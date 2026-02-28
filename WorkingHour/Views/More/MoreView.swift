//
//  MoreView.swift
//  Working Hour
//
//  Created by シン・ジャスティン on 2024/10/12.
//

import Komponents
import SwiftUI
import SwiftData
import xlsxwriter

struct MoreView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.openURL) var openURL
    @State var settingsManager = SettingsManager.shared
    @State var dataManager = DataManager.shared

    @State private var workingHours: Double = 8.0
    @State private var breakMinutes: Double = 60.0
    @State private var autoAddBreak: Bool = false

    var body: some View {
        NavigationStack {
            MoreList(repoName: "katagaki/WorkingHour") {
                // Timesheet Export Section
                Section {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ExportGridButton(
                            title: "Excel",
                            systemImage: "x.square.fill",
                            color: .green
                        ) {
                            exportTimesheetToExcel()
                        }
                        ExportGridButton(
                            title: "CSV",
                            systemImage: "tablecells",
                            color: .blue
                        ) {
                            exportTimesheetToCSV()
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Export.Section.Timesheet")
                }

                // Overtime Report Section
                Section {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ExportGridButton(
                            title: "Excel",
                            systemImage: "x.square.fill",
                            color: .green
                        ) {
                            exportOvertimeToExcel()
                        }
                        ExportGridButton(
                            title: "CSV",
                            systemImage: "tablecells",
                            color: .blue
                        ) {
                            exportOvertimeToCSV()
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Export.Section.Overtime")
                }

                // Workplaces Section
                Section {
                    NavigationLink("Workplace.Title") {
                        WorkplacesView()
                    }
                } header: {
                    Text("Settings.Section.Geofencing")
                } footer: {
                    Text("Settings.Geofencing.Footer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Notifications Section
                Section {
                    NavigationLink("Settings.Section.Notifications") {
                        NotificationsSettingsView()
                    }
                } header: {
                    Text("Settings.Section.Notifications")
                } footer: {
                    Text("Settings.Notifications.Footer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Working Hours & Break Settings Section
                Section {
                    VStack(alignment: .leading, spacing: 8.0) {
                        HStack {
                            Text("Settings.WorkingHours")
                            Spacer()
                            Text(String(format: "%.1f", workingHours) + " " + String(localized: "Settings.Hours"))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $workingHours, in: 1...12, step: 0.5)
                            .tint(.accent)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8.0) {
                        HStack {
                            Text("Settings.DefaultBreak")
                            Spacer()
                            Text(String(format: "%.0f", breakMinutes) + " " + String(localized: "Settings.Minutes"))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $breakMinutes, in: 0...120, step: 15)
                            .tint(.orange)
                    }
                    .padding(.vertical, 4)

                    Toggle("Settings.AutoAddBreak", isOn: $autoAddBreak)
                } header: {
                    Text("Settings.Section.WorkingTimeAndBreak")
                } footer: {
                    Text("Settings.WorkingHours.Footer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                #if DEBUG
                Section {
                    Button("Populate Sample Data") {
                        dataManager.populateSampleData()
                    }
                    Button("Clear All Data", role: .destructive) {
                        dataManager.clearAllData()
                    }
                } header: {
                    Text(verbatim: "Debug")
                }
                #endif

            }
            .navigationTitle("ViewTitle.More")
            .toolbarTitleDisplayMode(.inlineLarge)
            .task {
                loadSettings()
            }
            .onChange(of: workingHours) { _, _ in
                saveSettings()
            }
            .onChange(of: breakMinutes) { _, _ in
                saveSettings()
            }
            .onChange(of: autoAddBreak) { _, _ in
                saveSettings()
            }
        }
    }

    private func loadSettings() {
        workingHours = settingsManager.standardWorkingHours / 3600.0
        breakMinutes = settingsManager.defaultBreakDuration / 60.0
        autoAddBreak = settingsManager.autoAddBreakTime
    }

    private func saveSettings() {
        settingsManager.standardWorkingHours = workingHours * 3600
        settingsManager.defaultBreakDuration = breakMinutes * 60
        settingsManager.autoAddBreakTime = autoAddBreak
    }

    private func secondsSinceMidnight(from date: Date) -> Double {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return Double((components.hour ?? 0) * 3600 + (components.minute ?? 0) * 60)
    }

    private func dateFromSecondsSinceMidnight(_ seconds: Double) -> Date {
        let hour = Int(seconds) / 3600
        let minute = (Int(seconds) % 3600) / 60
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}
