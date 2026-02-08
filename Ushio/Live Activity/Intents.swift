//
//  Intents.swift
//  Ushio
//
//  Created by Assistant on 2026/02/07.
//

import AppIntents
import SwiftData
import Foundation
import WidgetKit

public struct BreakData: Codable, Hashable {
    let start: Date
    let end: Date?
}

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
        log("StartBreakIntent: Starting for entry ID: \(entryId)")
        let modelContext = SharedModelContainer.shared.container.mainContext
        let descriptor = FetchDescriptor<ClockEntry>(
            predicate: #Predicate { $0.id == entryId && $0.clockOutTime == nil }
        )
        guard let entries = try? modelContext.fetch(descriptor),
              let entry = entries.first else {
            log("StartBreakIntent: No matching entry found for ID: \(entryId)")
            return .result()
        }

        log("StartBreakIntent: Found entry, adding break")
        entry.breakTimes.append(Break(start: .now))
        entry.isOnBreak = true
        do {
            try modelContext.save()
            log("StartBreakIntent: Successfully saved changes")
        } catch {
            log("StartBreakIntent: Failed to save changes: \(error.localizedDescription)")
        }
        modelContext.processPendingChanges()

        WidgetCenter.shared.reloadAllTimelines()
        log("StartBreakIntent: Reloaded widget timelines")

        if let sessionData = entry.toWorkSessionData() {
            log("StartBreakIntent: Updating live activity \(sessionData.entryId)")
            await LiveActivities.updateActivity(with: sessionData)
        }

        log("StartBreakIntent: Completed successfully")
        return .result()
    }
}

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
        log("EndBreakIntent: Starting for entry ID: \(entryId)")
        let modelContext = SharedModelContainer.shared.container.mainContext

        let descriptor = FetchDescriptor<ClockEntry>(
            predicate: #Predicate { $0.id == entryId && $0.clockOutTime == nil }
        )

        guard let entries = try? modelContext.fetch(descriptor),
              let entry = entries.first,
              let startTime = entry.breakTimes.last?.start,
              entry.breakTimes.last?.end == nil else {
            log("EndBreakIntent: No matching entry or active break found for ID: \(entryId)")
            return .result()
        }

        log("EndBreakIntent: Found active break, ending it")
        entry.breakTimes.removeLast()
        entry.breakTimes.append(Break(start: startTime, end: .now))
        entry.isOnBreak = false

        do {
            try modelContext.save()
            log("EndBreakIntent: Successfully saved changes")
        } catch {
            log("EndBreakIntent: Failed to save changes: \(error.localizedDescription)")
        }

        // Ensure changes are processed
        modelContext.processPendingChanges()

        // Small delay to ensure data is saved
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Reload widgets
        WidgetCenter.shared.reloadAllTimelines()
        log("EndBreakIntent: Reloaded widget timelines")

        // Update Live Activity
        if let sessionData = entry.toWorkSessionData() {
            log("EndBreakIntent: Updating live activity")
            await LiveActivities.updateActivity(with: sessionData)
        }

        log("EndBreakIntent: Completed successfully")
        return .result()
    }
}

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
        log("ClockOutIntent: Starting for entry ID: \(entryId)")
        let modelContext = SharedModelContainer.shared.container.mainContext

        let descriptor = FetchDescriptor<ClockEntry>(
            predicate: #Predicate { $0.id == entryId && $0.clockOutTime == nil }
        )

        guard let entries = try? modelContext.fetch(descriptor),
              let entry = entries.first else {
            log("ClockOutIntent: No matching entry found for ID: \(entryId)")
            return .result()
        }

        log("ClockOutIntent: Found entry, clocking out")
        entry.clockOutTime = .now
        entry.isOnBreak = false

        do {
            try modelContext.save()
            log("ClockOutIntent: Successfully saved changes")
        } catch {
            log("ClockOutIntent: Failed to save changes: \(error.localizedDescription)")
        }

        // Ensure changes are processed
        modelContext.processPendingChanges()

        // Small delay to ensure data is saved
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Reload widgets
        WidgetCenter.shared.reloadAllTimelines()
        log("ClockOutIntent: Reloaded widget timelines")

        // End Live Activity
        if let sessionData = entry.toWorkSessionData() {
            log("ClockOutIntent: Ending live activity")
            await LiveActivities.endActivity(with: sessionData)
        }

        log("ClockOutIntent: Completed successfully")
        return .result()
    }
}
