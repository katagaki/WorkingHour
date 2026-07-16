//
//  AppShortcuts.swift
//  WorkingHour
//
//  Created by Assistant on 2026/07/16.
//

import AppIntents

/// Exposes clock in/out to Siri and Spotlight ("Clock in with Working Hour").
struct WorkingHourAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickClockInIntent(),
            phrases: [
                "Clock in with \(.applicationName)",
                "Start work in \(.applicationName)",
                "\(.applicationName)で出勤"
            ],
            shortTitle: "TimeClock.Work.ClockIn",
            systemImageName: "figure.walk.arrival"
        )
        AppShortcut(
            intent: QuickClockOutIntent(),
            phrases: [
                "Clock out with \(.applicationName)",
                "End work in \(.applicationName)",
                "\(.applicationName)で退勤"
            ],
            shortTitle: "TimeClock.Work.ClockOut",
            systemImageName: "figure.walk.departure"
        )
    }
}
