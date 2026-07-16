//
//  QuickClockIntents.swift
//  WorkingHour
//
//  Created by Assistant on 2026/07/16.
//

import AppIntents
import Foundation

// Parameterless clock in/out intents for interactive widgets and Siri.
// Conforming to LiveActivityIntent runs them in the app's process, so the
// full ClockService side effects (Live Activity, geofencing upkeep) apply
// even when triggered from a widget button without opening the app.

struct QuickClockInIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "TimeClock.Work.ClockIn"
    static var description = IntentDescription("TimeClock.Work.StartSession")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        log("QuickClockInIntent: Starting", prefix: "YUUKA")
        guard !ClockService.shared.hasActiveSession else {
            log("QuickClockInIntent: Session already active", prefix: "YUUKA")
            return .result(dialog: IntentDialog("Intent.ClockIn.AlreadyActive"))
        }
        await ClockService.shared.clockIn(source: .intent)?.value
        log("QuickClockInIntent: Completed", prefix: "YUUKA")
        return .result(dialog: IntentDialog("Intent.ClockIn.Success"))
    }
}

struct QuickClockOutIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "TimeClock.Work.ClockOut"
    static var description = IntentDescription("TimeClock.Work.ClockOutSession")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        log("QuickClockOutIntent: Starting", prefix: "YUUKA")
        guard ClockService.shared.hasActiveSession else {
            log("QuickClockOutIntent: No active session", prefix: "YUUKA")
            return .result(dialog: IntentDialog("Intent.ClockOut.NoSession"))
        }
        await ClockService.shared.clockOut(source: .intent, dismissActivityImmediately: false)?.value
        log("QuickClockOutIntent: Completed", prefix: "YUUKA")
        return .result(dialog: IntentDialog("Intent.ClockOut.Success"))
    }
}
