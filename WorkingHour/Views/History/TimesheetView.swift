//
//  TimesheetView.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2024/10/09.
//

import Komponents
import SwiftData
import SwiftUI

struct TimesheetView: View {

    @Environment(\.modelContext) var modelContext: ModelContext

    @Query(sort: [SortDescriptor(\ClockEntry.clockInTime, order: .reverse)]) var entries: [ClockEntry]

    @State var isTimesheetMenuOpen: Bool = false
    @State var isMoreViewOpen: Bool = false
    @State var isExportViewOpen: Bool = false

    @State var isBrowsingPastEntries: Bool = false
    @State var selectedMonth: Int
    @State var selectedYear: Int

    @State var entryBeingEdited: ClockEntry?

    var selectableMonths: [String] {
        return Calendar.current.monthSymbols
    }

    var selectableYears: [Int] {
        let startYear = 2024
        let endYear = Calendar.current.component(.year, from: .now)
        return Array(startYear...endYear)
    }

    init() {
        selectedMonth = Calendar.current.component(.month, from: .now)
        selectedYear = Calendar.current.component(.year, from: .now)
    }

    var body: some View {
        NavigationStack {
            List(entries) { entry in
                EntryRow(entry: entry)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if entry.clockOutTime != nil {
                            Button("Shared.Delete", systemImage: "xmark") {
                                modelContext.delete(entry)
                            }
                            .tint(.red)
                            Button("Shared.Edit", systemImage: "pencil") {
                                entryBeingEdited = entry
                            }
                            .tint(.blue)
                        }
                    }
            }
            .listStyle(.plain)
            .defaultScrollAnchor(.bottom)
            .navigationTitle("ViewTitle.Timesheet")
            .toolbarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.smooth.speed(2.0)) {
                            isTimesheetMenuOpen.toggle()
                        }
                    } label: {
                        HStack(alignment: .center, spacing: 8.0) {
                            Text("ViewTitle.Timesheet")
                                .font(.title)
                                .fontWeight(.bold)
                                .tint(.primary)
                            Group {
                                if !isTimesheetMenuOpen {
                                    Image(systemName: "chevron.down.circle.fill")
                                        .symbolRenderingMode(.hierarchical)
                                } else {
                                    Image(systemName: "chevron.up.circle.fill")
                                        .symbolRenderingMode(.hierarchical)
                                }
                            }
                            .font(.system(size: 14.0))
                        }
                    }
                }
                ToolbarItem(placement: .principal) {
                    Spacer()
                }
            }
            .safeAreaInset(edge: .top, spacing: 0.0) {
                BarAccessory(placement: .top) {
                    HStack {
                        if isTimesheetMenuOpen {
                            VStack(alignment: .leading, spacing: 10.0) {
                                HStack(alignment: .center, spacing: 8.0) {
                                    Toggle(
                                        "Browse Past Entries",
                                        isOn: $isBrowsingPastEntries.animation(.smooth.speed(2.0))
                                    )
                                }
                                if isBrowsingPastEntries {
                                    HStack(alignment: .center, spacing: 8.0) {
                                        Text("Select Month")
                                        Spacer()
                                        HStack(alignment: .center, spacing: 8.0) {
                                            Group {
                                                Picker("Month", selection: $selectedMonth) {
                                                    ForEach(
                                                        Array(selectableMonths.enumerated()),
                                                        id: \.offset
                                                    ) { index, month in
                                                        Text(month)
                                                            .tag(index + 1)
                                                    }
                                                }
                                                Picker("Year", selection: $selectedYear) {
                                                    ForEach(selectableYears, id: \.self) { year in
                                                        Text(String(year))
                                                            .tag(year)
                                                    }
                                                }
                                            }
                                            .background(.inlinePicker)
                                            .clipShape(.rect(cornerRadius: 8.0))
                                        }
                                    }
                                }
                            }
                            .padding([.leading, .trailing], 20.0)
                            .padding([.top, .bottom], 8.0)
                        }
                    }
                }
            }
            .sheet(item: $entryBeingEdited) { entry in
                EntryEditor(entry)
            }
        }
    }
}
