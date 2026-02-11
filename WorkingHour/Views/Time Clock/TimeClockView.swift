//
//  TimeClockView.swift
//  Working Hour
//
//  Created by シン・ジャスティン on 2024/11/04.
//

import SwiftData
import SwiftUI

struct TimeClockView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<ClockEntry> { $0.clockOutTime == nil },
        sort: \.clockInTime,
        order: .reverse
    )
    private var activeEntries: [ClockEntry]

    @Query(
        filter: #Predicate<ClockEntry> { $0.clockOutTime != nil },
        sort: \.clockInTime,
        order: .reverse
    )
    private var completedEntries: [ClockEntry]

    @State private var settingsManager = SettingsManager.shared

    var activeEntry: ClockEntry? {
        activeEntries.first
    }

    var lastCompletedEntry: ClockEntry? {
        completedEntries.first
    }

    @State var currentWorkingTime: TimeInterval = 0
    @State var timer: Timer?

    var standardWorkingHours: TimeInterval {
        settingsManager.standardWorkingHours
    }

    let cornerRadius = 32.0

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
                            } else if let lastEntry = lastCompletedEntry,
                                      let clockInTime = lastEntry.clockInTime {
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
                            if activeEntry != nil {
                                // Show active entry's clock out time (or "-" if still clocked in)
                                if let clockOutTime = activeEntry?.clockOutTime {
                                    Text(clockOutTime, style: .date)
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
                            } else if let lastEntry = lastCompletedEntry,
                                      let clockOutTime = lastEntry.clockOutTime {
                                // Show last completed entry's clock out time
                                Text(clockOutTime, style: .date)
                                    .foregroundStyle(.secondary)
                                    .fontWeight(.bold)
                                Text(clockOutTime, style: .time)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                            } else {
                                // No entries at all
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
                            Label("TimeClock.Work.ClockIn", systemImage: "figure.walk.arrival")
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
                .clipShape(.rect(cornerRadius: cornerRadius))

                // Working Hours with Overtime Info
                if let activeEntry, activeEntry.clockOutTime == nil,
                   let clockInTime = activeEntry.clockInTime {
                    VStack(alignment: .leading, spacing: 6.0) {
                        Text("TimeClock.Work.Title")
                            .foregroundStyle(.secondary)
                            .fontWeight(.bold)
                        Text(clockInTime, style: .relative)
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        // Overtime indicator
                        if currentWorkingTime > 0 {
                            if currentWorkingTime > standardWorkingHours {
                                HStack(spacing: 6.0) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.red)
                                    Text("TimeClock.Overtime")
                                        .fontWeight(.semibold)
                                    Text(formatTimeInterval(currentWorkingTime - standardWorkingHours))
                                }
                                .foregroundStyle(.red)
                                .font(.subheadline)
                                .padding(.top, 4.0)
                            } else {
                                let remaining = standardWorkingHours - currentWorkingTime
                                HStack(spacing: 6.0) {
                                    Image(systemName: "clock.badge.checkmark.fill")
                                    Text("TimeClock.Remaining")
                                        .fontWeight(.semibold)
                                    Text(formatTimeInterval(remaining))
                                }
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                                .padding(.top, 4.0)
                            }
                        }

                        Button {
                            clockOut()
                        } label: {
                            Label("TimeClock.Work.ClockOut", systemImage: "figure.walk.departure")
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
                    .clipShape(.rect(cornerRadius: cornerRadius))
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
                    .clipShape(.rect(cornerRadius: cornerRadius))
                }
            }
            .padding([.leading, .trailing], 18.0)
            .padding([.top, .bottom], 12.0)
            .navigationTitle("ViewTitle.TimeClock")
            .toolbarTitleDisplayMode(.inlineLarge)
            .task {
                setupView()
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
    }

    func setupView() {
        if activeEntry != nil {
            startTimer()
        }
    }

    func startTimer() {
        updateWorkingTime()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            updateWorkingTime()
        }
    }

    func updateWorkingTime() {
        guard let activeEntry, let clockInTime = activeEntry.clockInTime else {
            currentWorkingTime = 0
            return
        }
        let totalTime = Date.now.timeIntervalSince(clockInTime)
        let breakTime = activeEntry.breakTime()
        currentWorkingTime = totalTime - breakTime
    }

    func clockIn() {
        withAnimation(.smooth.speed(2.0)) {
            let newEntry = ClockEntry(.now)
            if settingsManager.autoAddBreakTime && settingsManager.defaultBreakDuration > 0 {
                let breakStart = Date.now
                let breakEnd = breakStart.addingTimeInterval(settingsManager.defaultBreakDuration)
                newEntry.breakTimes.append(Break(start: breakStart, end: breakEnd))
            }
            modelContext.insert(newEntry)
            startTimer()
            modelContext.processPendingChanges()
            if let sessionData = newEntry.toWorkSessionData() {
                Task {
                    await LiveActivities.startActivity(with: sessionData)
                }
            }
        }
    }

    func clockOut() {
        withAnimation(.smooth.speed(2.0)) {
            if let activeEntry,
               let sessionData = activeEntry.toWorkSessionData() {
                activeEntry.clockOutTime = .now
                modelContext.processPendingChanges()
                Task {
                    await LiveActivities.endActivity(with: sessionData, immediately: true)
                }
            }
            timer?.invalidate()
            timer = nil
        }
    }

    func startBreak() {
        withAnimation(.smooth.speed(2.0)) {
            activeEntry?.breakTimes.append(Break(start: .now))
            activeEntry?.isOnBreak = true
            modelContext.processPendingChanges()
            if let activeEntry,
               let sessionData = activeEntry.toWorkSessionData() {
                Task {
                    await LiveActivities.updateActivity(with: sessionData)
                }
            }
        }
    }

    func endBreak() {
        if let startTime = activeEntry?.breakTimes.last?.start,
           activeEntry?.breakTimes.last?.end == nil {
            withAnimation(.smooth.speed(2.0)) {
                activeEntry?.breakTimes.removeLast()
                activeEntry?.breakTimes.append(Break(start: startTime, end: .now))
                activeEntry?.isOnBreak = false
                modelContext.processPendingChanges()
                if let activeEntry,
                   let sessionData = activeEntry.toWorkSessionData() {
                    Task {
                        await LiveActivities.updateActivity(with: sessionData)
                    }
                }
            }
        }
    }

    func formatTimeInterval(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? ""
    }
}
