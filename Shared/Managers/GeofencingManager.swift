//
//  GeofencingManager.swift
//  WorkingHour
//
//  Created by Assistant on 2026/02/20.
//

import ActivityKit
import CoreLocation
import Foundation
import SwiftData

// swiftlint:disable type_body_length file_length

/// Coordinates workplace geofencing for automatic clock in/out and breaks.
///
/// Region events from iOS are treated as *hints* rather than facts: every hint
/// is verified against a fresh location fix before acting. When the fix is
/// conclusive the action happens automatically; when it is inconclusive (weak
/// GPS, boundary jitter) the user is asked to confirm via an actionable
/// notification instead of the event being silently dropped.
///
/// While a session is active, significant-change location monitoring keeps the
/// Live Activity from going stale and self-heals missed region events.
@MainActor
@Observable
final class GeofencingManager: NSObject {

    static let shared = GeofencingManager()

    private let locationManager = CLLocationManager()

    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isMonitoring: Bool = false

    // MARK: Hint verification

    enum HintDirection {
        case entry
        case exit
    }

    private enum Verdict {
        case inside
        case outside
        case uncertain
    }

    /// The region hint currently awaiting verification by a fresh fix.
    private var pendingHint: (direction: HintDirection, date: Date)?
    private var verificationTimeout: Task<Void, Never>?
    /// How long to wait for a usable fix before falling back to asking the user.
    private let verificationTimeoutInterval: TimeInterval = 20

    // MARK: Flap suppression

    /// The last automatic action taken, used to suppress rapid flip-flopping
    /// at the fence boundary.
    private var lastAutoAction: (direction: HintDirection, date: Date)?
    /// Minimum time before an automatic action in the opposite direction.
    private let actionCooldown: TimeInterval = 150

    // MARK: Session location upkeep

    /// Whether significant-change monitoring is running for an active session.
    private var isTrackingSession = false
    private var lastActivityRefresh: Date = .distantPast
    /// Minimum time between Live Activity refreshes from location updates.
    private let activityRefreshInterval: TimeInterval = 5 * 60
    /// Whether a short burst of standard location updates is running.
    private var isPulsing = false
    private var pulseTimeout: Task<Void, Never>?

    /// Whether the current session is known to be at a workplace. Only then
    /// may upkeep fixes clock the user out — a session started manually away
    /// from any workplace (e.g. working from home) must never be ended by a
    /// location update. Persisted so background relaunches keep the state.
    private var sessionConfirmedAtWorkplace: Bool {
        get { SettingsManager.shared.sessionConfirmedAtWorkplace }
        set { SettingsManager.shared.sessionConfirmedAtWorkplace = newValue }
    }
    /// Whether the current break started because the user left the workplace.
    /// Manually started breaks must never be ended by a location event.
    /// Persisted so background relaunches keep the state.
    private var isOnAwayBreak: Bool {
        get { SettingsManager.shared.isOnAwayBreak }
        set { SettingsManager.shared.isOnAwayBreak = newValue }
    }

