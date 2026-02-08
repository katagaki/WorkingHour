//
//  UshioControl.swift
//  Ushio
//
//  Created by シン・ジャスティン on 2024/12/09.
//

import AppIntents
import SwiftUI
import SwiftData
import WidgetKit

// MARK: - Start Work Session Control

struct StartWorkSessionControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.tsubuzaki.WorkingHour.Ushio.Start"
        ) {
            ControlWidgetButton(action: StartWorkSessionIntent()) {
                Label("Clock In", systemImage: "play.fill")
            }
        }
        .displayName("Clock In")
        .description("Start a new work session")
    }
}

// MARK: - End Work Session Control

struct EndWorkSessionControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.tsubuzaki.WorkingHour.Ushio.End"
        ) {
            ControlWidgetButton(action: EndWorkSessionIntent()) {
                Label("Clock Out", systemImage: "stop.fill")
            }
        }
        .displayName("Clock Out")
        .description("End the current work session")
    }
}

// MARK: - Start Work Session Intent

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
            await LiveActivityManager.shared.startActivity(with: sessionData)
        }

        return .result()
    }
}

// MARK: - End Work Session Intent

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
            await LiveActivityManager.shared.endActivity(with: sessionData)
        }

        return .result()
    }
}
