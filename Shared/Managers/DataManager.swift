//
//  DataManager.swift
//  WorkingHour
//
//  Created by Assistant on 2026/02/07.
//
//

import Foundation
import SwiftData

@MainActor
@Observable
final class DataManager {

    static let shared = DataManager()

    var modelContext: ModelContext?

    private(set) var clockEntries: [ClockEntry] = []
    private(set) var projects: [Project] = []
    private(set) var tasks: [ProjectTask] = []

    private init() {
    }

    // MARK: - Load Data

    func loadAll() {
        guard let modelContext else { return }

        do {
            let entryDescriptor = FetchDescriptor<ClockEntry>(sortBy: [SortDescriptor(\.clockInTime, order: .reverse)])
            clockEntries = try modelContext.fetch(entryDescriptor)

            let projectDescriptor = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            projects = try modelContext.fetch(projectDescriptor)

            let taskDescriptor = FetchDescriptor<ProjectTask>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            tasks = try modelContext.fetch(taskDescriptor)
        } catch {
            print("Error loading data: \(error)")
            clockEntries = []
            projects = []
            tasks = []
        }
    }

    // MARK: - Save Data

    func save() {
        do {
            try modelContext?.save()
        } catch {
            print("Error saving data: \(error)")
        }
    }

    // MARK: - Clock Entry Operations

    func addClockEntry(_ entry: ClockEntry) {
        modelContext?.insert(entry)
        save()
        loadAll()
    }

    func updateClockEntry(_ entry: ClockEntry) {
        save()
        loadAll()
    }

    func deleteClockEntry(_ entry: ClockEntry) {
        modelContext?.delete(entry)
        save()
        loadAll()
    }

    func deleteClockEntry(at offsets: IndexSet) {
        for index in offsets {
            let entry = clockEntries[index]
            modelContext?.delete(entry)
        }
        save()
        loadAll()
    }

    func getActiveEntry() -> ClockEntry? {
        clockEntries.first { $0.clockOutTime == nil }
    }

    func entries(in month: Int, year: Int) -> [ClockEntry] {
        let (startDate, endDate) = firstAndLastDayOfMonth(month: month, year: year)
        return clockEntries.filter { entry in
            guard let clockInTime = entry.clockInTime else { return false }
            return clockInTime >= startDate && clockInTime <= endDate
        }.sorted { ($0.clockInTime ?? .distantPast) < ($1.clockInTime ?? .distantPast) }
    }

    private func firstAndLastDayOfMonth(month: Int, year: Int) -> (firstDay: Date, lastDay: Date) {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0

        let calendar = Calendar.current
        if let firstDay = calendar.date(from: components) {
            if let firstDayOfNextMonth = calendar.date(byAdding: .month, value: 1, to: firstDay),
               let lastDay = calendar.date(byAdding: .second, value: -1, to: firstDayOfNextMonth) {
                return (firstDay, lastDay)
            }
        }
        return (.distantPast, .distantFuture)
    }

    // MARK: - Project Operations

    func addProject(_ project: Project) {
        modelContext?.insert(project)
        save()
        loadAll()
    }

    func updateProject(_ project: Project) {
        save()
        loadAll()
    }

    func deleteProject(_ project: Project) {
        modelContext?.delete(project)
        save()
        loadAll()
    }

    var activeProjects: [Project] {
        projects.filter { $0.isActive }.sorted { $0.name < $1.name }
    }

    var archivedProjects: [Project] {
        projects.filter { !$0.isActive }
    }

    // MARK: - Debug Operations

    #if DEBUG
    func populateSampleData() {
        guard let modelContext else { return }

        let calendar = Calendar.current
        let now = Date.now

        // Create today's ongoing entry (clock in only at 9am with random variation)
        var todayClockInComponents = calendar.dateComponents([.year, .month, .day], from: now)
        todayClockInComponents.hour = 9
        todayClockInComponents.minute = 0
        todayClockInComponents.second = 0

        if let baseTodayClockIn = calendar.date(from: todayClockInComponents) {
            let todayVariation = Int.random(in: -5...5)
            if let todayClockIn = calendar.date(byAdding: .minute, value: todayVariation, to: baseTodayClockIn) {
                let todayEntry = ClockEntry(todayClockIn)
                modelContext.insert(todayEntry)
            }
        }

        // Create sample data for the past 29 days (excluding today)
        for daysAgo in 1..<30 {
            guard let dayDate = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }

            // Skip weekends (Saturday = 7, Sunday = 1)
            let weekday = calendar.component(.weekday, from: dayDate)
            if weekday == 1 || weekday == 7 { continue }

            // Random variation between -5 and +5 minutes
            let clockInVariation = Int.random(in: -10...15)
            let clockOutVariation = Int.random(in: -5...85)

            // Set clock in time to 9:00 AM with random variation
            var clockInComponents = calendar.dateComponents([.year, .month, .day], from: dayDate)
            clockInComponents.hour = 9
            clockInComponents.minute = 0
            clockInComponents.second = 0

            guard let baseClockInTime = calendar.date(from: clockInComponents),
                  let clockInTime = calendar.date(
                    byAdding: .minute,
                    value: clockInVariation, to: baseClockInTime
                  ) else { continue }

            let entry = ClockEntry(clockInTime)

            // Add clock out at 6:00 PM with random variation
            var clockOutComponents = calendar.dateComponents([.year, .month, .day], from: dayDate)
            clockOutComponents.hour = 18
            clockOutComponents.minute = 0
            clockOutComponents.second = 0

            if let baseClockOutTime = calendar.date(from: clockOutComponents),
               let clockOutTime = calendar.date(byAdding: .minute, value: clockOutVariation, to: baseClockOutTime) {
                entry.clockOutTime = clockOutTime

                // Add 1 hour break starting at 12:00 PM
                var breakStartComponents = calendar.dateComponents([.year, .month, .day], from: dayDate)
                breakStartComponents.hour = 12
                breakStartComponents.minute = 0
                breakStartComponents.second = 0

                if let breakStart = calendar.date(from: breakStartComponents),
                   let breakEnd = calendar.date(byAdding: .hour, value: 1, to: breakStart) {
                    let sampleBreak = Break(start: breakStart, end: breakEnd)
                    sampleBreak.clockEntry = entry
                    modelContext.insert(sampleBreak)
                }

                modelContext.insert(entry)
            }
        }

        save()
        loadAll()
    }

    func clearAllData() {
        guard let modelContext else { return }

        // Delete all clock entries
        for entry in clockEntries {
            modelContext.delete(entry)
        }

        // Delete all projects
        for project in projects {
            modelContext.delete(project)
        }

        // Delete all tasks (in case any orphaned)
        for task in tasks {
            modelContext.delete(task)
        }

        save()
        loadAll()
    }
    #endif
}
