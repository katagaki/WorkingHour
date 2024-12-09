//
//  WorkingHourApp.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2024/10/09.
//

import Komponents
import SwiftUI
import SwiftData

@main
struct WorkingHourApp: App {

    @StateObject var navigator = Navigator<TabType, ViewPath>()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
        .environmentObject(navigator)
        .onChange(of: navigator.selectedTab) { _, _ in
            navigator.saveToDefaults()
        }
    }
}
