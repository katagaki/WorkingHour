//
//  UshioLiveActivity.swift
//  Ushio
//
//  Created by シン・ジャスティン on 2024/12/09.
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Activity Attributes

struct UshioAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Work session state
        var clockInTime: Date
        var isOnBreak: Bool
        var breakStartTime: Date?
        var totalBreakTime: TimeInterval
        var standardWorkingHours: TimeInterval
    }

    // Fixed properties
    var entryId: String
}

// MARK: - Work Session Data

// Simplified work session data that can be passed to the Live Activity
public struct WorkSessionData {
    let entryId: String
    let clockInTime: Date
    let isOnBreak: Bool
    let breakStartTime: Date?
    let totalBreakTime: TimeInterval
    let standardWorkingHours: TimeInterval
}

// MARK: - Live Activity Manager

@MainActor
public final class LiveActivityManager {
    public static let shared = LiveActivityManager()

    private var currentActivity: Activity<UshioAttributes>?

    private init() {}

    // Start a Live Activity for a work session
    public func startActivity(with data: WorkSessionData) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        let attributes = UshioAttributes(entryId: data.entryId)
        let contentState = UshioAttributes.ContentState(
            clockInTime: data.clockInTime,
            isOnBreak: data.isOnBreak,
            breakStartTime: data.breakStartTime,
            totalBreakTime: data.totalBreakTime,
            standardWorkingHours: data.standardWorkingHours
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil)
            )
            currentActivity = activity
        } catch {
            print("Error starting Live Activity: \(error)")
        }
    }

    // Update the Live Activity
    public func updateActivity(with data: WorkSessionData) {
        let contentState = UshioAttributes.ContentState(
            clockInTime: data.clockInTime,
            isOnBreak: data.isOnBreak,
            breakStartTime: data.breakStartTime,
            totalBreakTime: data.totalBreakTime,
            standardWorkingHours: data.standardWorkingHours
        )

        Task {
            await currentActivity?.update(
                .init(state: contentState, staleDate: nil)
            )
        }
    }

    // End the Live Activity
    public func endActivity(with data: WorkSessionData) {
        let contentState = UshioAttributes.ContentState(
            clockInTime: data.clockInTime,
            isOnBreak: false,
            breakStartTime: nil,
            totalBreakTime: data.totalBreakTime,
            standardWorkingHours: data.standardWorkingHours
        )

        Task {
            await currentActivity?.end(
                .init(state: contentState, staleDate: nil),
                dismissalPolicy: .default
            )
            currentActivity = nil
        }
    }

    // Check if there's an active Live Activity
    public var hasActiveActivity: Bool {
        currentActivity != nil
    }
}

struct UshioLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: UshioAttributes.self) { context in
            // Lock screen/banner UI goes here
            LiveActivityView(context: context)
                .activityBackgroundTint(Color.clear)
                .activitySystemActionForegroundColor(Color.primary)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text("Clock In")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(context.state.clockInTime, style: .time)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .padding()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        if context.state.isOnBreak {
                            Text("Break")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            if let breakStartTime = context.state.breakStartTime {
                                Text(breakStartTime, style: .relative)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.orange)
                            }
                        } else {
                            Text("Working")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(context.state.clockInTime, style: .relative)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 8) {
                        if context.state.isOnBreak {
                            Button(intent: EndBreakIntent(entryId: context.attributes.entryId)) {
                                Label("End Break", systemImage: "arrowshape.turn.up.backward.badge.clock.fill")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .tint(.red)
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button(intent: StartBreakIntent(entryId: context.attributes.entryId)) {
                                Label("Break", systemImage: "cup.and.heat.waves.fill")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .tint(.orange)
                            .buttonStyle(.borderedProminent)

                            Button(intent: ClockOutIntent(entryId: context.attributes.entryId)) {
                                Label("Clock Out", systemImage: "rectangle.portrait.and.arrow.right")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .tint(.red)
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.top, 8)
                }
            } compactLeading: {
                Image(systemName: "clock.fill")
                    .foregroundStyle(context.state.isOnBreak ? .orange : .blue)
            } compactTrailing: {
                Text(context.state.clockInTime, style: .relative)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(context.state.isOnBreak ? .orange : .primary)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: context.state.isOnBreak ? "cup.and.heat.waves.fill" : "clock.fill")
                    .foregroundStyle(context.state.isOnBreak ? .orange : .blue)
            }
            .keylineTint(context.state.isOnBreak ? .orange : .blue)
        }
    }
}