    private var modelContext: ModelContext {
        SharedModelContainer.shared.container.mainContext
    }

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = locationManager.authorizationStatus
    }

    /// Called as early as possible on every launch — including background
    /// launches caused by a region crossing or a significant location change —
    /// so the delegate is armed before CoreLocation delivers the event.
    func bootstrap() {
        authorizationStatus = locationManager.authorizationStatus
        startMonitoringWorkplaces()
        syncSessionUpkeep()
    }

    // MARK: - Authorization

    func requestAlwaysAuthorization() {
        let status = locationManager.authorizationStatus
        if status == .notDetermined || status == .authorizedWhenInUse {
            locationManager.requestAlwaysAuthorization()
        }
    }

    var hasAlwaysAuthorization: Bool {
        locationManager.authorizationStatus == .authorizedAlways
    }

    var hasAnyAuthorization: Bool {
        let status = locationManager.authorizationStatus
        return status == .authorizedAlways || status == .authorizedWhenInUse
    }

    // MARK: - Geofence Monitoring

    func startMonitoringWorkplaces() {
        guard SettingsManager.shared.geofencingEnabled else {
            stopMonitoringAllRegions()
            return
        }

        guard hasAlwaysAuthorization else {
            log("GeofencingManager: Missing Always authorization", prefix: "MIKA")
            return
        }

        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            log("GeofencingManager: Geofencing not available on this device", prefix: "MIKA")
            return
        }

        let workplaces = enabledWorkplaces()

        // Re-register only what changed; tearing everything down on every
        // launch makes CoreLocation re-deliver boundary events unnecessarily.
        let wantedIds = Set(workplaces.map(\.id))
        for region in locationManager.monitoredRegions where !wantedIds.contains(region.identifier) {
            locationManager.stopMonitoring(for: region)
        }

        for workplace in workplaces {
            let region = CLCircularRegion(
                center: CLLocationCoordinate2D(
                    latitude: workplace.latitude,
                    longitude: workplace.longitude
                ),
                radius: max(
                    Workplace.minimumReliableRadius,
                    min(workplace.radius, locationManager.maximumRegionMonitoringDistance)
                ),
                identifier: workplace.id
            )
            region.notifyOnEntry = true
            region.notifyOnExit = true

            if let monitored = locationManager.monitoredRegions.first(where: { $0.identifier == workplace.id }) {
                if let monitored = monitored as? CLCircularRegion,
                   monitored.center.latitude == region.center.latitude,
                   monitored.center.longitude == region.center.longitude,
                   monitored.radius == region.radius {
                    continue // Unchanged, keep the existing registration.
                }
                locationManager.stopMonitoring(for: monitored)
            }
            locationManager.startMonitoring(for: region)
            log("GeofencingManager: Monitoring \(workplace.name) (r=\(workplace.radius)m)", prefix: "MIKA")
        }

        isMonitoring = !workplaces.isEmpty
        log("GeofencingManager: Monitoring \(workplaces.count) workplace(s)", prefix: "MIKA")
    }

    func stopMonitoringAllRegions() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        isMonitoring = false
        log("GeofencingManager: Stopped monitoring all regions", prefix: "MIKA")
    }

    // MARK: - Hint Handling

    /// Handles a raw region-crossing hint from CoreLocation by verifying it
    /// against a fresh location fix before acting on it.
    private func handleHint(_ direction: HintDirection) {
        guard SettingsManager.shared.geofencingEnabled else { return }

        guard hintIsActionable(direction) else {
            log("GeofencingManager: \(direction) hint has no applicable action, ignoring", prefix: "MIKA")
            return
        }

        // Suppress flip-flopping at the fence boundary: an opposite hint right
        // after an automatic action is almost always jitter.
        if let lastAutoAction,
           lastAutoAction.direction != direction,
           Date.now.timeIntervalSince(lastAutoAction.date) < actionCooldown {
            log("GeofencingManager: \(direction) hint within cooldown of last auto action, ignoring", prefix: "MIKA")
            return
        }

        if let pendingHint, pendingHint.direction == direction {
            return // Already verifying this hint.
        }

        log("GeofencingManager: Verifying \(direction) hint with a fresh fix", prefix: "MIKA")
        pendingHint = (direction, .now)
        startVerificationTimeout()
        // While a pulse is streaming updates the next fix resolves the hint;
        // requestLocation must not run concurrently with standard updates.
        if !isPulsing {
            locationManager.requestLocation()
        }
    }

    /// Whether a hint in this direction could lead to any action, so we do not
    /// spin up GPS for hints that would be no-ops.
    private func hintIsActionable(_ direction: HintDirection) -> Bool {
        let settings = SettingsManager.shared
        let entry = ClockService.shared.activeEntry()

        switch direction {
        case .entry:
            if let entry {
                // Only breaks that started by leaving the workplace may be
                // ended by returning; manually started breaks are off-limits.
                return entry.isOnBreak && isOnAwayBreak
            }
            return settings.autoClockInEnabled
        case .exit:
            guard let entry else { return false }
            if isWithinBreakWindow(.now), !entry.isOnBreak {
                return true // Leaving during a break window starts a break.
            }
            return settings.autoClockOutEnabled
        }
    }

    private func startVerificationTimeout() {
        verificationTimeout?.cancel()
        verificationTimeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(self?.verificationTimeoutInterval ?? 20))
            guard !Task.isCancelled else { return }
            guard let self, let hint = self.pendingHint else { return }
            self.pendingHint = nil
            log("GeofencingManager: No usable fix in time, asking the user to confirm", prefix: "MIKA")
            self.requestUserConfirmation(for: hint.direction, hintDate: hint.date)
        }
    }

    private func resolveHint(with location: CLLocation) {
        guard let hint = pendingHint else { return }
        pendingHint = nil
        verificationTimeout?.cancel()
        verificationTimeout = nil

        let verdict = classify(location)
        log(
            "GeofencingManager: \(hint.direction) hint verified as \(verdict) "
            + "(accuracy=\(Int(location.horizontalAccuracy))m)",
            prefix: "MIKA"
        )

        if verdict == .inside, ClockService.shared.hasActiveSession {
            sessionConfirmedAtWorkplace = true
        }

        switch (hint.direction, verdict) {
        case (.entry, .inside):
            performEntryActions(at: hint.date)
        case (.exit, .outside):
            performExitActions(at: hint.date)
        case (.entry, .uncertain), (.exit, .uncertain):
            requestUserConfirmation(for: hint.direction, hintDate: hint.date)
        case (.entry, .outside), (.exit, .inside):
            log("GeofencingManager: Fix contradicts \(hint.direction) hint, rejecting", prefix: "MIKA")
        }
    }

    private func failPendingHint() {
        guard let hint = pendingHint else { return }
        pendingHint = nil
        verificationTimeout?.cancel()
        verificationTimeout = nil
        log("GeofencingManager: Could not get a fix, asking the user to confirm", prefix: "MIKA")
        requestUserConfirmation(for: hint.direction, hintDate: hint.date)
    }

    // MARK: - Fix Classification

    /// Classifies a fix against all enabled workplaces with accuracy-based
    /// hysteresis: `.inside` if confidently within any fence, `.outside` only
    /// if confidently outside every fence, `.uncertain` otherwise.
    private func classify(_ location: CLLocation) -> Verdict {
        let workplaces = enabledWorkplaces()
        guard !workplaces.isEmpty else { return .uncertain }

        let accuracy = location.horizontalAccuracy
        guard accuracy >= 0, accuracy <= 250 else {
            return .uncertain // Fix too coarse to trust either way.
        }
        let slack = max(accuracy, 30)

        var uncertain = false
        for workplace in workplaces {
            let center = CLLocation(latitude: workplace.latitude, longitude: workplace.longitude)
            let distance = location.distance(from: center)
            if distance + slack <= workplace.radius + 40 {
                return .inside
            }
            if distance - slack >= workplace.radius + 40 {
                continue // Confidently outside this fence.
            }
            uncertain = true
        }
        return uncertain ? .uncertain : .outside
    }

    private func enabledWorkplaces() -> [Workplace] {
        let descriptor = FetchDescriptor<Workplace>(
            predicate: #Predicate { $0.isEnabled }
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            log("GeofencingManager: Error fetching workplaces: \(error)", prefix: "MIKA")
            return []
        }
    }

    // MARK: - Automatic Actions

    private func performEntryActions(at date: Date) {
        let settings = SettingsManager.shared

        if let entry = ClockService.shared.activeEntry() {
            // Ending an in-progress break takes priority and happens
            // regardless of the auto clock-in setting — but only for breaks
            // that started by leaving the workplace. A manually started break
            // must never be ended by a location event.
            if entry.isOnBreak, isOnAwayBreak {
                lastAutoAction = (.entry, .now)
                ClockService.shared.endBreak(at: date, source: .geofence, notify: true)
            }
            return
        }

        guard settings.autoClockInEnabled else { return }
        lastAutoAction = (.entry, .now)
        ClockService.shared.clockIn(at: date, source: .geofence)
    }

    private func performExitActions(at date: Date) {
        let settings = SettingsManager.shared
        guard let entry = ClockService.shared.activeEntry() else { return }

        // During a configured break window, leaving starts a break instead of
        // clocking out — regardless of the auto clock-out setting.
        if isWithinBreakWindow(date) {
            if !entry.isOnBreak {
                lastAutoAction = (.exit, .now)
                ClockService.shared.startBreak(at: date, source: .geofence, notify: true)
            }
            return
        }

        guard settings.autoClockOutEnabled else { return }
        lastAutoAction = (.exit, .now)
        ClockService.shared.clockOut(at: date, source: .geofence)
    }

    /// Asks the user to confirm an action we could not verify automatically.
    private func requestUserConfirmation(for direction: HintDirection, hintDate: Date) {
        let entry = ClockService.shared.activeEntry()

        let kind: NotificationManager.ConfirmationRequest
        switch direction {
        case .entry:
            if let entry, entry.isOnBreak {
                // Don't even ask about ending a manually started break.
                guard isOnAwayBreak else { return }
                kind = .breakEnd
            } else if entry == nil {
                kind = .clockIn
            } else {
                return
            }
        case .exit:
            guard let entry else { return }
            if isWithinBreakWindow(hintDate), !entry.isOnBreak {
                kind = .breakStart
            } else {
                kind = .clockOut
            }
        }

        Task {
            await NotificationManager.shared.sendConfirmationRequest(kind, hintDate: hintDate)
        }
    }

    // MARK: - Break Windows

    /// Whether `date` falls within any enabled break window.
    private func isWithinBreakWindow(_ date: Date) -> Bool {
        let descriptor = FetchDescriptor<BreakWindow>(
            predicate: #Predicate { $0.isEnabled }
        )
        do {
            let windows = try modelContext.fetch(descriptor)
            return windows.contains { $0.contains(date) }
        } catch {
            log("GeofencingManager: Error fetching break windows: \(error)", prefix: "MIKA")
            return false
        }
    }

    // MARK: - Session Location Upkeep

    /// Starts or stops significant-change monitoring to match whether a
    /// session is currently active.
    func syncSessionUpkeep() {
        if ClockService.shared.hasActiveSession {
            sessionDidStart()
        } else {
            sessionDidEnd()
        }
    }

    /// Begins location upkeep for an active session: significant-change
    /// monitoring wakes the app periodically to refresh the Live Activity's
    /// stale date and to self-heal missed region events.
    ///
    /// Pass `confirmedAtWorkplace` when a session starts to record whether it
    /// began at a workplace; omit it when merely resuming upkeep for a
    /// session that is already running.
    func sessionDidStart(confirmedAtWorkplace: Bool? = nil) {
        if let confirmedAtWorkplace {
            sessionConfirmedAtWorkplace = confirmedAtWorkplace
            isOnAwayBreak = false
        }
        guard hasAnyAuthorization,
              CLLocationManager.significantLocationChangeMonitoringAvailable() else {
            return
        }
        updateBackgroundLocationCapability()
        guard !isTrackingSession else { return }
        isTrackingSession = true
        locationManager.startMonitoringSignificantLocationChanges()
        log("GeofencingManager: Started session location upkeep", prefix: "MIKA")
    }

    /// Stops location upkeep when no session is active.
    func sessionDidEnd() {
        sessionConfirmedAtWorkplace = false
        isOnAwayBreak = false
        guard isTrackingSession else { return }
        isTrackingSession = false
        locationManager.stopMonitoringSignificantLocationChanges()
        endLocationPulse()
        log("GeofencingManager: Stopped session location upkeep", prefix: "MIKA")
    }

    /// Records how the current break started. Only breaks that began because
    /// the user left the workplace may be ended by a location event.
    func noteBreakStarted(awayFromWorkplace: Bool) {
        isOnAwayBreak = awayFromWorkplace
    }

    /// Records that the current break has ended.
    func noteBreakEnded() {
        isOnAwayBreak = false
    }

    /// Briefly streams location updates. While updates are flowing the app is
    /// allowed to start Live Activities from the background, and the extra
    /// runtime lets in-flight work (saves, notifications) finish.
    func beginLocationPulse(for duration: TimeInterval = 15) {
        guard hasAnyAuthorization else { return }
        updateBackgroundLocationCapability()
        isPulsing = true
        locationManager.startUpdatingLocation()
        pulseTimeout?.cancel()
        pulseTimeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            self?.endLocationPulse()
        }
    }

    private func endLocationPulse() {
        pulseTimeout?.cancel()
        pulseTimeout = nil
        guard isPulsing else { return }
        isPulsing = false
        locationManager.stopUpdatingLocation()
    }

    private func updateBackgroundLocationCapability() {
        let allowed = hasAlwaysAuthorization
        if locationManager.allowsBackgroundLocationUpdates != allowed {
            locationManager.allowsBackgroundLocationUpdates = allowed
        }
    }

    /// Handles a fix that arrived outside hint verification (significant
    /// location change or a pulse): refreshes the Live Activity and reconciles
    /// the session against the fences to catch missed region events.
    private func handleUpkeepFix(_ location: CLLocation) {
        guard let entry = ClockService.shared.activeEntry() else {
            sessionDidEnd()
            return
        }

        // Refresh the Live Activity so it never reaches its 8-hour stale date
        // mid-shift, starting it if it is missing (possible here because the
        // app is actively receiving location updates).
        if Date.now.timeIntervalSince(lastActivityRefresh) >= activityRefreshInterval {
            lastActivityRefresh = .now
            if let sessionData = entry.toWorkSessionData() {
                Task {
                    await LiveActivities.startOrUpdateActivity(with: sessionData)
                }
            }
        }

        // Reconcile against the fences, but only on confident verdicts —
        // upkeep fixes must never generate confirmation notifications.
        guard SettingsManager.shared.geofencingEnabled else { return }
        // Significant-change monitoring can deliver cached fixes; never
        // reconcile against a stale position.
        guard abs(location.timestamp.timeIntervalSinceNow) < 120 else { return }
        if let lastAutoAction, Date.now.timeIntervalSince(lastAutoAction.date) < actionCooldown {
            return
        }

        switch classify(location) {
        case .outside:
            // Only sessions known to be at a workplace may be ended here; a
            // session started manually elsewhere is none of our business.
            guard sessionConfirmedAtWorkplace else { return }
            log("GeofencingManager: Upkeep fix shows we left the workplace, reconciling", prefix: "MIKA")
            performExitActions(at: location.timestamp)
        case .inside:
            sessionConfirmedAtWorkplace = true
            if entry.isOnBreak, isOnAwayBreak {
                log("GeofencingManager: Upkeep fix shows we are back at the workplace, ending break", prefix: "MIKA")
                performEntryActions(at: location.timestamp)
            }
        case .uncertain:
            break
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension GeofencingManager: CLLocationManagerDelegate {

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            log("GeofencingManager: Authorization changed to \(status.rawValue)", prefix: "MIKA")

            if status == .authorizedAlways {
                if SettingsManager.shared.geofencingEnabled {
                    self.startMonitoringWorkplaces()
                }
                self.syncSessionUpkeep()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard region is CLCircularRegion else { return }
        Task { @MainActor in
            log("GeofencingManager: Entered region \(region.identifier)", prefix: "MIKA")
            self.handleHint(.entry)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard region is CLCircularRegion else { return }
        Task { @MainActor in
            log("GeofencingManager: Exited region \(region.identifier)", prefix: "MIKA")
            self.handleHint(.exit)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            if self.pendingHint != nil {
                self.resolveHint(with: location)
            } else {
                self.handleUpkeepFix(location)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            log("GeofencingManager: Location request failed: \(error)", prefix: "MIKA")
            // kCLErrorLocationUnknown is transient — CoreLocation keeps
            // trying, and the verification timeout covers the worst case.
            if let clError = error as? CLError, clError.code == .locationUnknown {
                return
            }
            self.failPendingHint()
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        monitoringDidFailFor region: CLRegion?,
        withError error: Error
    ) {
        Task { @MainActor in
            log(
                "GeofencingManager: Monitoring failed for region \(region?.identifier ?? "unknown"): \(error)",
                prefix: "MIKA"
            )
        }
    }
}
// swiftlint:enable type_body_length file_length
