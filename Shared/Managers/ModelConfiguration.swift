//
//  ModelConfiguration.swift
//  WorkingHour
//
//  Created by Assistant on 2026/02/07.
//

import SwiftData
import Foundation

// Shared model container singleton for app and widget extension
@MainActor
public class SharedModelContainer {
    public static let shared = SharedModelContainer()

    public let container: ModelContainer

    private init() {
        container = Self.createModelContainer()
    }

    private static func createModelContainer() -> ModelContainer {
        let schema = Schema([
            ClockEntry.self,
            Project.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier("group.com.tsubuzaki.WorkingHour")
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
