//
//  LiveActivityManager.swift
//  WorkingHour
//
//  Created by Assistant on 2026/02/07.
//

import ActivityKit
import Foundation

@MainActor
public final class LiveActivityManager {
    public static let shared = LiveActivityManager()

    private var currentActivity: Activity<UshioAttributes>?

    private init() {}

    // Start a Live Activity for a work session
    public func startActivity(with data: WorkSessionData) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        let attributes = UshioAttributes(entryId: data.entryId)
        let contentState = UshioAttributes.ContentState(
            clockInTime: data.clockInTime,
            isOnBreak: data.isOnBreak,
            breakStartTime: data.breakStartTime,
            totalBreakTime: data.totalBreakTime,
            standardWorkingHours: data.standardWorkingHours
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil)
            )
            currentActivity = activity
        } catch {
            print("Error starting Live Activity: \(error)")
        }
    }

    // Update the Live Activity
    public func updateActivity(with data: WorkSessionData) {
        let contentState = UshioAttributes.ContentState(
            clockInTime: data.clockInTime,
            isOnBreak: data.isOnBreak,
            breakStartTime: data.breakStartTime,
            totalBreakTime: data.totalBreakTime,
            standardWorkingHours: data.standardWorkingHours
        )

        Task {
            // Try to find the activity if we don't have a reference
            if currentActivity == nil {
                currentActivity = Activity<UshioAttributes>.activities.first(where: { $0.attributes.entryId == data.entryId })
            }
            
            await currentActivity?.update(
                .init(state: contentState, staleDate: nil)
            )
        }
    }

    // End the Live Activity
    public func endActivity(with data: WorkSessionData) {
        let contentState = UshioAttributes.ContentState(
            clockInTime: data.clockInTime,
            isOnBreak: false,
            breakStartTime: nil,
            totalBreakTime: data.totalBreakTime,
            standardWorkingHours: data.standardWorkingHours
        )

        Task {
            // Try to find the activity if we don't have a reference
            if currentActivity == nil {
                currentActivity = Activity<UshioAttributes>.activities.first(where: { $0.attributes.entryId == data.entryId })
            }
            
            await currentActivity?.end(
                .init(state: contentState, staleDate: nil),
                dismissalPolicy: .default
            )
            currentActivity = nil
        }
    }

    // Check if there's an active Live Activity
    public var hasActiveActivity: Bool {
        currentActivity != nil
    }
}

// UshioAttributes - must match the definition in the widget extension
public struct UshioAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var clockInTime: Date
        public var isOnBreak: Bool
        public var breakStartTime: Date?
        public var totalBreakTime: TimeInterval
        public var standardWorkingHours: TimeInterval

        public init(clockInTime: Date, isOnBreak: Bool, breakStartTime: Date?, totalBreakTime: TimeInterval, standardWorkingHours: TimeInterval) {
            self.clockInTime = clockInTime
            self.isOnBreak = isOnBreak
            self.breakStartTime = breakStartTime
            self.totalBreakTime = totalBreakTime
            self.standardWorkingHours = standardWorkingHours
        }
    }

    public var entryId: String

    public init(entryId: String) {
        self.entryId = entryId
    }
}
