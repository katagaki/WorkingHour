//
//  ClockEntry.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2024/10/11.
//

import Foundation
import SwiftData

@Model
final class ClockEntry {
    var id: String = UUID().uuidString

    var clockInTime: Date?
    var clockOutTime: Date?
    var breakTimes: [Break] = []
    var isOnBreak: Bool = false

    // Project ID : Task Information
    var projectTasks: [String: String] = [:]

    init(_ clockInTime: Date? = nil) {
        self.clockInTime = clockInTime
    }

    func clockIn() {
        clockInTime = .now
    }

    func clockOut() {
        clockOutTime = .now
    }

    func clockInDateString() -> String? {
        if let clockInTime {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: clockInTime)
        } else {
            return nil
        }
    }

    func clockInDayString() -> String? {
        if let clockInTime {
            let formatter = DateFormatter()
            return formatter.weekdaySymbols[Calendar.current.component(.weekday, from: clockInTime) - 1]
        } else {
            return nil
        }
    }

    func clockInTimeString() -> String? {
        if let clockInTime {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .medium
            return formatter.string(from: clockInTime)
        } else {
            return nil
        }
    }

    func clockOutDateString() -> String? {
        if let clockOutTime {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: clockOutTime)
        } else {
            return nil
        }
    }

    func clockOutTimeString() -> String? {
        if let clockOutTime {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .medium
            return formatter.string(from: clockOutTime)
        } else {
            return nil
        }
    }

    func breakTime() -> TimeInterval {
        return breakTimes.reduce(into: .zero) { partialResult, breakTime in
            partialResult += breakTime.time()
        }
    }

    func breakTimeString() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .full
        return formatter.string(from: breakTime()) ?? ""
    }

    func timeWorked() -> TimeInterval? {
        if let clockInTime, let clockOutTime {
            return (clockOutTime.timeIntervalSince(clockInTime)) - breakTime()
        } else {
            return nil
        }
    }

    func timeWorkedString() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .full
        return formatter.string(from: timeWorked() ?? .zero) ?? ""
    }

    func overtime(standardWorkingTime: TimeInterval = .zero) -> TimeInterval? {
        if let timeWorked = timeWorked() {
            if timeWorked > standardWorkingTime {
                return timeWorked - standardWorkingTime
            } else {
                return .zero
            }
        } else {
            return nil
        }
    }

    func overtimeString(standardWorkingTime: TimeInterval = .zero) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .full
        return formatter.string(from: overtime(standardWorkingTime: standardWorkingTime) ?? .zero) ?? ""
    }
}
