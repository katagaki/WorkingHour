//
//  KatsuView.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2024/10/09.
//

import Komponents
import SwiftData
import SwiftUI

struct KatsuView: View {

    @Environment(\.modelContext) var modelContext: ModelContext

    @Query(sort: [SortDescriptor(\ClockEntry.clockInTime, order: .reverse)]) var entries: [ClockEntry]
    @State var activeEntry: ClockEntry?

    @AppStorage(wrappedValue: "", "Global.CurrentClockEntry") var currentClockEntry: String
    @AppStorage(wrappedValue: TimeInterval.zero, "Global.WorkingHours") var workingHours: TimeInterval

    var body: some View {
        NavigationStack {
            List(entries) { entry in
                EntryRow(entry: entry)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button("Delete", systemImage: "xmark") {
                            modelContext.delete(entry)
                        }
                        .tint(.red)
                        Button("Edit", systemImage: "xmark") {
                            // TODO: Open editor
                        }
                    }
            }
            .listStyle(.plain)
            .defaultScrollAnchor(.bottom)
            .navigationTitle("Timesheet")
            .toolbarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Timesheet")
                        .font(.title)
                        .fontWeight(.bold)
                }
                ToolbarItem(placement: .principal) {
                    Spacer()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("More", systemImage: "ellipsis.circle") {
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0.0) {
                BarAccessory(placement: .bottom) {
                    TimeClock(activeEntry: $activeEntry)
                }
            }
            .navigationTitle("Working Hour")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if !entries.isEmpty, let firstEntry = entries.first, firstEntry.clockOutTime == nil {
                    activeEntry = firstEntry
                }
            }
        }
    }
}
