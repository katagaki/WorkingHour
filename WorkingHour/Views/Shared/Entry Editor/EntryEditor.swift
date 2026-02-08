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

    @State var entry: ClockEntry

    @State var newClockInTime: Date
    @State var newClockOutTime: Date
    @State var showingTasksEditor: Bool = false
    @State var showingAddBreakAlert: Bool = false
    @State var newBreakStart: Date = .now
    @State var newBreakEnd: Date = .now

    init(_ entry: ClockEntry) {
        self.entry = entry
        self.newClockInTime = entry.clockInTime ?? .distantPast
        self.newClockOutTime = entry.clockOutTime ?? .distantFuture
    }

    var sortedBreakTimes: [Break] {
        entry.breakTimes.sorted { $0.start < $1.start }
    }

    @ViewBuilder
    var breakTimesView: some View {
        ForEach(sortedBreakTimes) { breakTime in
            if let index = entry.breakTimes.firstIndex(where: { $0.id == breakTime.id }) {
                breakTimelineRows(for: index)
            }
        }
    }

    @ViewBuilder
    func breakTimelineRows(for index: Int) -> some View {
        TimelineRow(.breakStart, date: Binding(
            get: { entry.breakTimes[index].start },
            set: { newStart in
                withAnimation(.smooth(duration: 0.35)) {
                    entry.breakTimes[index].start = newStart
                    if let end = entry.breakTimes[index].end, end < newStart {
                        entry.breakTimes[index].end = newStart
                    }
                }
            }
        ), in: newClockInTime...newClockOutTime)

        if let _ = entry.breakTimes[index].end {
            TimelineRow(.breakEnd, date: Binding(
                get: { entry.breakTimes[index].end ?? .now },
                set: { newEnd in
                    withAnimation(.smooth(duration: 0.35)) {
                        entry.breakTimes[index].end = newEnd
                    }
                }
            ), in: newClockInTime...newClockOutTime)
        } else {
            TimelineRow(.breakTime, date: .constant(.distantPast))
        }

        TimelineRow(.neutral, date: .constant(.distantPast))
    }

    var body: some View {
        NavigationStack {
            List {
                TimelineRow(.start, date: $newClockInTime)
                if !sortedBreakTimes.isEmpty {
                    TimelineRow(.neutral, date: .constant(.distantPast))
                }
                breakTimesView
                TimelineRow(.end, date: $newClockOutTime)

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
                                        if let originalIndex = entry.breakTimes.firstIndex(where: { $0.id == breakTime.id }) {
                                            entry.breakTimes.remove(at: originalIndex)
                                        }
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
                            if !entry.projectTasks.isEmpty {
                                Text("\(entry.projectTasks.count)")
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
                        entry.clockOutTime = newClockOutTime
                        saveEntry()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingTasksEditor) {
                TasksEditorView(entry: entry)
            }
            .alert("EntryEditor.AddBreak.Title", isPresented: $showingAddBreakAlert) {
                DatePicker("EntryEditor.Break.Start", selection: $newBreakStart, in: newClockInTime...newClockOutTime, displayedComponents: [.date, .hourAndMinute])
                DatePicker("EntryEditor.Break.End", selection: $newBreakEnd, in: newClockInTime...newClockOutTime, displayedComponents: [.date, .hourAndMinute])
                Button("Shared.Add") {
                    withAnimation(.smooth(duration: 0.35)) {
                        if newBreakEnd > newBreakStart {
                            entry.breakTimes.append(Break(start: newBreakStart, end: newBreakEnd))
                            entry.breakTimes.sort { $0.start < $1.start }
                        }
                    }
                }
                Button("Shared.Cancel", role: .cancel) {}
            } message: {
                Text("EntryEditor.AddBreak.Message")
            }
        }
        .interactiveDismissDisabled(true)
        .presentationDetents([.medium, .large])
    }

    private func saveEntry() {
        // dataManager.updateClockEntry(entry)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
