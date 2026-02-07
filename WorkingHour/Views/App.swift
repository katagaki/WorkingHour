//
//  WorkingHourApp.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2024/10/09.
//

import Komponents
import SwiftData
import SwiftUI

@main
struct WorkingHourApp: App {

    @StateObject var navigator = Navigator<TabType, ViewPath>()

    // Create the model container for SwiftData
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: ClockEntry.self, Project.self)
        } catch {
            fatalError("Failed to create ModelContainer for ClockEntry and Project.")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    let context = container.mainContext
                    // Set DataManager context
                    DataManager.shared.modelContext = context

                    // Perform migration
                    MigrationManager().migrate(modelContext: context)

                    // Reload DataManager
                    DataManager.shared.loadAll()
                }
        }
        .environmentObject(navigator)
        .modelContainer(container)
        .onChange(of: navigator.selectedTab) { _, _ in
            navigator.saveToDefaults()
        }
    }
}
