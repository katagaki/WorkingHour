//
//  EntryEditor.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2024/10/16.
//

import Komponents
import SwiftUI

struct EntryEditor: View {

    @Environment(\.dismiss) var dismiss

    @Bindable var entry: ClockEntry

    @State var newClockInTime: Date
    @State var newClockOutTime: Date
    @State var isTaskEditorOpen: Bool = false

    init(_ entry: ClockEntry) {
        self.entry = entry
        self.newClockInTime = entry.clockInTime ?? .distantPast
        self.newClockOutTime = entry.clockOutTime ?? .distantFuture
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        isTaskEditorOpen = true
                    } label: {
                        HStack {
                            Label("Report Tasks", systemImage: "list.clipboard")
                            Spacer()
                            if !entry.projectTasks.isEmpty {
                                Text("\(entry.projectTasks.count)")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.secondary.opacity(0.2))
                                    .clipShape(.capsule)
                            }
                        }
                    }
                    .tint(.primary)
                } header: {
                    ListSectionHeader(text: "Tasks")
                }
                
                Section {
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
                } header: {
                    ListSectionHeader(text: "Timeline")
                }
            }
            .listStyle(.plain)
            .environment(\.defaultMinListRowHeight, 26.0)
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: newClockInTime) { _, _ in
                entry.clockInTime = newClockInTime
            }
            .onChange(of: newClockOutTime) { _, _ in
                entry.clockOutTime = newClockOutTime
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isTaskEditorOpen) {
                TaskEditorView(entry: entry)
            }
        }
        .interactiveDismissDisabled(true)
        .presentationDetents([.medium, .large])
    }
}
