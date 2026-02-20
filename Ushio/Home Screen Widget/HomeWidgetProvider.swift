//
//  HomeWidgetProvider.swift
//  Ushio
//
//  Created by シン・ジャスティン on 2026/02/20.
//

import SwiftData
import SwiftUI
import WidgetKit

struct HomeWidgetEntry: TimelineEntry {
    let date: Date
    let clockInTime: Date?
    let clockOutTime: Date?
    let isOnBreak: Bool
    let totalBreakTime: TimeInterval
    let standardWorkingHours: TimeInterval

    var isActive: Bool {
        clockInTime != nil && clockOutTime == nil
    }

    var timeWorked: TimeInterval? {
        guard let clockInTime else { return nil }
        let endTime = clockOutTime ?? Date.now
        return endTime.timeIntervalSince(clockInTime) - totalBreakTime
    }

    static var placeholder: HomeWidgetEntry {
        HomeWidgetEntry(
            date: .now,
            clockInTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now),
            clockOutTime: nil,
            isOnBreak: false,
            totalBreakTime: 0,
            standardWorkingHours: 8 * 3600
        )
    }

    static var empty: HomeWidgetEntry {
        HomeWidgetEntry(
            date: .now,
            clockInTime: nil,
            clockOutTime: nil,
            isOnBreak: false,
            totalBreakTime: 0,
            standardWorkingHours: 8 * 3600
        )
    }
}

struct HomeWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> HomeWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (HomeWidgetEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
        } else {
            completion(fetchEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HomeWidgetEntry>) -> Void) {
        let entry = fetchEntry()

        let refreshDate: Date
        if entry.isActive {
            // Refresh every 15 minutes while working
            refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        } else {
            // Refresh every hour when idle
            refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        }

        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }

    @MainActor
    private func fetchEntry() -> HomeWidgetEntry {
        let modelContext = SharedModelContainer.shared.container.mainContext
        let standardWorkingHours = SettingsManager.shared.standardWorkingHours

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? .now

        let descriptor = FetchDescriptor<ClockEntry>(
            predicate: #Predicate {
                $0.clockInTime != nil &&
                $0.clockInTime! >= startOfDay &&
                $0.clockInTime! < endOfDay
            },
            sortBy: [SortDescriptor(\.clockInTime, order: .reverse)]
        )

        guard let entries = try? modelContext.fetch(descriptor),
              let entry = entries.first else {
            return HomeWidgetEntry(
                date: .now,
                clockInTime: nil,
                clockOutTime: nil,
                isOnBreak: false,
                totalBreakTime: 0,
                standardWorkingHours: standardWorkingHours
            )
        }

        let totalBreakTime = (entry.breakTimes ?? []).reduce(into: 0.0) { result, breakTime in
            if let end = breakTime.end {
                result += end.timeIntervalSince(breakTime.start)
            }
        }

        return HomeWidgetEntry(
            date: .now,
            clockInTime: entry.clockInTime,
            clockOutTime: entry.clockOutTime,
            isOnBreak: entry.isOnBreak,
            totalBreakTime: totalBreakTime,
            standardWorkingHours: standardWorkingHours
        )
    }
}
