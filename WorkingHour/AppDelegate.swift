//
//  AppDelegate.swift
//  WorkingHour
//
//  Created by Assistant on 2026/07/16.
//

import UIKit

/// Wires up the managers as early as possible in the launch sequence.
///
/// When iOS relaunches the app in the background for a location event (a
/// geofence crossing or a significant location change), no scene is created
/// and SwiftUI's `onAppear` never runs — so everything the event handlers
/// need must be ready by the end of `didFinishLaunching`.
@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if launchOptions?[.location] != nil {
            log("AppDelegate: Launched in the background for a location event", prefix: "MIKA")
        }

        DataManager.shared.modelContext = SharedModelContainer.shared.container.mainContext
        DataManager.shared.loadAll()

        // Arm the notification delegate so confirmation actions are handled
        // even when the app is launched in the background.
        _ = NotificationManager.shared

        // Re-arm the location manager delegate so the event that caused this
        // launch is delivered, and resume session upkeep if a session is open.
        GeofencingManager.shared.bootstrap()

        return true
    }
}
