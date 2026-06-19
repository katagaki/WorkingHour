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

    @State var selectedMonth: Int
    @State var selectedYear: Int

    @State var entryBeingEdited: ClockEntry?
    @State var shareableFile: ShareableFile?

    @Namespace var namespace

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
            TimesheetList(
                month: selectedMonth,
                year: selectedYear,
                entryBeingEdited: $entryBeingEdited,
                namespace: namespace
            )
            .listStyle(.plain)
            .navigationTitle("ViewTitle.Timesheet")
            .toolbarTitleDisplayMode(.inlineLarge)
            .safeAreaInset(edge: .top, spacing: 0.0) {
                HStack(alignment: .center, spacing: 8.0) {
                    Picker("Shared.Month", selection: $selectedMonth) {
                        ForEach(
                            Array(selectableMonths.enumerated()),
                            id: \.offset
                        ) { index, month in
                            Text(month)
                                .tag(index + 1)
                        }
                    }
                    Picker("Shared.Year", selection: $selectedYear) {
                        ForEach(selectableYears, id: \.self) { year in
                            Text(String(year))
                                .tag(year)
                        }
                    }
                    Spacer()
                    Menu {
                        Section("Export.Section.Timesheet") {
                            Button("Excel", systemImage: "tablecells") {
                                share(.timesheetExcel)
                            }
                            Button("CSV", systemImage: "doc.text") {
                                share(.timesheetCSV)
                            }
                        }
                        Section("Export.Section.Overtime") {
                            Button("Excel", systemImage: "tablecells") {
                                share(.overtimeExcel)
                            }
                            Button("CSV", systemImage: "doc.text") {
                                share(.overtimeCSV)
                            }
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .padding(.horizontal, 20.0)
                .padding(.vertical, 8.0)
                .adaptiveGlass()
                .padding(.horizontal, 20.0)
                .sheet(item: $shareableFile) { file in
                    ShareSheet(activityItems: [file.url])
                }
            }
            .sheet(item: $entryBeingEdited) { entry in
                EntryEditor(entry)
                    .navigationTransition(.zoom(sourceID: entry.id, in: namespace))
            }
        }
    }

    private func share(_ format: TimesheetExportFormat) {
        let exporter = TimesheetExporter(modelContext: context, settingsManager: .shared)
        if let url = exporter.export(format, month: selectedMonth, year: selectedYear) {
            shareableFile = ShareableFile(url: url)
        }
    }
}

struct TimesheetList: View {
    @Environment(\.modelContext) var modelContext
    @Query var entries: [ClockEntry]
    @Binding var entryBeingEdited: ClockEntry?

    var namespace: Namespace.ID

    init(month: Int, year: Int, entryBeingEdited: Binding<ClockEntry?>, namespace: Namespace.ID) {
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

        let predicate = #Predicate<ClockEntry> { entry in
            if let clockInTime = entry.clockInTime {
                clockInTime >= startDate && clockInTime <= endDate
            } else {
                false
            }
        }

        _entries = Query(filter: predicate, sort: [SortDescriptor(\.clockInTime, order: .reverse)])

        self.namespace = namespace
    }

    var body: some View {
        if entries.isEmpty {
            ContentUnavailableView(
                LocalizedStringKey("Timesheet.NoEntries"),
                systemImage: "clock.badge.xmark",
                description: Text(LocalizedStringKey("Timesheet.NoEntriesMessage"))
            )
        } else {
            List(entries) { entry in
                Button {
                    entryBeingEdited = entry
                } label: {
                    EntryRow(entry: entry)
                        .matchedTransitionSource(id: entry.id, in: namespace)
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
