//
//  TimeClockView.swift
//  Working Hour
//
//  Created by シン・ジャスティン on 2024/11/04.
//

import SwiftData
import SwiftUI

struct TimeClockView: View {

    @Environment(\.modelContext) var modelContext: ModelContext

    @Query(sort: [SortDescriptor(\ClockEntry.clockInTime, order: .reverse)]) var entries: [ClockEntry]
    @State var activeEntry: ClockEntry?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12.0) {
                // Working Time
                VStack(alignment: .center, spacing: 6.0) {
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

                    if activeEntry == nil || activeEntry?.clockOutTime != nil {
                        Button {
                            clockIn()
                        } label: {
                            Label("TimeClock.Work.ClockIn", systemImage: "ipad.and.arrow.forward")
                                .fontWeight(.semibold)
                                .padding([.top, .bottom], 6.0)
                                .frame(maxWidth: .infinity)
                        }
                        .clipShape(.capsule)
                        .buttonStyle(.borderedProminent)
                        .padding([.top], 2.0)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.groupedBackground)
                .clipShape(.rect(cornerRadius: 12.0))

                // Working Hours
                if let activeEntry, activeEntry.clockOutTime == nil,
                   let clockInTime = activeEntry.clockInTime {
                    VStack(alignment: .leading, spacing: 6.0) {
                        Text("TimeClock.Work.Title")
                            .foregroundStyle(.secondary)
                            .fontWeight(.bold)
                        Text(clockInTime, style: .relative)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Button {
                            clockOut()
                        } label: {
                            Label("TimeClock.Work.ClockOut", systemImage: "rectangle.portrait.and.arrow.right")
                                .fontWeight(.semibold)
                                .padding([.top, .bottom], 6.0)
                                .frame(maxWidth: .infinity)
                        }
                        .tint(.red)
                        .disabled(activeEntry.isOnBreak)
                        .clipShape(.capsule)
                        .buttonStyle(.borderedProminent)
                        .padding([.top], 2.0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.groupedBackground)
                    .clipShape(.rect(cornerRadius: 12.0))
                }

                // Break Time
                if let activeEntry, activeEntry.clockOutTime == nil {
                    VStack(alignment: .leading, spacing: 6.0) {
                        if let lastBreakTime = activeEntry.breakTimes.last {
                            Group {
                                Text("TimeClock.Break.Title")
                                    .fontWeight(.bold)
                                Group {
                                    if activeEntry.isOnBreak {
                                        Text(lastBreakTime.start, style: .relative)
                                    } else {
                                        Text(activeEntry.breakTimeString())
                                    }
                                }
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            }
                            .foregroundStyle(.orange)
                        }
                        Group {
                            if activeEntry.isOnBreak {
                                Button {
                                    endBreak()
                                } label: {
                                    Label("TimeClock.Break.End",
                                          systemImage: "arrowshape.turn.up.backward.badge.clock.fill")
                                    .fontWeight(.semibold)
                                    .padding([.top, .bottom], 6.0)
                                    .frame(maxWidth: .infinity)
                                }
                                .tint(.red)
                            } else {
                                Button {
                                    startBreak()
                                } label: {
                                    Label("TimeClock.Break.Start", systemImage: "cup.and.heat.waves.fill")
                                        .fontWeight(.semibold)
                                        .padding([.top, .bottom], 6.0)
                                        .frame(maxWidth: .infinity)
                                }
                                .tint(.orange)
                            }
                        }
                        .clipShape(.capsule)
                        .buttonStyle(.borderedProminent)
                        .padding([.top], 2.0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.groupedBackground)
                    .clipShape(.rect(cornerRadius: 12.0))
                }
            }
            .padding([.leading, .trailing], 18.0)
            .padding([.top, .bottom], 12.0)
            .navigationTitle("ViewTitle.TimeClock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("ViewTitle.TimeClock")
                        .font(.title)
                        .fontWeight(.bold)
                }
                ToolbarItem(placement: .principal) {
                    Spacer()
                }
            }
            .task {
                setupView()
            }
        }
    }

    func setupView() {
        if !entries.isEmpty, let firstEntry = entries.first, firstEntry.clockOutTime == nil {
            activeEntry = firstEntry
        }
    }

    func clockIn() {
        withAnimation(.smooth.speed(2.0)) {
            let newEntry = ClockEntry(.now)
            modelContext.insert(newEntry)
            activeEntry = newEntry
            try? modelContext.save()
        }
    }

    func clockOut() {
        withAnimation(.smooth.speed(2.0)) {
            activeEntry?.clockOutTime = .now
            try? modelContext.save()
        }
    }

    func startBreak() {
        withAnimation(.smooth.speed(2.0)) {
            activeEntry?.breakTimes.append(Break(start: .now))
            activeEntry?.isOnBreak = true
            try? modelContext.save()
        }
    }

    func endBreak() {
        if let startTime = activeEntry?.breakTimes.last?.start,
           activeEntry?.breakTimes.last?.end == nil {
            withAnimation(.smooth.speed(2.0)) {
                activeEntry?.breakTimes.removeLast()
                activeEntry?.breakTimes.append(Break(start: startTime, end: .now))
                activeEntry?.isOnBreak = false
                try? modelContext.save()
            }
        }
    }
}
