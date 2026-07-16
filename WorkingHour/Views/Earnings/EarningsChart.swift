//
//  EarningsChart.swift
//  WorkingHour
//
//  Created by Assistant on 2026/07/16.
//

import Charts
import SwiftUI

/// A stacked bar chart of hours worked per day (or per month in the year
/// view), split into regular time and overtime.
struct EarningsChart: View {
    let entries: [ClockEntry]
    let period: EarningsPeriod
    let standardWorkingHours: TimeInterval
    let roundingMinutes: Int

    private struct ChartPoint: Identifiable {
        let date: Date
        var regularHours: Double = 0
        var overtimeHours: Double = 0

        var id: Date { date }
    }

    private var points: [ChartPoint] {
        let calendar = Calendar.current
        var buckets: [Date: ChartPoint] = [:]
        for entry in entries {
            guard let clockInTime = entry.clockInTime,
                  let timeWorked = entry.roundedTimeWorked(minutes: roundingMinutes) else { continue }
            let bucketDate: Date = if period.chartUnit == .month {
                calendar.dateInterval(of: .month, for: clockInTime)?.start
                    ?? calendar.startOfDay(for: clockInTime)
            } else {
                calendar.startOfDay(for: clockInTime)
            }
            let overtime = max(0, timeWorked - standardWorkingHours)
            var point = buckets[bucketDate] ?? ChartPoint(date: bucketDate)
            point.regularHours += (timeWorked - overtime) / 3600
            point.overtimeHours += overtime / 3600
            buckets[bucketDate] = point
        }
        return buckets.values.sorted { $0.date < $1.date }
    }

    var body: some View {
        let regularLabel = String(localized: "Earnings.Series.Regular")
        let overtimeLabel = String(localized: "Shared.Overtime")

        Chart(points) { point in
            BarMark(
                x: .value("Shared.Date", point.date, unit: period.chartUnit),
                y: .value("Shared.Hours", point.regularHours)
            )
            .foregroundStyle(by: .value("Earnings.Series", regularLabel))
            BarMark(
                x: .value("Shared.Date", point.date, unit: period.chartUnit),
                y: .value("Shared.Hours", point.overtimeHours)
            )
            .foregroundStyle(by: .value("Earnings.Series", overtimeLabel))
        }
        .chartForegroundStyleScale([
            regularLabel: Color.accentColor,
            overtimeLabel: Color.orange
        ])
        .chartXAxis {
            switch period {
            case .week:
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                }
            case .month:
                AxisMarks(values: .automatic(desiredCount: 6)) { value in
                    AxisGridLine()
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: .dateTime.day())
                        }
                    }
                }
            case .year:
                AxisMarks(values: .stride(by: .month)) { value in
                    AxisGridLine()
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: .dateTime.month(.narrow))
                        }
                    }
                }
            }
        }
        .chartXScale(domain: chartDomain)
        .frame(height: 220.0)
        .padding(.vertical, 8.0)
    }

    /// Pins the x axis to the full period so partial data doesn't stretch.
    private var chartDomain: ClosedRange<Date> {
        let interval = period.interval(containing: .now)
        return interval.start...interval.end
    }
}
