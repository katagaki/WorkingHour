//
//  LiveActivities.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2026/02/08.
//

import ActivityKit
import Foundation

class LiveActivities {
    public static func hasActivity(for entryId: String) -> Bool {
        let activities = Activity<UshioAttributes>.activities
        return activities.contains(where: { $0.attributes.entryId == entryId })
    }

    public static func ensureActivity(with data: WorkSessionData) async {
        guard data.clockOutTime == nil else {
            log("LiveActivityManager: Entry is already clocked out, not starting activity")
            return
        }

        if hasActivity(for: data.entryId) {
            log("LiveActivityManager: Activity already exists for entryId \(data.entryId)")
            return
        }

        log("LiveActivityManager: No activity found for entryId \(data.entryId), starting new one")
        await startActivity(with: data)
    }

    public static func startActivity(with data: WorkSessionData) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            log("LiveActivityManager: Activities are disabled for this app on this device")
            return
        }

        let attributes = UshioAttributes(entryId: data.entryId)
        let contentState = UshioAttributes.ContentState(
            clockInTime: data.clockInTime,
            clockOutTime: data.clockOutTime,
            isOnBreak: data.isOnBreak,
            breakStartTime: data.breakStartTime,
            totalBreakTime: data.totalBreakTime,
            standardWorkingHours: data.standardWorkingHours
        )
        let staleDate = data.clockInTime.addingTimeInterval(data.standardWorkingHours)
        let content = ActivityContent(state: contentState, staleDate: staleDate)

        do {
            let activity = try Activity<UshioAttributes>.request(attributes: attributes, content: content)
            log("LiveActivityManager: Started activity \(activity.id) for entryId \(activity.attributes.entryId)")
        } catch {
            log("LiveActivityManager: Error while starting activity: \(error), \(error.localizedDescription)")
        }
    }

    public static func updateActivity(with data: WorkSessionData) async {
        let contentState = UshioAttributes.ContentState(
            clockInTime: data.clockInTime,
            clockOutTime: data.clockOutTime,
            isOnBreak: data.isOnBreak,
            breakStartTime: data.breakStartTime,
            totalBreakTime: data.totalBreakTime,
            standardWorkingHours: data.standardWorkingHours
        )
        let staleDate = data.clockInTime.addingTimeInterval(data.standardWorkingHours)
        let content = ActivityContent(state: contentState, staleDate: staleDate)

        let activities = Activity<UshioAttributes>.activities
        log("LiveActivityManager: Looking for activity with entryId: \(data.entryId) in \(activities.count) activities")
        if let activity = activities.first(where: { $0.attributes.entryId == data.entryId }) {
            log("LiveActivityManager: Updating activity content for \(activity.attributes.entryId)")
            await activity.update(content)
        } else {
            log("LiveActivityManager: No matching activity found")
        }
    }

    public static func endActivity(with data: WorkSessionData, immediately: Bool = false) async {
        let contentState = UshioAttributes.ContentState(
            clockInTime: data.clockInTime,
            clockOutTime: data.clockOutTime,
            isOnBreak: false,
            breakStartTime: nil,
            totalBreakTime: data.totalBreakTime,
            standardWorkingHours: data.standardWorkingHours
        )
        let dismissDate = Date(timeIntervalSinceNow: 1800)
        let content = ActivityContent(state: contentState, staleDate: immediately ? nil : dismissDate)

        let activities = Activity<UshioAttributes>.activities
        if let activity = activities.first(where: { $0.attributes.entryId == data.entryId }) {
            log("LiveActivityManager: Ending activity \(activity.attributes.entryId)")
            await activity.end(
                content,
                dismissalPolicy: immediately ? .immediate : .after(dismissDate)
            )
        } else {
            log("LiveActivityManager: No matching activity found")
        }
    }
}
