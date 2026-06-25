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

@MainActor
@Observable
final class GeofencingManager: NSObject {

    static let shared = GeofencingManager()

    private let locationManager = CLLocationManager()

    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isMonitoring: Bool = false

    /// A confirmed boundary crossing, used to debounce flapping at the edge.
    private enum RegionTransition { case entered, exited }

    /// Region boundary crossings awaiting confirmation via `requestState`,
    /// keyed by region identifier with the direction that triggered them.
    private var pendingConfirmations: [String: RegionTransition] = [:]

    /// Entry/exit events received before this date are ignored, to let regions
    /// settle after (re-)registration.
    private var ignoreEventsUntil: Date = .distantPast

    /// The last transition we acted on, and when — used to drop duplicate or
    /// rapidly-flapping events while lingering at the boundary.
    private var lastActedTransition: RegionTransition?
    private var lastActedTransitionAt: Date = .distantPast

    /// Minimum spacing between two *same-direction* transitions. Opposite
    /// directions (a genuine state change) are always allowed through.
    private let transitionCooldown: TimeInterval = 60

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Authorization

    func requestAlwaysAuthorization() {
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else if status == .authorizedWhenInUse {
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
            log("GeofencingManager: Geofencing is disabled in settings", prefix: "MIKA")
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

        guard let modelContext = DataManager.shared.modelContext else {
            log("GeofencingManager: No model context available", prefix: "MIKA")
            return
        }

        // Stop all existing monitoring first
        stopMonitoringAllRegions()

        // Ignore entries and exits briefly while regions settle after
        // re-registration, which otherwise re-deliver spurious crossings.
        ignoreEventsUntil = Date().addingTimeInterval(15)

        do {
            let descriptor = FetchDescriptor<Workplace>(
                predicate: #Predicate { $0.isEnabled }
            )
            let workplaces = try modelContext.fetch(descriptor)

            for workplace in workplaces {
                let region = CLCircularRegion(
                    center: CLLocationCoordinate2D(
                        latitude: workplace.latitude,
                        longitude: workplace.longitude
                    ),
                    radius: min(workplace.radius, locationManager.maximumRegionMonitoringDistance),
                    identifier: workplace.id
                )
                region.notifyOnEntry = true
                region.notifyOnExit = true
                locationManager.startMonitoring(for: region)
                log("GeofencingManager: Started monitoring \(workplace.name) (r=\(workplace.radius)m)", prefix: "MIKA")
            }

            isMonitoring = !workplaces.isEmpty
            log("GeofencingManager: Monitoring \(workplaces.count) workplace(s)", prefix: "MIKA")
        } catch {
            log("GeofencingManager: Error fetching workplaces: \(error)", prefix: "MIKA")
        }
    }

    func stopMonitoringAllRegions() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        isMonitoring = false
        log("GeofencingManager: Stopped monitoring all regions", prefix: "MIKA")
    }

    // MARK: - Clock In/Out Actions

    private func handleRegionEntry() {
        let settings = SettingsManager.shared
        guard settings.geofencingEnabled else { return }

        guard let modelContext = DataManager.shared.modelContext else {
            log("GeofencingManager: No model context for clock-in", prefix: "MIKA")
            return
        }

        // Ending an in-progress break takes priority and happens regardless of
        // the auto clock-in setting or the current time.
        if endActiveBreak(in: modelContext) { return }

        guard settings.autoClockInEnabled else { return }

        // Check if there's already an active entry
        let descriptor = FetchDescriptor<ClockEntry>(
            predicate: #Predicate { $0.clockOutTime == nil }
        )

        do {
            let activeEntries = try modelContext.fetch(descriptor)
            guard activeEntries.isEmpty else {
                log("GeofencingManager: Already clocked in, skipping auto clock-in", prefix: "MIKA")
                return
            }

            let newEntry = ClockEntry(.now)

            modelContext.insert(newEntry)
            try modelContext.save()
            DataManager.shared.loadAll()

            log("GeofencingManager: Auto clocked in", prefix: "MIKA")

            // Send clock-in notification
            Task {
                await NotificationManager.shared.sendClockInConfirmation(at: .now)
            }

            // Start live activity
            if let sessionData = newEntry.toWorkSessionData() {
                Task {
                    await LiveActivities.startActivity(with: sessionData)
                }
            }
        } catch {
            log("GeofencingManager: Error during auto clock-in: \(error)", prefix: "MIKA")
        }
    }

    private func handleRegionExit() {
        let settings = SettingsManager.shared
        guard settings.geofencingEnabled else { return }

        guard let modelContext = DataManager.shared.modelContext else {
            log("GeofencingManager: No model context for clock-out", prefix: "MIKA")
            return
        }

        let descriptor = FetchDescriptor<ClockEntry>(
            predicate: #Predicate { $0.clockOutTime == nil },
            sortBy: [SortDescriptor(\.clockInTime, order: .reverse)]
        )

        do {
            guard let activeEntry = try modelContext.fetch(descriptor).first else {
                log("GeofencingManager: No active entry on exit", prefix: "MIKA")
                return
            }

            // During a configured break window, leaving starts a break instead
            // of clocking out — regardless of the auto clock-out setting.
            if isWithinBreakWindow(.now, in: modelContext) {
                startAutoBreak(for: activeEntry, in: modelContext)
                return
            }

            guard settings.autoClockOutEnabled else { return }

            // End any active break first. Find the open break explicitly —
            // `breakTimes` is an unordered SwiftData relationship, so `.last`
            // is not reliably the ongoing one.
            if activeEntry.isOnBreak,
               let openBreak = (activeEntry.breakTimes ?? []).first(where: { $0.end == nil }) {
                openBreak.end = .now
                activeEntry.isOnBreak = false
            }

            let sessionData = activeEntry.toWorkSessionData()

            activeEntry.clockOutTime = .now
            try modelContext.save()
            DataManager.shared.loadAll()

            log("GeofencingManager: Auto clocked out", prefix: "MIKA")

            // End live activity
            if let sessionData {
                Task {
                    await LiveActivities.endActivity(with: sessionData, immediately: true)
                }
            }
        } catch {
            log("GeofencingManager: Error during auto clock-out: \(error)", prefix: "MIKA")
        }
    }

