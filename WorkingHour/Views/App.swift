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
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    let context = SharedModelContainer.shared.container.mainContext
                    DataManager.shared.modelContext = context
                    DataManager.shared.loadAll()
                    checkAndRestoreLiveActivity(context: context)
                }
        }
        .environmentObject(navigator)
        .modelContainer(SharedModelContainer.shared.container)
        .onChange(of: navigator.selectedTab) { _, _ in
            navigator.saveToDefaults()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                let context = SharedModelContainer.shared.container.mainContext
                checkAndRestoreLiveActivity(context: context)
            }
        }
    }

    private func checkAndRestoreLiveActivity(context: ModelContext) {
        // Fetch active entries (entries without clock out time)
        let descriptor = FetchDescriptor<ClockEntry>(
            predicate: #Predicate { $0.clockOutTime == nil },
            sortBy: [SortDescriptor(\.clockInTime, order: .reverse)]
        )

        if let activeEntry = try? context.fetch(descriptor).first,
           let sessionData = activeEntry.toWorkSessionData() {
            Task {
                await LiveActivities.ensureActivity(with: sessionData)
            }
        }
    }
}
