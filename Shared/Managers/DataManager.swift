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
        } catch {
            print("Error loading data: \(error)")
            clockEntries = []
            projects = []
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
}