    // MARK: - Automatic Breaks

    /// Whether `date` falls within any enabled break window.
    private func isWithinBreakWindow(_ date: Date, in modelContext: ModelContext) -> Bool {
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

    /// Starts a break for the active entry (unless one is already in progress)
    /// and notifies the user.
    private func startAutoBreak(for activeEntry: ClockEntry, in modelContext: ModelContext) {
        guard !activeEntry.isOnBreak else {
            log("GeofencingManager: Already on break, skipping auto break", prefix: "MIKA")
            return
        }

        do {
            let newBreak = Break(start: .now)
            newBreak.clockEntry = activeEntry
            modelContext.insert(newBreak)
            activeEntry.isOnBreak = true
            try modelContext.save()
            DataManager.shared.loadAll()

            log("GeofencingManager: Auto started break", prefix: "MIKA")

            if let sessionData = activeEntry.toWorkSessionData() {
                Task {
                    await LiveActivities.updateActivity(with: sessionData)
                }
            }
            Task {
                await NotificationManager.shared.sendBreakStartedConfirmation(at: .now)
            }
        } catch {
            log("GeofencingManager: Error starting auto break: \(error)", prefix: "MIKA")
        }
    }

    /// Ends the active break, if any. Returns `true` when a break was ended.
    private func endActiveBreak(in modelContext: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<ClockEntry>(
            predicate: #Predicate { $0.clockOutTime == nil },
            sortBy: [SortDescriptor(\.clockInTime, order: .reverse)]
        )

        do {
            // `breakTimes` is unordered, so locate the open break explicitly
            // rather than relying on `.last`.
            guard let activeEntry = try modelContext.fetch(descriptor).first,
                  activeEntry.isOnBreak,
                  let openBreak = (activeEntry.breakTimes ?? []).first(where: { $0.end == nil }) else {
                return false
            }

            openBreak.end = .now
            activeEntry.isOnBreak = false
            try modelContext.save()
            DataManager.shared.loadAll()

            log("GeofencingManager: Auto ended break", prefix: "MIKA")

            if let sessionData = activeEntry.toWorkSessionData() {
                Task {
                    await LiveActivities.updateActivity(with: sessionData)
                }
            }
            Task {
                await NotificationManager.shared.sendBreakEndedConfirmation(at: .now)
            }
            return true
        } catch {
            log("GeofencingManager: Error ending break: \(error)", prefix: "MIKA")
            return false
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

            if status == .authorizedAlways && SettingsManager.shared.geofencingEnabled {
                self.startMonitoringWorkplaces()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard region is CLCircularRegion else { return }
        Task { @MainActor in
            self.queueConfirmation(.entered, for: region, with: manager)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard region is CLCircularRegion else { return }
        Task { @MainActor in
            self.queueConfirmation(.exited, for: region, with: manager)
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didDetermineState state: CLRegionState,
        for region: CLRegion
    ) {
        guard region is CLCircularRegion else { return }
        Task { @MainActor in
            // Only act on states we explicitly requested to confirm a crossing.
            guard let transition = self.pendingConfirmations.removeValue(forKey: region.identifier) else { return }

            // Use the confirmed state to veto obvious GPS jitter, but trust the
            // original event (including `.unknown`, which is common in the
            // background) so genuine crossings are never silently dropped.
            switch transition {
            case .entered:
                guard state != .outside else {
                    log("GeofencingManager: Ignoring entry for \(region.identifier); device is outside", prefix: "MIKA")
                    return
                }
                self.act(on: .entered, region: region.identifier, state: state) { self.handleRegionEntry() }
            case .exited:
                guard state != .inside else {
                    log("GeofencingManager: Ignoring exit for \(region.identifier); device is still inside", prefix: "MIKA")
                    return
                }
                self.act(on: .exited, region: region.identifier, state: state) { self.handleRegionExit() }
            }
        }
    }

    /// Records a boundary crossing and asks Core Location to confirm the
    /// device's current state before acting, unless we're still settling.
    private func queueConfirmation(
        _ transition: RegionTransition,
        for region: CLRegion,
        with manager: CLLocationManager
    ) {
        let verb = transition == .entered ? "entry" : "exit"
        log("GeofencingManager: \(verb.capitalized) for region \(region.identifier)", prefix: "MIKA")

        guard Date() >= ignoreEventsUntil else {
            log("GeofencingManager: Ignoring \(verb) for \(region.identifier) during settling window", prefix: "MIKA")
            return
        }

        pendingConfirmations[region.identifier] = transition
        manager.requestState(for: region)
    }

    /// Runs `action` for a confirmed crossing, dropping a same-direction repeat
    /// that lands within the cooldown (boundary flapping / duplicate events).
    private func act(
        on transition: RegionTransition,
        region: String,
        state: CLRegionState,
        action: () -> Void
    ) {
        if transition == lastActedTransition,
           Date().timeIntervalSince(lastActedTransitionAt) < transitionCooldown {
            log("GeofencingManager: Debouncing repeat \(region) crossing within cooldown", prefix: "MIKA")
            return
        }

        log("GeofencingManager: Confirmed crossing for \(region) (state=\(state.rawValue))", prefix: "MIKA")
        lastActedTransition = transition
        lastActedTransitionAt = Date()
        action()
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
