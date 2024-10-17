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

    @State var entry: ClockEntry

    @State var newClockInTime: Date
    @State var newClockOutTime: Date

    init(_ entry: ClockEntry) {
        self.entry = entry
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
                }
                if !entry.breakTimes.isEmpty {
                    TimelineRow(.neutral, date: .constant(.distantPast))
                }
                TimelineRow(.end, date: $newClockOutTime)
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
        }
        .interactiveDismissDisabled(true)
        .presentationDetents([.medium, .large])
    }
}
