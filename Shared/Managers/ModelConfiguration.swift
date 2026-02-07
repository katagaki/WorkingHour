//
//  ModelConfiguration.swift
//  WorkingHour
//
//  Created by Assistant on 2026/02/07.
//

import SwiftData
import Foundation

// Shared model container configuration for app and widget extension
@MainActor
class SharedModelConfiguration {
    static let appGroupIdentifier = "group.com.tsubuzaki.WorkingHour"
    
    static func createModelContainer() -> ModelContainer {
        let schema = Schema([
            ClockEntry.self,
            Project.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: containerURL(),
            allowsSave: true
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    static func containerURL() -> URL {
        let fileManager = FileManager.default
        guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            fatalError("Shared app group container could not be created.")
        }
        return containerURL.appendingPathComponent("WorkingHour.sqlite")
    }
}
