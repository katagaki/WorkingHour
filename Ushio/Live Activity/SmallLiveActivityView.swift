//
//  SmallLiveActivityView.swift
//  Ushio
//
//  Created by シン・ジャスティン on 2026/07/02.
//

import ActivityKit
import SwiftUI
import WidgetKit

/// Compact presentation of the live activity for the small activity family,
/// shown in the Smart Stack on a paired Apple Watch. Follows the watchOS
/// guidance of staying glanceable with at most one control.
struct SmallLiveActivityView: View {
    let context: ActivityViewContext<UshioAttributes>

    /// The moment the current break exceeds the configured break duration,
    /// or `nil` when not on a break or no break duration is configured.
    private var breakEndDate: Date? {
        guard context.state.isOnBreak,
              context.state.defaultBreakDuration > 0,
              let breakStartTime = context.state.breakStartTime else {
            return nil
        }
        return breakStartTime.addingTimeInterval(context.state.defaultBreakDuration)
    }

    private var isExceedingBreak: Bool {
        guard let breakEndDate else { return false }
        return Date.now >= breakEndDate
    }

    /// The moment the standard working hours elapse, accounting for breaks.
    private var endWorkDate: Date {
        context.state.clockInTime
            .addingTimeInterval(context.state.totalBreakTime)
            .addingTimeInterval(context.state.standardWorkingHours)
    }

    private var statusTint: Color {
        guard context.state.isOnBreak else { return .blue }
        return isExceedingBreak ? .red : .orange
    }

    var body: some View {
        if let clockOutTime = context.state.clockOutTime {
            clockedOutContent(clockOutTime)
        } else {
            activeContent
        }
    }

    private var activeContent: some View {
        HStack(alignment: .center, spacing: 8.0) {
            VStack(alignment: .leading, spacing: 2.0) {
                HStack(spacing: 4.0) {
                    Image(systemName: context.state.isOnBreak ?
                          "cup.and.heat.waves.fill" : "clock.fill")
                    Text(context.state.isOnBreak ?
                         "TimeClock.Break.OnBreak" : "TimeClock.Work.Working")
                }
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(statusTint)

                if context.state.isOnBreak,
                   let breakStartTime = context.state.breakStartTime {
                    Text(breakStartTime, style: .relative)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(isExceedingBreak ? .red : .primary)
                } else {
                    Text(context.state.clockInTime, style: .relative)
                        .font(.title3)
                        .fontWeight(.bold)
                }

                detailRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if context.isStale {
                // The stale prompt does not fit the Smart Stack, so a
                // refresh indicator takes the control's place instead.
                Image(systemName: "exclamationmark.arrow.circlepath")
                    .font(.body)
                    .foregroundStyle(.blue)
            } else if context.state.isOnBreak {
                Button(intent: EndBreakIntent(entryId: context.attributes.entryId)) {
                    Image(systemName: "arrowshape.turn.up.backward.badge.clock.fill")
                        .font(.body)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .tint(.red)
            } else {
                Button(intent: StartBreakIntent(entryId: context.attributes.entryId)) {
                    Image(systemName: "cup.and.heat.waves.fill")
                        .font(.body)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .tint(.orange)
            }
        }
        .padding(8.0)
        .background {
            if context.state.isOnBreak {
                Color.orange.opacity(0.2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    /// Bottom line of the active layout: overtime warnings when a threshold
    /// has been crossed, the clock-in time otherwise.
    @ViewBuilder
    private var detailRow: some View {
        if context.state.isOnBreak {
            if isExceedingBreak, let breakEndDate {
                HStack(spacing: 3.0) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Shared.BreakOvertime")
                        .fontWeight(.semibold)
                    Text(breakEndDate, style: .timer)
                }
                .font(.caption2)
                .foregroundStyle(.red)
            } else {
                clockInRow
            }
        } else if Date.now >= endWorkDate {
            HStack(spacing: 3.0) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("Shared.Overtime")
                    .fontWeight(.semibold)
                Text(endWorkDate, style: .timer)
            }
            .font(.caption2)
            .foregroundStyle(.red)
        } else {
            HStack(spacing: 3.0) {
                Image(systemName: "clock.badge.checkmark.fill")
                Text("Shared.Remaining")
                    .fontWeight(.semibold)
                Text(endWorkDate, style: .timer)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    private var clockInRow: some View {
        HStack(spacing: 3.0) {
            Text("TimeClock.Work.ClockIn")
                .fontWeight(.semibold)
            Text(context.state.clockInTime, style: .time)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }

    private func clockedOutContent(_ clockOutTime: Date) -> some View {
        VStack(alignment: .leading, spacing: 2.0) {
            Text("Timesheet.TotalTimeWorked")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            let totalTime = clockOutTime.timeIntervalSince(
                context.state.clockInTime
            ) - context.state.totalBreakTime
            Text(formatTimeInterval(totalTime))
                .font(.title3)
                .fontWeight(.bold)

            HStack(spacing: 4.0) {
                Text(context.state.clockInTime, style: .time)
                Image(systemName: "arrow.right")
                Text(clockOutTime, style: .time)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8.0)
    }

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? ""
    }
}
