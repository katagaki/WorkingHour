//
//  SessionData.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2026/02/08.
//

import Foundation

struct WorkSessionData {
    let entryId: String
    let clockInTime: Date
    let clockOutTime: Date?
    let isOnBreak: Bool
    let breakStartTime: Date?
    let totalBreakTime: TimeInterval
    let standardWorkingHours: TimeInterval
}
