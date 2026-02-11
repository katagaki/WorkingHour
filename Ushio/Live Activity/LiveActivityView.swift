//
//  LiveActivityView.swift
//  Ushio
//
//  Created by シン・ジャスティン on 2024/12/09.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct LiveActivityView: View {
    let context: ActivityViewContext<UshioAttributes>

    var body: some View {
        VStack(spacing: 6.0) {
            // Clock in/out times
            HStack(alignment: .center, spacing: 12.0) {
                VStack(alignment: .leading, spacing: 2.0) {
                    Text(context.state.clockInTime, style: .date)
                        .foregroundStyle(.secondary)
                        .font(.caption2)
                        .fontWeight(.bold)
                    Text(context.state.clockInTime, style: .time)
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)

                VStack(alignment: .trailing, spacing: 2.0) {
                    if let clockOutTime = context.state.clockOutTime {
                        Text(clockOutTime, style: .date)
                            .foregroundStyle(.secondary)
                            .font(.caption2)
                            .fontWeight(.bold)
                        Text(clockOutTime, style: .time)
                            .font(.title3)
                            .fontWeight(.bold)
                    } else {
                        Text("-")
                            .foregroundStyle(.secondary)
                            .font(.caption2)
                            .fontWeight(.bold)
                        Text("-")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Divider()

            // Working time or total time worked
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    if let clockOutTime = context.state.clockOutTime {
                        // Show total time worked when clocked out
                        Text("Timesheet.TotalTimeWorked")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            .fontWeight(.bold)

                        let totalTime = clockOutTime.timeIntervalSince(context.state.clockInTime) - context.state.totalBreakTime
                        Text(formatTimeInterval(totalTime))
                            .font(.title2)
                            .fontWeight(.bold)
                    } else {
                        HStack(spacing: 6) {
                            Text(context.state.isOnBreak ? "TimeClock.Break.OnBreak" : "TimeClock.Work.Working")
                                .foregroundStyle(context.state.isOnBreak ? .orange : .secondary)
                                .font(.caption)
                                .fontWeight(.bold)

                            // Show remaining/overtime beside the Working text
                            if !context.state.isOnBreak {
                                let endWorkDate = context.state.clockInTime
                                    .addingTimeInterval(context.state.totalBreakTime)
                                    .addingTimeInterval(context.state.standardWorkingHours)
                                if Date.now >= endWorkDate {
                                    HStack(spacing: 3) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.caption2)
                                        Text("Shared.Overtime")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                        Text(endWorkDate, style: .timer)
                                            .font(.caption2)
                                    }
                                    .foregroundStyle(.red)
                                } else {
                                    HStack(spacing: 3) {
                                        Image(systemName: "clock.badge.checkmark.fill")
                                            .font(.caption2)
                                        Text("Shared.Remaining")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                        Text(endWorkDate, style: .timer)
                                            .font(.caption2)
                                    }
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }

                        if context.state.isOnBreak, let breakStartTime = context.state.breakStartTime {
                            Text(breakStartTime, style: .relative)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.orange)
                        } else {
                            Text(context.state.clockInTime, style: .relative)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Action buttons (only show when not clocked out)
            if context.state.clockOutTime == nil {
                HStack(spacing: 8) {
                    if context.state.isOnBreak {
                        Button(intent: EndBreakIntent(entryId: context.attributes.entryId)) {
                            Label {
                                Text("TimeClock.Break.End")
                            } icon: {
                                Image(systemName: "arrowshape.turn.up.backward.badge.clock.fill")
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                        }
                        .tint(.red)
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button(intent: StartBreakIntent(entryId: context.attributes.entryId)) {
                            Label {
                                Text("Shared.Break")
                            } icon: {
                                Image(systemName: "cup.and.heat.waves.fill")
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                        }
                        .tint(.orange)
                        .buttonStyle(.borderedProminent)

                        Button(intent: ClockOutIntent(entryId: context.attributes.entryId)) {
                            Label {
                                Text("TimeClock.Work.ClockOut")
                            } icon: {
                                Image(systemName: "stop.fill")
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                        }
                        .tint(.red)
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .padding(16)
    }

    func formatTimeInterval(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? ""
    }
}
