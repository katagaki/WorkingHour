//
//  SwiftData.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2024/12/09.
//

import SwiftData

let sharedModelContainer: ModelContainer = {
    let schema = Schema([ClockEntry.self, AppSettings.self, Project.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()
