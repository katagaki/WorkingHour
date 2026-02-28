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
        guard settings.geofencingEnabled, settings.autoClockInEnabled else { return }

        guard let modelContext = DataManager.shared.modelContext else {
            log("GeofencingManager: No model context for clock-in", prefix: "MIKA")
            return
        }

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

            if settings.autoAddBreakTime && settings.defaultBreakDuration > 0 {
                let breakStart = Date.now
                let breakEnd = breakStart.addingTimeInterval(settings.defaultBreakDuration)
                let newBreak = Break(start: breakStart, end: breakEnd)
                newBreak.clockEntry = newEntry
                modelContext.insert(newBreak)
            }

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
        guard settings.geofencingEnabled, settings.autoClockOutEnabled else { return }

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
                log("GeofencingManager: No active entry to clock out", prefix: "MIKA")
                return
            }

            // End any active break first
            if activeEntry.isOnBreak,
               let lastBreak = (activeEntry.breakTimes ?? []).last,
               lastBreak.end == nil {
                lastBreak.end = .now
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
}

// MARK: - CLLocationManagerDelegate

extension GeofencingManager: @preconcurrency CLLocationManagerDelegate {

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
            log("GeofencingManager: Entered region \(region.identifier)", prefix: "MIKA")
            self.handleRegionEntry()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard region is CLCircularRegion else { return }
        Task { @MainActor in
            log("GeofencingManager: Exited region \(region.identifier)", prefix: "MIKA")
            self.handleRegionExit()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        Task { @MainActor in
            log("GeofencingManager: Monitoring failed for region \(region?.identifier ?? "unknown"): \(error)", prefix: "MIKA")
        }
    }
}
