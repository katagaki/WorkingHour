//
//  ControlIntents.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2026/02/08.
//

import AppIntents
import SwiftData

struct StartWorkSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "TimeClock.Work.ClockIn"
    static var description = IntentDescription("TimeClock.Work.StartSession")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        log("StartWorkSessionIntent: Starting", prefix: "YUUKA")
        await ClockService.shared.clockIn(source: .intent)?.value
        log("StartWorkSessionIntent: Completed", prefix: "YUUKA")
        return .result()
    }
}

struct EndWorkSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "TimeClock.Work.ClockOut"
    static var description = IntentDescription("TimeClock.Work.ClockOutSession")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        log("EndWorkSessionIntent: Starting", prefix: "YUUKA")
        await ClockService.shared.clockOut(source: .intent, dismissActivityImmediately: false)?.value
        log("EndWorkSessionIntent: Completed", prefix: "YUUKA")
        return .result()
    }
}
