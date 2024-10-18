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
            // Title Bar
            HStack(alignment: .center) {
                Group {
                    Text("Working Hours")
                    if activeEntry?.clockOutTime == nil, let clockInTime = activeEntry?.clockInTime {
                        Text(clockInTime, style: .relative)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .font(.body)
                .fontWeight(.bold)
            }
            Divider()

            // Working Time
            HStack(alignment: .center, spacing: 12.0) {
                VStack(alignment: .leading, spacing: 4.0) {
                    if let clockInTime = activeEntry?.clockInTime {
                        Text(clockInTime, style: .date)
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

            // Clock In/Out Buttons
            Group {
                if let activeEntry, activeEntry.clockOutTime == nil {
                    Button {
                        clockOut()
                    } label: {
                        Label("Clock Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .fontWeight(.semibold)
                            .padding([.top, .bottom], 6.0)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(activeEntry.isOnBreak)
                } else {
                    Button {
                        clockIn()
                    } label: {
                        Label("Clock In", systemImage: "ipad.and.arrow.forward")
                            .fontWeight(.semibold)
                            .padding([.top, .bottom], 6.0)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .clipShape(.capsule)
            .buttonStyle(.borderedProminent)

            if let activeEntry, activeEntry.clockOutTime == nil {
                // Break Time
                if activeEntry.isOnBreak,
                   let lastBreakTime = activeEntry.breakTimes.last {
                    VStack(alignment: .leading, spacing: 4.0) {
                        Text("Break Time")
                            .foregroundStyle(.secondary)
                            .fontWeight(.bold)
                        Text(lastBreakTime.start, style: .timer)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.top], 2.0)
                }

                // Start/End Break Buttons
                HStack(alignment: .center, spacing: 12.0) {
                    Group {
                        if !activeEntry.isOnBreak {
                            Button {
                                startBreak()
                            } label: {
                                Label("Start Break", systemImage: "cup.and.heat.waves.fill")
                                    .fontWeight(.semibold)
                                    .padding([.top, .bottom], 6.0)
                                    .frame(maxWidth: .infinity)
                            }
                        } else {
                            Button {
                                endBreak()
                            } label: {
                                Label("End Break", systemImage: "arrowshape.turn.up.backward.badge.clock.fill")
                                    .fontWeight(.semibold)
                                    .padding([.top, .bottom], 6.0)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .clipShape(.capsule)
                    .buttonStyle(.borderedProminent)
                }
                .tint(.pink)
            }
        }
        .padding([.leading, .trailing], 18.0)
        .padding([.top, .bottom], 12.0)
    }

    func clockIn() {
        withAnimation(.smooth.speed(2.0)) {
            let newEntry = ClockEntry(.now)
            modelContext.insert(newEntry)
            activeEntry = newEntry
        }
    }

    func clockOut() {
        withAnimation(.smooth.speed(2.0)) {
            activeEntry?.clockOutTime = .now
        }
    }

    func startBreak() {
        withAnimation(.smooth.speed(2.0)) {
            activeEntry?.breakTimes.append(Break(start: .now))
            activeEntry?.isOnBreak = true
        }
    }

    func endBreak() {
        if let startTime = activeEntry?.breakTimes.last?.start,
           activeEntry?.breakTimes.last?.end == nil {
            withAnimation(.smooth.speed(2.0)) {
                activeEntry?.breakTimes.removeLast()
                activeEntry?.breakTimes.append(Break(start: startTime, end: .now))
                activeEntry?.isOnBreak = false
            }
        }
    }
}
