//
//  EntryEditor.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2024/10/16.
//

import Komponents
import SwiftData
import SwiftUI

struct EntryEditor: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @State var entry: ClockEntry

    @State var newClockInTime: Date
    @State var newClockOutTime: Date
    @State var showingTasksEditor: Bool = false
    let hasClockOutTime: Bool
    @State var showingAddBreakAlert: Bool = false
    @State var newBreakStart: Date = .now
    @State var newBreakEnd: Date = .now

    init(_ entry: ClockEntry) {
        self.entry = entry
        self.newClockInTime = entry.clockInTime ?? .distantPast
        self.newClockOutTime = entry.clockOutTime ?? .distantFuture
        self.hasClockOutTime = entry.clockOutTime != nil
    }

    var safeBreakTimeRange: ClosedRange<Date> {
        if newClockInTime <= newClockOutTime {
            return newClockInTime...newClockOutTime
        } else {
            return newClockOutTime...newClockInTime
        }
    }

    var sortedBreakTimes: [Break] {
        (entry.breakTimes ?? []).sorted { $0.start < $1.start }
    }

    @ViewBuilder
    var breakTimesView: some View {
        ForEach(sortedBreakTimes) { breakTime in
            breakTimelineRows(for: breakTime)
        }
    }

    @ViewBuilder
    func breakTimelineRows(for breakTime: Break) -> some View {
        TimelineRow(.breakStart, date: Binding(
            get: { breakTime.start },
            set: { newStart in
                withAnimation(.smooth(duration: 0.35)) {
                    breakTime.start = newStart
                    if let end = breakTime.end, end < newStart {
                        breakTime.end = newStart
                    }
                }
            }
        ), in: safeBreakTimeRange)

        if breakTime.end != nil {
            TimelineRow(.breakEnd, date: Binding(
                get: { breakTime.end ?? .now },
                set: { newEnd in
                    withAnimation(.smooth(duration: 0.35)) {
                        breakTime.end = newEnd
                    }
                }
            ), in: safeBreakTimeRange)
        } else {
            TimelineRow(.breakTime, date: .constant(.distantPast))
        }

        TimelineRow(.neutral, date: .constant(.distantPast))
    }

    var body: some View {
        NavigationStack {
            List {
                TimelineRow(.start, date: $newClockInTime, in: hasClockOutTime ? .distantPast...newClockOutTime : nil)
                if !sortedBreakTimes.isEmpty {
                    TimelineRow(.neutral, date: .constant(.distantPast))
                }
                breakTimesView
                if hasClockOutTime {
                    TimelineRow(.end, date: $newClockOutTime, in: newClockInTime...Date.distantFuture)
                }

                // Break Management Section
                Section {
                    Button {
                        newBreakStart = newClockInTime.addingTimeInterval(3600)
                        newBreakEnd = newBreakStart.addingTimeInterval(3600)
                        showingAddBreakAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.orange)
                            Text("EntryEditor.AddBreak")
                                .foregroundStyle(.primary)
                        }
                    }

                    if !sortedBreakTimes.isEmpty {
                        ForEach(Array(sortedBreakTimes.enumerated()), id: \.element.id) { index, breakTime in
                            HStack {
                                Image(systemName: "cup.and.heat.waves.fill")
                                    .foregroundStyle(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("EntryEditor.Break.Number \(index + 1)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    if let end = breakTime.end {
                                        Text("\(formatTime(breakTime.start)) - \(formatTime(end))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("EntryEditor.Break.Ongoing")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    withAnimation(.smooth(duration: 0.35)) {
                                        deleteBreak(breakTime)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } header: {
                    Text("EntryEditor.Section.Breaks")
                }

                // Tasks Section
                Section {
                    Button {
                        showingTasksEditor = true
                    } label: {
                        HStack {
                            Image(systemName: "checklist")
                                .foregroundStyle(.accent)
                            Text("EntryEditor.Tasks")
                                .foregroundStyle(.primary)
                            Spacer()
                            if !(entry.tasks ?? []).isEmpty {
                                Text("\((entry.tasks ?? []).count)")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(.quaternary)
                                    .clipShape(Capsule())
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("EntryEditor.Section.Tasks")
                }
            }
            .listStyle(.plain)
            .environment(\.defaultMinListRowHeight, 26.0)
            .navigationTitle("EntryEditor.Edit")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .confirm) {
                        entry.clockInTime = newClockInTime
                        if hasClockOutTime {
                            entry.clockOutTime = newClockOutTime
                        }
                        saveEntry()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingTasksEditor) {
                TasksEditorView(entry: entry)
            }
            .sheet(isPresented: $showingAddBreakAlert) {
                NavigationStack {
                    Form {
                        Section {
                            DatePicker(
                                "EntryEditor.Break.Start",
                                selection: $newBreakStart,
                                in: safeBreakTimeRange,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            DatePicker(
                                "EntryEditor.Break.End",
                                selection: $newBreakEnd,
                                in: safeBreakTimeRange,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                        } footer: {
                            Text("EntryEditor.AddBreak.Message")
                        }
                    }
                    .navigationTitle("EntryEditor.AddBreak.Title")
                    .toolbarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Shared.Cancel") {
                                showingAddBreakAlert = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Shared.Add") {
                                withAnimation(.smooth(duration: 0.35)) {
                                    if newBreakEnd > newBreakStart {
                                        let newBreak = Break(start: newBreakStart, end: newBreakEnd)
                                        newBreak.clockEntry = entry
                                        modelContext.insert(newBreak)
                                    }
                                }
                                showingAddBreakAlert = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
        .interactiveDismissDisabled(true)
        .presentationDetents([.medium, .large])
    }

    private func deleteBreak(_ breakTime: Break) {
        // If this was the ongoing break of an active work session, clear the flag
        // so the entry is no longer stuck in an "on break" state.
        if entry.clockOutTime == nil, breakTime.end == nil, entry.isOnBreak {
            entry.isOnBreak = false
        }

        // Sever the inverse relationship first so SwiftUI's next render no longer
        // sees this break in entry.breakTimes, avoiding stale bindings to a
        // deleted SwiftData object.
        if let index = entry.breakTimes?.firstIndex(where: { $0.id == breakTime.id }) {
            entry.breakTimes?.remove(at: index)
        }
        breakTime.clockEntry = nil
        modelContext.delete(breakTime)

        // Keep the live activity in sync when the session is still ongoing.
        if entry.clockOutTime == nil, let sessionData = entry.toWorkSessionData() {
            Task {
                await LiveActivities.updateActivity(with: sessionData)
            }
        }
    }

    private func saveEntry() {
        if entry.clockOutTime == nil, let sessionData = entry.toWorkSessionData() {
            Task {
                await LiveActivities.updateActivity(with: sessionData)
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