// Lock screen/banner view
struct LiveActivityView: View {
    let context: ActivityViewContext<UshioAttributes>

    var currentWorkingTime: TimeInterval {
        let totalTime = Date.now.timeIntervalSince(context.state.clockInTime)
        let breakTime = context.state.totalBreakTime
        if context.state.isOnBreak, let breakStartTime = context.state.breakStartTime {
            let currentBreakTime = Date.now.timeIntervalSince(breakStartTime)
            return totalTime - breakTime - currentBreakTime
        }
        return totalTime - breakTime
    }

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
                    Text("-")
                        .foregroundStyle(.secondary)
                        .font(.caption2)
                        .fontWeight(.bold)
                    Text("-")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Divider()

            // Working time
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(context.state.isOnBreak ? "On Break" : "Working")
                            .foregroundStyle(context.state.isOnBreak ? .orange : .secondary)
                            .font(.caption)
                            .fontWeight(.bold)
                        
                        // Show remaining/overtime beside the Working text
                        if !context.state.isOnBreak && currentWorkingTime > 0 {
                            if currentWorkingTime > context.state.standardWorkingHours {
                                HStack(spacing: 3) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption2)
                                    Text("Overtime")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                    Text(formatTimeInterval(currentWorkingTime - context.state.standardWorkingHours))
                                        .font(.caption2)
                                }
                                .foregroundStyle(.red)
                            } else {
                                let remaining = context.state.standardWorkingHours - currentWorkingTime
                                HStack(spacing: 3) {
                                    Image(systemName: "clock.badge.checkmark.fill")
                                        .font(.caption2)
                                    Text("Remaining")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                    Text(formatTimeInterval(remaining))
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
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Action buttons
            HStack(spacing: 8) {
                if context.state.isOnBreak {
                    Button(intent: EndBreakIntent(entryId: context.attributes.entryId)) {
                        Label("End Break", systemImage: "arrowshape.turn.up.backward.badge.clock.fill")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .tint(.red)
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(intent: StartBreakIntent(entryId: context.attributes.entryId)) {
                        Label("Break", systemImage: "cup.and.heat.waves.fill")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .tint(.orange)
                    .buttonStyle(.borderedProminent)

                    Button(intent: ClockOutIntent(entryId: context.attributes.entryId)) {
                        Label("Clock Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .tint(.red)
                    .buttonStyle(.borderedProminent)
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

extension UshioAttributes {
    fileprivate static var preview: UshioAttributes {
        UshioAttributes(entryId: "preview-id")
    }
}

extension UshioAttributes.ContentState {
    fileprivate static var working: UshioAttributes.ContentState {
        UshioAttributes.ContentState(
            clockInTime: Date.now.addingTimeInterval(-3600),
            isOnBreak: false,
            breakStartTime: nil,
            totalBreakTime: 0,
            standardWorkingHours: 28800
        )
     }

     fileprivate static var onBreak: UshioAttributes.ContentState {
         UshioAttributes.ContentState(
             clockInTime: Date.now.addingTimeInterval(-7200),
             isOnBreak: true,
             breakStartTime: Date.now.addingTimeInterval(-600),
             totalBreakTime: 0,
             standardWorkingHours: 28800
         )
     }
}

#Preview("Notification", as: .content, using: UshioAttributes.preview) {
   UshioLiveActivity()
} contentStates: {
    UshioAttributes.ContentState.working
    UshioAttributes.ContentState.onBreak
}
