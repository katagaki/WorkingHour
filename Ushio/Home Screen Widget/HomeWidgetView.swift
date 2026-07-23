//
//  HomeWidgetView.swift
//  Ushio
//
//  Created by シン・ジャスティン on 2026/02/20.
//

import SwiftUI
import WidgetKit

struct HomeWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: HomeWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    // MARK: - Small Widget

    var smallWidget: some View {
        VStack(alignment: .leading, spacing: 6.0) {
            HStack(spacing: 4.0) {
                Image(systemName: statusIcon)
                    .font(.caption2)
                    .foregroundStyle(statusColor)
                Text(statusText)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(statusColor)
            }

            Spacer()

            if let clockInTime = entry.clockInTime {
                VStack(alignment: .leading, spacing: 2.0) {
                    Text("TimeClock.Work.ClockIn")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(clockInTime, style: .time)
                        .font(.title3)
                        .fontWeight(.bold)
                }

                if entry.clockOutTime != nil {
                    if let timeWorked = entry.timeWorked {
                        VStack(alignment: .leading, spacing: 2.0) {
                            Text("Timesheet.TotalTimeWorked")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(formatTimeInterval(timeWorked))
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                    }
                } else if entry.isActive {
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text(entry.isOnBreak ? "TimeClock.Break.OnBreak" : "TimeClock.Work.Working")
                            .font(.caption2)
                            .foregroundStyle(entry.isOnBreak ? .orange : .secondary)
                        Text(clockInTime, style: .relative)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(entry.isOnBreak ? .orange : .primary)
                    }
                }
            } else {
                Text("Widget.NotClockedIn")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            clockButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// One-tap clock in/out without opening the app.
    var clockButton: some View {
        Group {
            if entry.isActive {
                Button(intent: QuickClockOutIntent()) {
                    Label("TimeClock.Work.ClockOut", systemImage: "figure.walk.departure")
                        .frame(maxWidth: .infinity)
                }
                .tint(.red)
            } else {
                Button(intent: QuickClockInIntent()) {
                    Label("TimeClock.Work.ClockIn", systemImage: "figure.walk.arrival")
                        .frame(maxWidth: .infinity)
                }
                .tint(.accent)
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
        .font(.caption)
        .fontWeight(.semibold)
    }

    // MARK: - Medium Widget

    var mediumWidget: some View {
        VStack(spacing: 10.0) {
            mediumWidgetContent
            clockButton
        }
    }

    var mediumWidgetContent: some View {
        HStack(spacing: 16.0) {
            VStack(alignment: .leading, spacing: 6.0) {
                HStack(spacing: 4.0) {
                    Image(systemName: statusIcon)
                        .font(.caption2)
                        .foregroundStyle(statusColor)
                    Text(statusText)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(statusColor)
                }

                Spacer()

                if let clockInTime = entry.clockInTime {
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text("TimeClock.Work.ClockIn")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(clockInTime, style: .time)
                            .font(.title3)
                            .fontWeight(.bold)
                    }

                    if let clockOutTime = entry.clockOutTime {
                        VStack(alignment: .leading, spacing: 2.0) {
                            Text("TimeClock.Work.ClockOut")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(clockOutTime, style: .time)
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                    }
                } else {
                    Text("Widget.NotClockedIn")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if entry.clockInTime != nil {
                VStack(alignment: .trailing, spacing: 6.0) {
                    Spacer()

                    if let clockOutTime = entry.clockOutTime,
                       let clockInTime = entry.clockInTime {
                        VStack(alignment: .trailing, spacing: 2.0) {
                            Text("Timesheet.TotalTimeWorked")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            let totalTime = clockOutTime.timeIntervalSince(clockInTime) - entry.totalBreakTime
                            Text(formatTimeInterval(totalTime))
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        if entry.totalBreakTime > 0 {
                            VStack(alignment: .trailing, spacing: 2.0) {
                                Text("Shared.Break")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                                Text(formatTimeInterval(entry.totalBreakTime))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.orange)
                            }
                        }
                    } else if entry.isActive, let clockInTime = entry.clockInTime {
                        if entry.isOnBreak {
                            VStack(alignment: .trailing, spacing: 2.0) {
                                Text("TimeClock.Break.OnBreak")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                    .fontWeight(.semibold)
                            }
                        } else {
                            let endWorkDate = clockInTime
                                .addingTimeInterval(entry.totalBreakTime)
                                .addingTimeInterval(entry.standardWorkingHours)

                            VStack(alignment: .trailing, spacing: 2.0) {
                                if Date.now >= endWorkDate {
                                    HStack(spacing: 3.0) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.caption2)
                                        Text("Shared.Overtime")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundStyle(.red)
                                } else {
                                    HStack(spacing: 3.0) {
                                        Image(systemName: "clock.badge.checkmark.fill")
                                            .font(.caption2)
                                        Text("Shared.Remaining")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }

                        VStack(alignment: .trailing, spacing: 2.0) {
                            Text(clockInTime, style: .relative)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(entry.isOnBreak ? .orange : .primary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    // MARK: - Helpers

    var statusIcon: String {
        if entry.clockInTime == nil {
            return "moon.zzz.fill"
        } else if entry.clockOutTime != nil {
            return "checkmark.circle.fill"
        } else if entry.isOnBreak {
            return "cup.and.heat.waves.fill"
        } else {
            return "clock.fill"
        }
    }

    var statusColor: Color {
        if entry.clockInTime == nil {
            return .secondary
        } else if entry.clockOutTime != nil {
            return .green
        } else if entry.isOnBreak {
            return .orange
        } else {
            return .blue
        }
    }

    var statusText: LocalizedStringKey {
        if entry.clockInTime == nil {
            return "Widget.Status.NotStarted"
        } else if entry.clockOutTime != nil {
            return "Widget.Status.Done"
        } else if entry.isOnBreak {
            return "TimeClock.Break.OnBreak"
        } else {
            return "TimeClock.Work.Working"
        }
    }

    func formatTimeInterval(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: max(0, interval)) ?? ""
    }
}
