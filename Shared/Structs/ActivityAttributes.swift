//
//  ActivityAttributes.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2026/02/08.
//

import ActivityKit
import Foundation

struct UshioAttributes: ActivityAttributes {
    let entryId: String

    struct ContentState: Codable, Hashable {
        var clockInTime: Date
        var isOnBreak: Bool
        var breakStartTime: Date?
        var totalBreakTime: TimeInterval
        var standardWorkingHours: TimeInterval

        static var working: UshioAttributes.ContentState {
            UshioAttributes.ContentState(
                clockInTime: Date.now.addingTimeInterval(-3600),
                isOnBreak: false,
                breakStartTime: nil,
                totalBreakTime: 0,
                standardWorkingHours: 28800
            )
        }

        static var onBreak: UshioAttributes.ContentState {
            UshioAttributes.ContentState(
                clockInTime: Date.now.addingTimeInterval(-7200),
                isOnBreak: true,
                breakStartTime: Date.now.addingTimeInterval(-600),
                totalBreakTime: 0,
                standardWorkingHours: 28800
            )
        }
    }
}
