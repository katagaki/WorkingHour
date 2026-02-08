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
        let modelContext = SharedModelContainer.shared.container.mainContext
        let descriptor = FetchDescriptor<ClockEntry>(
            predicate: #Predicate { $0.clockOutTime == nil }
        )
        if let entries = try? modelContext.fetch(descriptor),
           !entries.isEmpty {
            log("StartWorkSessionIntent: Active session already exists, skipping", prefix: "YUUKA")
            return .result()
        }

        log("StartWorkSessionIntent: Creating new clock entry", prefix: "YUUKA")
        let newEntry = ClockEntry(.now)
        modelContext.insert(newEntry)

        try? modelContext.save()
        modelContext.processPendingChanges()

        if let sessionData = newEntry.toWorkSessionData() {
            log("StartWorkSessionIntent: Starting live activity", prefix: "YUUKA")
            await LiveActivities.startActivity(with: sessionData)
        }

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
        let modelContext = SharedModelContainer.shared.container.mainContext
        let descriptor = FetchDescriptor<ClockEntry>(
            predicate: #Predicate { $0.clockOutTime == nil }
        )
        guard let entries = try? modelContext.fetch(descriptor),
              let entry = entries.first else {
            log("EndWorkSessionIntent: No active session found", prefix: "YUUKA")
            return .result()
        }

        log("EndWorkSessionIntent: Found active session", prefix: "YUUKA")

        if entry.isOnBreak,
           let breakStart = entry.breakTimes.last?.start,
           entry.breakTimes.last?.end == nil {
            log("EndWorkSessionIntent: Ending active break", prefix: "YUUKA")
            entry.breakTimes.removeLast()
            entry.breakTimes.append(Break(start: breakStart, end: .now))
            entry.isOnBreak = false
        }

        log("EndWorkSessionIntent: Setting clock out time", prefix: "YUUKA")
        entry.clockOutTime = .now

        try? modelContext.save()
        modelContext.processPendingChanges()

        if let sessionData = entry.toWorkSessionData() {
            log("EndWorkSessionIntent: Ending live activity", prefix: "YUUKA")
            await LiveActivities.endActivity(with: sessionData)
        }

        log("EndWorkSessionIntent: Completed", prefix: "YUUKA")
        return .result()
    }
}
