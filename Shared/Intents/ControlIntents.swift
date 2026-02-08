//
//  ControlIntents.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2026/02/08.
//

import AppIntents
import SwiftData

struct StartWorkSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Clock In"
    static var description = IntentDescription("Start a new work session")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        let modelContext = SharedModelContainer.shared.container.mainContext

        // Check if there's already an active session
        let descriptor = FetchDescriptor<ClockEntry>(
            predicate: #Predicate { $0.clockOutTime == nil }
        )

        if let entries = try? modelContext.fetch(descriptor),
           !entries.isEmpty {
            // Already have an active session
            return .result()
        }

        // Create new entry
        let newEntry = ClockEntry(.now)
        modelContext.insert(newEntry)

        try? modelContext.save()

        // Start Live Activity
        if let sessionData = newEntry.toWorkSessionData() {
            await LiveActivities.startActivity(with: sessionData)
        }

        return .result()
    }
}

struct EndWorkSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Clock Out"
    static var description = IntentDescription("End the current work session")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        let modelContext = SharedModelContainer.shared.container.mainContext

        // Find active session
        let descriptor = FetchDescriptor<ClockEntry>(
            predicate: #Predicate { $0.clockOutTime == nil }
        )

        guard let entries = try? modelContext.fetch(descriptor),
              let entry = entries.first else {
            return .result()
        }

        // End any active break first
        if entry.isOnBreak,
           let breakStart = entry.breakTimes.last?.start,
           entry.breakTimes.last?.end == nil {
            entry.breakTimes.removeLast()
            entry.breakTimes.append(Break(start: breakStart, end: .now))
            entry.isOnBreak = false
        }

        entry.clockOutTime = .now

        try? modelContext.save()

        // End Live Activity
        if let sessionData = entry.toWorkSessionData() {
            await LiveActivities.endActivity(with: sessionData)
        }

        return .result()
    }
}
