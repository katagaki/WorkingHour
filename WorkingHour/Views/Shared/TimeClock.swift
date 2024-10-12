//
//  TimeClock.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2024/10/12.
//

import SwiftData
import SwiftUI

struct TimeClock: View {
    @Environment(\.modelContext) var modelContext: ModelContext
    @Binding var activeEntry: ClockEntry?

    var body: some View {
        VStack(alignment: .leading, spacing: 12.0) {
            HStack(alignment: .center) {
                Text("Working Hours")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                if let clockInTime = activeEntry?.clockInTime {
                    Text(clockInTime, style: .relative)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }
            Divider()
            HStack(alignment: .center, spacing: 12.0) {
                VStack(alignment: .leading, spacing: 4.0) {
                    if let clockInTime = activeEntry?.clockInTime {
                        Text(Date.now, style: .date)
                            .foregroundStyle(.secondary)
                            .fontWeight(.bold)
                        Text(clockInTime, style: .time)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    } else {
                        Text(Date.now, style: .date)
                            .foregroundStyle(.secondary)
                            .fontWeight(.bold)
                        Text(verbatim: "-")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "arrow.right")
                VStack(alignment: .trailing, spacing: 4.0) {
                    if let clockOutTime = activeEntry?.clockOutTime {
                        Text(Date.now, style: .date)
                            .foregroundStyle(.secondary)
                            .fontWeight(.bold)
                        Text(clockOutTime, style: .time)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    } else {
                        Text(verbatim: "-")
                            .foregroundStyle(.secondary)
                            .fontWeight(.bold)
                        Text(verbatim: "-")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxWidth: .infinity)
            HStack(alignment: .center, spacing: 12.0) {
                Group {
                    Button {
                        clockIn()
                    } label: {
                        Label("Clock In", systemImage: "ipad.and.arrow.forward")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(activeEntry != nil)
                    Button {
                        clockOut()
                    } label: {
                        Label("Clock Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(activeEntry == nil)
                }
                .clipShape(.capsule)
                .buttonStyle(.borderedProminent)
            }
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 4.0) {
                    Text("Break Time")
                        .foregroundStyle(.secondary)
                        .fontWeight(.bold)
                    if let lastBreakTime = activeEntry?.breakTimes.last,
                       activeEntry?.isOnBreak ?? false {
                        Text(lastBreakTime.start, style: .timer)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    } else {
                        Text(verbatim: "-")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: 12.0) {
                    Group {
                        Button {
                            startBreak()
                        } label: {
                            Label("Start Break", systemImage: "cup.and.heat.waves.fill")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(activeEntry == nil || (activeEntry?.isOnBreak ?? true))
                        Button {
                            endBreak()
                        } label: {
                            Label("End Break", systemImage: "arrowshape.turn.up.backward.badge.clock.fill")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(activeEntry == nil || !(activeEntry?.isOnBreak ?? true))
                    }
                    .clipShape(.capsule)
                    .buttonStyle(.borderedProminent)
                }
                .tint(.orange)
            }
        }
        .padding()
    }

    func clockIn() {
        let newEntry = ClockEntry(.now)
        modelContext.insert(newEntry)
        activeEntry = newEntry
    }

    func clockOut() {
        activeEntry?.clockOutTime = .now
        activeEntry = nil
    }

    func startBreak() {
        activeEntry?.breakTimes.append(Break(start: .now))
        activeEntry?.isOnBreak = true
    }

    func endBreak() {
        if let startTime = activeEntry?.breakTimes.last?.start,
           activeEntry?.breakTimes.last?.end == nil {
            activeEntry?.breakTimes.removeLast()
            activeEntry?.breakTimes.append(Break(start: startTime, end: .now))
            activeEntry?.isOnBreak = false
        }
    }
}
