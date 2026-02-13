//
//  Widget.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2026/02/08.
//

import SwiftUI
import WidgetKit

struct UshioLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: UshioAttributes.self) { context in
            LiveActivityView(context: context)
                .activityBackgroundTint(Color.clear)
                .activitySystemActionForegroundColor(Color.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text("TimeClock.Work.ClockIn")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(context.state.clockInTime, style: .time)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .padding(.leading, 4.0)
                    .padding(.top, 2.0)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        if context.state.isOnBreak {
                            Text("Shared.Break")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                                .multilineTextAlignment(.trailing)
                            if let breakStartTime = context.state.breakStartTime {
                                Text(breakStartTime, style: .relative)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.orange)
                                    .multilineTextAlignment(.trailing)
                            }
                        } else {
                            Text("TimeClock.Work.Working")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                            Text(context.state.clockInTime, style: .relative)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 4.0)
                    .padding(.top, 2.0)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 8) {
                        if context.state.isOnBreak {
                            Button(intent: EndBreakIntent(entryId: context.attributes.entryId)) {
                                Label {
                                    Text("TimeClock.Break.End")
                                } icon: {
                                    Image(systemName: "arrowshape.turn.up.backward.badge.clock.fill")
                                }
                                .font(.body)
                                .fontWeight(.semibold)
                                .padding(.vertical, 4)
                                .frame(maxWidth: .infinity)
                            }
                            .tint(.red)
                            .buttonStyle(.bordered)
                        } else {
                            Button(intent: StartBreakIntent(entryId: context.attributes.entryId)) {
                                Label {
                                    Text("Shared.Break")
                                } icon: {
                                    Image(systemName: "cup.and.heat.waves.fill")
                                }
                                .font(.body)
                                .fontWeight(.semibold)
                                .padding(.vertical, 4)
                                .frame(maxWidth: .infinity)
                            }
                            .tint(.orange)
                            .buttonStyle(.bordered)

                            Button(intent: ClockOutIntent(entryId: context.attributes.entryId)) {
                                Label {
                                    Text("TimeClock.Work.ClockOut")
                                } icon: {
                                    Image(systemName: "stop.fill")
                                }
                                .font(.body)
                                .fontWeight(.semibold)
                                .padding(.vertical, 4)
                                .frame(maxWidth: .infinity)
                            }
                            .tint(.red)
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.top, 8)
                }
            } compactLeading: {
                if context.state.isOnBreak {
                    Image(systemName: "cup.and.heat.waves.fill")
                        .foregroundStyle(.orange)
                } else {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.blue)
                }
            } compactTrailing: {
                if context.state.isOnBreak {
                    let workingTime: TimeInterval = {
                        if let breakStartTime = context.state.breakStartTime {
                            return breakStartTime.timeIntervalSince(context.state.clockInTime)
                                - context.state.totalBreakTime
                        }
                        return 0
                    }()
                    ProgressView(
                        value: min(workingTime, context.state.standardWorkingHours),
                        total: context.state.standardWorkingHours
                    )
                    .progressViewStyle(.circular)
                    .tint(.orange)
                    .padding(.leading, 4.0)
                } else {
                    let adjustedStart = context.state.clockInTime
                        .addingTimeInterval(context.state.totalBreakTime)
                    let endDate = adjustedStart
                        .addingTimeInterval(context.state.standardWorkingHours)
                    ProgressView(
                        timerInterval: adjustedStart...endDate,
                        countsDown: false
                    ) {
                        EmptyView()
                    } currentValueLabel: {
                        EmptyView()
                    }
                    .progressViewStyle(.circular)
                    .tint(.blue)
                    .padding(.leading, 4.0)
                }
            } minimal: {
                Image(systemName: context.state.isOnBreak ? "cup.and.heat.waves.fill" : "clock.fill")
                    .foregroundStyle(context.state.isOnBreak ? .orange : .blue)
            }
            .keylineTint(context.state.isOnBreak ? .orange : .blue)
        }
    }
}
