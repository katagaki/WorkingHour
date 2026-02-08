//
//  WorkSessionIntents.swift
//  Ushio
//
//  Created by Assistant on 2026/02/07.
//

import AppIntents
import SwiftData
import Foundation

// MARK: - Break data structure for cross-target use
public struct BreakData: Codable, Hashable {
    let start: Date
    let end: Date?
}

// MARK: - Start Break Intent

struct StartBreakIntent: AppIntent, LiveActivityIntent, Sendable {
    static var title: LocalizedStringResource = "Start Break"
    static var description = IntentDescription("Start a break during the work session")
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = false

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

        do {
            try modelContext.save()
        } catch {
            // Handle error silently
        }

        // Small delay to ensure data is saved
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Update Live Activity
        if let sessionData = entry.toWorkSessionData() {
            await LiveActivityManager.shared.updateActivity(with: sessionData)
        }

        return .result()
    }
}

// MARK: - End Break Intent

struct EndBreakIntent: AppIntent, LiveActivityIntent, Sendable {
    static var title: LocalizedStringResource = "End Break"
    static var description = IntentDescription("End the current break")
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = false

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

        do {
            try modelContext.save()
        } catch {
            // Handle error silently
        }

        // Small delay to ensure data is saved
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Update Live Activity
        if let sessionData = entry.toWorkSessionData() {
            await LiveActivityManager.shared.updateActivity(with: sessionData)
        }

        return .result()
    }
}

// MARK: - Clock Out Intent

struct ClockOutIntent: AppIntent, LiveActivityIntent, Sendable {
    static var title: LocalizedStringResource = "Clock Out"
    static var description = IntentDescription("End the work session")
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = false

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

        do {
            try modelContext.save()
        } catch {
            // Handle error silently
        }

        // Small delay to ensure data is saved
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // End Live Activity
        if let sessionData = entry.toWorkSessionData() {
            await LiveActivityManager.shared.endActivity(with: sessionData)
        }

        return .result()
    }
}
// Extension to convert ClockEntry to WorkSessionData in the Ushio target
extension ClockEntry {
    @MainActor
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

        // Get standard working hours from settings
        let standardWorkingHours = SettingsManager.shared.standardWorkingHours

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
