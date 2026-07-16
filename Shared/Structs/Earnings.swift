//
//  Earnings.swift
//  WorkingHour
//
//  Created by Assistant on 2026/07/16.
//

import Foundation

// MARK: - Time Rounding

extension Date {
    /// Rounds the date to the nearest interval of `minutes`, or returns the
    /// date unchanged when `minutes` is 0.
    func rounded(toNearestMinutes minutes: Int) -> Date {
        guard minutes > 0 else { return self }
        let interval = TimeInterval(minutes * 60)
        let rounded = (timeIntervalSinceReferenceDate / interval).rounded() * interval
        return Date(timeIntervalSinceReferenceDate: rounded)
    }
}

extension ClockEntry {
    /// Clock-in time rounded to the nearest interval. Stored times are never
    /// modified; rounding only applies to exports and earnings calculations.
    func roundedClockInTime(minutes: Int) -> Date? {
        clockInTime?.rounded(toNearestMinutes: minutes)
    }

    /// Clock-out time rounded to the nearest interval.
    func roundedClockOutTime(minutes: Int) -> Date? {
        clockOutTime?.rounded(toNearestMinutes: minutes)
    }

    /// Total break time with each break's start and end rounded to the
    /// nearest interval.
    func roundedBreakTime(minutes: Int) -> TimeInterval {
        (breakTimes ?? []).reduce(into: .zero) { partialResult, breakTime in
            if let end = breakTime.end {
                let roundedStart = breakTime.start.rounded(toNearestMinutes: minutes)
                let roundedEnd = end.rounded(toNearestMinutes: minutes)
                partialResult += max(0, roundedEnd.timeIntervalSince(roundedStart))
            }
        }
    }

    /// Time worked with punches rounded to the nearest interval.
    func roundedTimeWorked(minutes: Int) -> TimeInterval? {
        guard let clockIn = roundedClockInTime(minutes: minutes),
              let clockOut = roundedClockOutTime(minutes: minutes) else {
            return nil
        }
        return max(0, clockOut.timeIntervalSince(clockIn) - roundedBreakTime(minutes: minutes))
    }

    /// Overtime beyond the standard working time, using rounded punches.
    func roundedOvertime(standardWorkingTime: TimeInterval, minutes: Int) -> TimeInterval? {
        guard let timeWorked = roundedTimeWorked(minutes: minutes) else { return nil }
        return max(0, timeWorked - standardWorkingTime)
    }
}

// MARK: - Earnings

/// Aggregated working time and estimated pay for a set of clock entries.
struct EarningsSummary {
    var regularTime: TimeInterval = .zero
    var overtime: TimeInterval = .zero
    var daysWorked: Int = 0
    var regularPay: Double = .zero
    var overtimePay: Double = .zero

    var totalTime: TimeInterval {
        regularTime + overtime
    }

    var totalPay: Double {
        regularPay + overtimePay
    }

    var averageTimePerDay: TimeInterval {
        daysWorked > 0 ? totalTime / Double(daysWorked) : .zero
    }
}

enum EarningsCalculator {
    /// Summarizes completed entries into worked/overtime hours and estimated
    /// pay. Regular hours are paid at `hourlyRate`; hours beyond
    /// `standardWorkingHours` per entry at `hourlyRate * overtimeMultiplier`.
    static func summarize(
        _ entries: [ClockEntry],
        standardWorkingHours: TimeInterval,
        hourlyRate: Double,
        overtimeMultiplier: Double,
        roundingMinutes: Int
    ) -> EarningsSummary {
        var summary = EarningsSummary()
        for entry in entries {
            guard let timeWorked = entry.roundedTimeWorked(minutes: roundingMinutes) else { continue }
            let overtime = max(0, timeWorked - standardWorkingHours)
            summary.regularTime += timeWorked - overtime
            summary.overtime += overtime
            summary.daysWorked += 1
        }
        summary.regularPay = summary.regularTime / 3600 * hourlyRate
        summary.overtimePay = summary.overtime / 3600 * hourlyRate * overtimeMultiplier
        return summary
    }
}
