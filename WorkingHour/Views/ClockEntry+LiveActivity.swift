//
//  ClockEntry+LiveActivity.swift
//  WorkingHour
//
//  Created by Assistant on 2026/02/07.
//

import Foundation

// Simplified work session data that can be passed to the Live Activity
public struct WorkSessionData {
    let entryId: String
    let clockInTime: Date
    let isOnBreak: Bool
    let breakStartTime: Date?
    let totalBreakTime: TimeInterval
    let standardWorkingHours: TimeInterval
}

extension ClockEntry {
    func toWorkSessionData(standardWorkingHours: TimeInterval) -> WorkSessionData? {
        guard let clockInTime = self.clockInTime,
              self.clockOutTime == nil else {
            return nil
        }

        return WorkSessionData(
            entryId: self.id,
            clockInTime: clockInTime,
            isOnBreak: self.isOnBreak,
            breakStartTime: self.isOnBreak ? self.breakTimes.last?.start : nil,
            totalBreakTime: self.breakTime(),
            standardWorkingHours: standardWorkingHours
        )
    }
}
