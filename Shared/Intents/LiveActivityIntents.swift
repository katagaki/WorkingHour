//
//  LiveActivityIntents.swift
//  WorkingHour
//
//  Created by Assistant on 2026/02/07.
//

import ActivityKit
import AppIntents
import Foundation
import SwiftData
import WidgetKit

// NOTE: Intent target membership must include main app,
//       or LiveActivityIntent will fizzle out and refuse to find activities!

struct BreakData: Codable, Hashable {
    let start: Date
    let end: Date?
}

struct StartBreakIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "TimeClock.Break.Start"
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = false

    @Parameter(title: "EntryEditor.EntryID")
    var entryId: String

    init() {
        // Not implemented
    }

    init(entryId: String) {
        self.entryId = entryId
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        log("StartBreakIntent: Starting for entry ID: \(entryId)")
        guard ClockService.shared.activeEntry()?.id == entryId else {
            log("StartBreakIntent: No matching active entry found for ID: \(entryId)")
            return .result()
        }
        await ClockService.shared.startBreak(source: .intent)?.value
        log("StartBreakIntent: Completed successfully")
        return .result()
    }
}

struct EndBreakIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "TimeClock.Break.End"
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = false

    @Parameter(title: "EntryEditor.EntryID")
    var entryId: String

    init() {
        // Not implemented
    }

    init(entryId: String) {
        self.entryId = entryId
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        log("EndBreakIntent: Starting for entry ID: \(entryId)")
        guard ClockService.shared.activeEntry()?.id == entryId else {
            log("EndBreakIntent: No matching active entry found for ID: \(entryId)")
            return .result()
        }
        await ClockService.shared.endBreak(source: .intent)?.value
        log("EndBreakIntent: Completed successfully")
        return .result()
    }
}

struct ClockOutIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "TimeClock.Work.ClockOut"
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = false

    @Parameter(title: "EntryEditor.EntryID")
    var entryId: String

    init() {
        // Not implemented
    }

    init(entryId: String) {
        self.entryId = entryId
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        log("ClockOutIntent: Starting for entry ID: \(entryId)")
        guard ClockService.shared.activeEntry()?.id == entryId else {
            log("ClockOutIntent: No matching active entry found for ID: \(entryId)")
            return .result()
        }
        await ClockService.shared.clockOut(source: .intent, dismissActivityImmediately: false)?.value
        log("ClockOutIntent: Completed successfully")
        return .result()
    }
}
