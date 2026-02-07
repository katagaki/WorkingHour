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

    // @State private var dataManager = DataManager.shared

    @State var entry: ClockEntry
    var onSave: (() -> Void)?

    @State var newClockInTime: Date
    @State var newClockOutTime: Date
    @State var showingTasksEditor: Bool = false

    init(_ entry: ClockEntry, onSave: (() -> Void)? = nil) {
        self.entry = entry
        self.onSave = onSave
        self.newClockInTime = entry.clockInTime ?? .distantPast
        self.newClockOutTime = entry.clockOutTime ?? .distantFuture
    }

    var body: some View {
        NavigationStack {
            List {
                TimelineRow(.start, date: $newClockInTime)
                if !entry.breakTimes.isEmpty {
                    TimelineRow(.neutral, date: .constant(.distantPast))
                }
                ForEach($entry.breakTimes, id: \.self) { $break in
                    TimelineRow(.breakStart, date: $break.start, in: newClockInTime...newClockOutTime)
                    if let breakEnd = Binding($break.end) {
                        TimelineRow(.breakEnd, date: breakEnd, in: newClockInTime...newClockOutTime)
                    } else {
                        TimelineRow(.breakTime, date: .constant(.distantPast))
                    }
                    TimelineRow(.neutral, date: .constant(.distantPast))
                }
                TimelineRow(.end, date: $newClockOutTime)

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
            .navigationTitle("Edit Entry")
            .toolbarTitleDisplayMode(.inline)
            .onChange(of: newClockInTime) { _, _ in
                entry.clockInTime = newClockInTime
                saveEntry()
            }
            .onChange(of: newClockOutTime) { _, _ in
                entry.clockOutTime = newClockOutTime
                saveEntry()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .confirm) {
                        saveEntry()
                        onSave?()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingTasksEditor) {
                TasksEditorView(entry: entry)
            }
        }
        .interactiveDismissDisabled(true)
        .presentationDetents([.medium, .large])
    }

    private func saveEntry() {
        // dataManager.updateClockEntry(entry)
    }
}
