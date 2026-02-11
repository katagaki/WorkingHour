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
    @Query var projects: [Project]
    @State var settingsManager = SettingsManager.shared
    @State var dataManager = DataManager.shared

    @State private var workingHours: Double = 8.0
    @State private var breakMinutes: Double = 60.0
    @State private var autoAddBreak: Bool = false

    @State private var clockInReminderEnabled: Bool = false
    @State private var clockOutReminderEnabled: Bool = false
    @State private var clockInReminderTime: Date = {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var clockOutReminderTime: Date = {
        var components = DateComponents()
        components.hour = 17
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()

    #if DEBUG
    @State private var showingClearDataAlert = false
    #endif

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
                    ListSectionHeader(text: "Export.Section.Timesheet")
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
                    ListSectionHeader(text: "Export.Section.Overtime")
                }

                // Notifications Section
                Section {
                    Toggle("Settings.ClockInReminder", isOn: $clockInReminderEnabled)
                    if clockInReminderEnabled {
                        DatePicker("Settings.ClockInReminder.Time",
                                   selection: $clockInReminderTime,
                                   displayedComponents: .hourAndMinute)
                    }

                    Toggle("Settings.ClockOutReminder", isOn: $clockOutReminderEnabled)
                    if clockOutReminderEnabled {
                        DatePicker("Settings.ClockOutReminder.Time",
                                   selection: $clockOutReminderTime,
                                   displayedComponents: .hourAndMinute)
                    }
                } header: {
                    ListSectionHeader(text: "Settings.Section.Notifications")
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
                    ListSectionHeader(text: "Settings.Section.WorkingTimeAndBreak")
                } footer: {
                    Text("Settings.WorkingHours.Footer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                #if DEBUG
                // Debug Section
                Section {
                    Button("Debug.PopulateSampleData") {
                        dataManager.populateSampleData()
                    }

                    Button("Debug.ClearAllData", role: .destructive) {
                        showingClearDataAlert = true
                    }
                } header: {
                    ListSectionHeader(text: "Debug")
                } footer: {
                    Text("Debug.PopulateSampleData.Description")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
            .onChange(of: clockInReminderEnabled) { _, _ in
                saveNotificationSettings()
            }
            .onChange(of: clockOutReminderEnabled) { _, _ in
                saveNotificationSettings()
            }
            .onChange(of: clockInReminderTime) { _, _ in
                saveNotificationSettings()
            }
            .onChange(of: clockOutReminderTime) { _, _ in
                saveNotificationSettings()
            }
            #if DEBUG
            .alert("Debug.ClearAllData.Confirmation", isPresented: $showingClearDataAlert) {
                Button("Shared.Cancel", role: .cancel) { }
                Button("Shared.Clear", role: .destructive) {
                    dataManager.clearAllData()
                }
            } message: {
                Text("Debug.ClearAllData.Message")
            }
            #endif
        }
    }

    private func loadSettings() {
        workingHours = settingsManager.standardWorkingHours / 3600.0
        breakMinutes = settingsManager.defaultBreakDuration / 60.0
        autoAddBreak = settingsManager.autoAddBreakTime
        clockInReminderEnabled = settingsManager.clockInReminderEnabled
        clockOutReminderEnabled = settingsManager.clockOutReminderEnabled
        clockInReminderTime = dateFromSecondsSinceMidnight(settingsManager.clockInReminderTime)
        clockOutReminderTime = dateFromSecondsSinceMidnight(settingsManager.clockOutReminderTime)
    }

    private func saveSettings() {
        settingsManager.standardWorkingHours = workingHours * 3600
        settingsManager.defaultBreakDuration = breakMinutes * 60
        settingsManager.autoAddBreakTime = autoAddBreak
    }

    private func saveNotificationSettings() {
        settingsManager.clockInReminderEnabled = clockInReminderEnabled
        settingsManager.clockOutReminderEnabled = clockOutReminderEnabled
        settingsManager.clockInReminderTime = secondsSinceMidnight(from: clockInReminderTime)
        settingsManager.clockOutReminderTime = secondsSinceMidnight(from: clockOutReminderTime)

        let notificationManager = NotificationManager.shared

        if clockInReminderEnabled {
            let components = Calendar.current.dateComponents([.hour, .minute], from: clockInReminderTime)
            Task {
                await notificationManager.scheduleClockInReminders(at: components)
                settingsManager.notificationsLastScheduledDate = Date()
            }
        } else {
            Task {
                await notificationManager.cancelClockInReminders()
            }
        }

        if clockOutReminderEnabled {
            let components = Calendar.current.dateComponents([.hour, .minute], from: clockOutReminderTime)
            Task {
                await notificationManager.scheduleClockOutReminder(at: components)
            }
        } else {
            notificationManager.cancelClockOutReminder()
        }
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
