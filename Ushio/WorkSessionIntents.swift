//
//  WorkSessionIntents.swift
//  Ushio
//
//  Created by Assistant on 2026/02/07.
//

import AppIntents
import SwiftData
import Foundation

// Shared model container
@MainActor
class SharedModelContainer {
    static let shared = SharedModelContainer()

    let container: ModelContainer

    private init() {
        container = SharedModelConfiguration.createModelContainer()
    }
}

// MARK: - Break data structure for cross-target use
public struct BreakData: Codable, Hashable {
    let start: Date
    let end: Date?
}

// MARK: - Start Break Intent

struct StartBreakIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Break"
    static var description = IntentDescription("Start a break during the work session")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Entry ID")
    var entryId: String

    init() {
        self.entryId = ""
    }

    init(entryId: String) {
        self.entryId = entryId
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let modelContext = SharedModelContainer.shared.container.mainContext

        let descriptor = FetchDescriptor<ClockEntry>(
            predicate: #Predicate { $0.id == entryId && $0.clockOutTime == nil }
        )

        guard let entries = try? modelContext.fetch(descriptor),
              let entry = entries.first else {
            return .result()
        }

        entry.breakTimes.append(Break(start: .now))
        entry.isOnBreak = true

        try? modelContext.save()

        // Update Live Activity
        if let sessionData = entry.toWorkSessionData() {
            LiveActivityManager.shared.updateActivity(with: sessionData)
        }

        return .result()
    }
}

// MARK: - End Break Intent

struct EndBreakIntent: AppIntent {
    static var title: LocalizedStringResource = "End Break"
    static var description = IntentDescription("End the current break")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Entry ID")
    var entryId: String

    init() {
        self.entryId = ""
    }

    init(entryId: String) {
        self.entryId = entryId
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let modelContext = SharedModelContainer.shared.container.mainContext

        let descriptor = FetchDescriptor<ClockEntry>(
            predicate: #Predicate { $0.id == entryId && $0.clockOutTime == nil }
        )

        guard let entries = try? modelContext.fetch(descriptor),
              let entry = entries.first,
              let startTime = entry.breakTimes.last?.start,
              entry.breakTimes.last?.end == nil else {
            return .result()
        }

        entry.breakTimes.removeLast()
        entry.breakTimes.append(Break(start: startTime, end: .now))
        entry.isOnBreak = false

        try? modelContext.save()

        // Update Live Activity
        if let sessionData = entry.toWorkSessionData() {
            LiveActivityManager.shared.updateActivity(with: sessionData)
        }

        return .result()
    }
}

// MARK: - Clock Out Intent

struct ClockOutIntent: AppIntent {
    static var title: LocalizedStringResource = "Clock Out"
    static var description = IntentDescription("End the work session")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Entry ID")
    var entryId: String

    init() {
        self.entryId = ""
    }

    init(entryId: String) {
        self.entryId = entryId
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let modelContext = SharedModelContainer.shared.container.mainContext

        let descriptor = FetchDescriptor<ClockEntry>(
            predicate: #Predicate { $0.id == entryId && $0.clockOutTime == nil }
        )

        guard let entries = try? modelContext.fetch(descriptor),
              let entry = entries.first else {
            return .result()
        }

        entry.clockOutTime = .now
        entry.isOnBreak = false

        try? modelContext.save()

        // End Live Activity
        if let sessionData = entry.toWorkSessionData() {
            LiveActivityManager.shared.endActivity(with: sessionData)
        }

        return .result()
    }
}
// Extension to convert ClockEntry to WorkSessionData in the Ushio target
extension ClockEntry {
    func toWorkSessionData() -> WorkSessionData? {
        guard let clockInTime = self.clockInTime else {
            return nil
        }

        // Calculate total break time
        let totalBreakTime = self.breakTimes.reduce(into: 0.0) { partialResult, breakTime in
            if let end = breakTime.end {
                partialResult += end.timeIntervalSince(breakTime.start)
            }
        }

        // Default to 8 hours (28800 seconds) as standard working hours
        let standardWorkingHours: TimeInterval = 28800

        return WorkSessionData(
            entryId: self.id,
            clockInTime: clockInTime,
            isOnBreak: self.isOnBreak,
            breakStartTime: self.isOnBreak ? self.breakTimes.last?.start : nil,
            totalBreakTime: totalBreakTime,
            standardWorkingHours: standardWorkingHours
        )
    }
}
