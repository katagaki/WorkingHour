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

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    let context = SharedModelContainer.shared.container.mainContext
                    // Set DataManager context
                    DataManager.shared.modelContext = context

                    // Reload DataManager
                    DataManager.shared.loadAll()
                }
        }
        .environmentObject(navigator)
        .modelContainer(SharedModelContainer.shared.container)
        .onChange(of: navigator.selectedTab) { _, _ in
            navigator.saveToDefaults()
        }
    }
}
