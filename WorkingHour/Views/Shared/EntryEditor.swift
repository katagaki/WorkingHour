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
                DatePicker(
                    "Clock In Time",
                    selection: $newClockInTime,
                    displayedComponents: [.date, .hourAndMinute]
                )
                DatePicker(
                    "Clock Out Time",
                    selection: $newClockOutTime,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }
            .listStyle(.insetGrouped)
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
        .presentationDetents([.fraction(0.3)])
    }
}
