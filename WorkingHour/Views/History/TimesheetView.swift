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

    @State private var modelContext: ModelContext?
    @Environment(\.modelContext) private var context

    @State var isMoreViewOpen: Bool = false
    @State var isExportViewOpen: Bool = false

    @State var isBrowsingPastEntries: Bool = false
    @State var selectedMonth: Int
    @State var selectedYear: Int

    @State var entryBeingEdited: ClockEntry?

    // var entries: [ClockEntry] {
    //     dataManager.entries(in: selectedMonth, year: selectedYear)
    // }

    var selectedDate: [Int] {
        [selectedMonth, selectedYear]
    }

    var selectableMonths: [String] {
        return Calendar.current.monthSymbols
    }

    var selectableYears: [Int] {
        let startYear = 2024
        let endYear = Calendar.current.component(.year, from: .now)
        return Array(startYear...endYear)
    }

    init() {
        _selectedMonth = State(initialValue: Calendar.current.component(.month, from: .now))
        _selectedYear = State(initialValue: Calendar.current.component(.year, from: .now))
    }

    var body: some View {
        NavigationStack {
            TimesheetList(month: selectedMonth, year: selectedYear, entryBeingEdited: $entryBeingEdited)
            .listStyle(.plain)
            .navigationTitle("ViewTitle.Timesheet")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Toggle(
                            "Browse Past Entries",
                            isOn: $isBrowsingPastEntries.animation(.smooth.speed(2.0))
                        )
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0.0) {
                if isBrowsingPastEntries {
                    HStack {
                        VStack(alignment: .leading, spacing: 10.0) {
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
                        .padding([.leading, .trailing], 20.0)
                        .padding([.top, .bottom], 8.0)
                    }
                }
            }
            .sheet(item: $entryBeingEdited) { entry in
                EntryEditor(entry, onSave: {
                    // Refresh handled by SwiftData
                })
            }
            .onChange(of: isBrowsingPastEntries) { oldValue, newValue in
                if oldValue && !newValue {
                    selectedMonth = Calendar.current.component(.month, from: .now)
                    selectedYear = Calendar.current.component(.year, from: .now)
                }
            }
        }
    }
}

struct TimesheetList: View {
    @Environment(\.modelContext) var modelContext
    @Query var entries: [ClockEntry]
    @Binding var entryBeingEdited: ClockEntry?

    init(month: Int, year: Int, entryBeingEdited: Binding<ClockEntry?>) {
        self._entryBeingEdited = entryBeingEdited

        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0

        let startDate = calendar.date(from: components) ?? .distantPast
        let endDate = calendar.date(byAdding: .month, value: 1, to: startDate)?.addingTimeInterval(-1) ?? .distantFuture

        // Predicate: clockInTime between start and end
        // CloudKit-compatible predicate without force unwrap
        let predicate = #Predicate<ClockEntry> { entry in
            if let clockInTime = entry.clockInTime {
                clockInTime >= startDate && clockInTime <= endDate
            } else {
                false
            }
        }

        _entries = Query(filter: predicate, sort: [SortDescriptor(\.clockInTime, order: .reverse)])
    }

    var body: some View {
        if entries.isEmpty {
            ContentUnavailableView(
                LocalizedStringKey("No Entries"),
                systemImage: "clock.badge.xmark",
                description: Text(LocalizedStringKey("No clock entries found for this period"))
            )
        } else {
            List(entries) { entry in
                Button {
                    entryBeingEdited = entry
                } label: {
                    EntryRow(entry: entry)
                }
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    if entry.clockOutTime != nil {
                        Button("Shared.Delete", systemImage: "xmark") {
                            modelContext.delete(entry)
                        }
                        .tint(.red)
                    }
                }
            }
        }
    }
}
