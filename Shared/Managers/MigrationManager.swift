//
//  MigrationManager.swift
//  WorkingHour
//
//  Created by Assistant on 2026/02/07.
//

import SwiftData
import SwiftUI

struct MigrationManager {
    static let shared = MigrationManager()

    // Temporary structs for decoding legacy JSON
    struct LegacyClockEntry: Codable {
        var id: String
        var clockInTime: Date?
        var clockOutTime: Date?
        var breakTimes: [Break]
        var isOnBreak: Bool
        var projectTasks: [String: String]
    }

    struct LegacyProject: Codable {
        var id: String
        var name: String
        var createdAt: Date
        var isActive: Bool
    }

    @MainActor
    func migrate(modelContext: ModelContext) {
        let textKey = "HasMigratedToSwiftData"
        let defaults = UserDefaults.standard

        guard !defaults.bool(forKey: textKey) else { return }

        print("Starting migration to SwiftData...")

        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataDirectory = documentsDirectory.appendingPathComponent("WorkingHourData")
        let entriesFileURL = dataDirectory.appendingPathComponent("clock_entries.json")
        let projectsFileURL = dataDirectory.appendingPathComponent("projects.json")

        // Migrate Entries
        if fileManager.fileExists(atPath: entriesFileURL.path) {
            do {
                let data = try Data(contentsOf: entriesFileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let legacyEntries = try decoder.decode([LegacyClockEntry].self, from: data)

                for legacy in legacyEntries {
                    let entry = ClockEntry(legacy.clockInTime)
                    entry.id = legacy.id
                    entry.clockOutTime = legacy.clockOutTime
                    entry.breakTimes = legacy.breakTimes
                    entry.isOnBreak = legacy.isOnBreak
                    entry.projectTasks = legacy.projectTasks
                    modelContext.insert(entry)
                }
                print("Migrated \(legacyEntries.count) entries.")
            } catch {
                print("Error migrating entries: \(error)")
            }
        }

        // Migrate Projects
        if fileManager.fileExists(atPath: projectsFileURL.path) {
            do {
                let data = try Data(contentsOf: projectsFileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let legacyProjects = try decoder.decode([LegacyProject].self, from: data)

                for legacy in legacyProjects {
                    let project = Project(name: legacy.name)
                    project.id = legacy.id
                    project.createdAt = legacy.createdAt
                    project.isActive = legacy.isActive
                    modelContext.insert(project)
                }
                print("Migrated \(legacyProjects.count) projects.")
            } catch {
                print("Error migrating projects: \(error)")
            }
        }

        defaults.set(true, forKey: textKey)
        try? modelContext.save()
        print("Migration complete.")
    }
}
