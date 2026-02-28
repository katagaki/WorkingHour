//
//  WorkingHourApp.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2024/10/09.
//

import Komponents
import SwiftData
import SwiftUI

@main
struct WorkingHourApp: App {

    @StateObject var navigator = Navigator<TabType, ViewPath>()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    let context = SharedModelContainer.shared.container.mainContext
                    DataManager.shared.modelContext = context
                    DataManager.shared.loadAll()
                    checkAndRestoreLiveActivity(context: context)
                    refreshClockInRemindersIfNeeded()
                    startGeofencingIfEnabled()
                }
        }
        .environmentObject(navigator)
        .modelContainer(SharedModelContainer.shared.container)
        .onChange(of: navigator.selectedTab) { _, _ in
            navigator.saveToDefaults()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                let context = SharedModelContainer.shared.container.mainContext
                checkAndRestoreLiveActivity(context: context)
            }
        }
    }

    private func checkAndRestoreLiveActivity(context: ModelContext) {
        // Fetch active entries (entries without clock out time)
        let descriptor = FetchDescriptor<ClockEntry>(
            predicate: #Predicate { $0.clockOutTime == nil },
            sortBy: [SortDescriptor(\.clockInTime, order: .reverse)]
        )

        if let activeEntry = try? context.fetch(descriptor).first,
           let sessionData = activeEntry.toWorkSessionData() {
            Task {
                await LiveActivities.ensureActivity(with: sessionData)
            }
        }
    }

    /// Re-schedules reminders if they are enabled and were last
    private func startGeofencingIfEnabled() {
        let settings = SettingsManager.shared
        guard settings.geofencingEnabled else { return }
        GeofencingManager.shared.startMonitoringWorkplaces()
    }

    /// Re-schedules clock-in reminders if they are enabled and were last
    /// scheduled more than 7 days ago (or have never been scheduled).
    private func refreshClockInRemindersIfNeeded() {
        let settings = SettingsManager.shared
        guard settings.clockInReminderEnabled || settings.clockOutReminderEnabled else { return }

        let needsRefresh: Bool
        if let lastScheduled = settings.notificationsLastScheduledDate {
            let daysSinceLastScheduled = Calendar.current.dateComponents(
                [.day], from: lastScheduled, to: Date()
            ).day ?? 0
            needsRefresh = daysSinceLastScheduled >= 7
        } else {
            // Never scheduled before
            needsRefresh = true
        }

        guard needsRefresh else { return }

        Task {
            if settings.clockInReminderEnabled {
                await NotificationManager.shared.scheduleClockInReminders(at: settings.clockInReminderTimeComponents)
            }
            if settings.clockOutReminderEnabled {
                await NotificationManager.shared.scheduleClockOutReminder(at: settings.clockOutReminderTimeComponents)
            }
            settings.notificationsLastScheduledDate = Date()
        }
    }
}
