//
//  NotificationsSettingsView.swift
//  WorkingHour
//
//  Created by Assistant on 2026/02/21.
//

import SwiftUI

struct NotificationsSettingsView: View {

    @State private var settingsManager = SettingsManager.shared

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
    @State private var breakStartReminderEnabled: Bool = false
    @State private var breakEndReminderEnabled: Bool = false

    var body: some View {
        List {
            Section {
                Toggle("Settings.ClockInReminder", isOn: $clockInReminderEnabled)
                if clockInReminderEnabled {
                    DatePicker("Settings.ClockInReminder.Time",
                               selection: $clockInReminderTime,
                               displayedComponents: .hourAndMinute)
                }
            } header: {
                Text("Settings.Notifications.ClockIn")
            }

            Section {
                Toggle("Settings.ClockOutReminder", isOn: $clockOutReminderEnabled)
                if clockOutReminderEnabled {
                    DatePicker("Settings.ClockOutReminder.Time",
                               selection: $clockOutReminderTime,
                               displayedComponents: .hourAndMinute)
                }
            } header: {
                Text("Settings.Notifications.ClockOut")
            } footer: {
                Text("Settings.Notifications.Footer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Settings.BreakStartReminder", isOn: $breakStartReminderEnabled)
                Toggle("Settings.BreakEndReminder", isOn: $breakEndReminderEnabled)
            } header: {
                Text("Settings.Notifications.Breaks")
            } footer: {
                Text("Settings.Notifications.Breaks.Footer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings.Section.Notifications")
        .toolbarTitleDisplayMode(.inline)
        .task {
            loadSettings()
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
        .onChange(of: breakStartReminderEnabled) { _, _ in
            saveBreakReminderSettings()
        }
        .onChange(of: breakEndReminderEnabled) { _, _ in
            saveBreakReminderSettings()
        }
    }

    private func loadSettings() {
        clockInReminderEnabled = settingsManager.clockInReminderEnabled
        clockOutReminderEnabled = settingsManager.clockOutReminderEnabled
        clockInReminderTime = dateFromSecondsSinceMidnight(settingsManager.clockInReminderTime)
        clockOutReminderTime = dateFromSecondsSinceMidnight(settingsManager.clockOutReminderTime)
        breakStartReminderEnabled = settingsManager.breakStartReminderEnabled
        breakEndReminderEnabled = settingsManager.breakEndReminderEnabled
    }

    private func saveBreakReminderSettings() {
        settingsManager.breakStartReminderEnabled = breakStartReminderEnabled
        settingsManager.breakEndReminderEnabled = breakEndReminderEnabled
        Task {
            await NotificationManager.shared.refreshBreakReminders()
        }
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
                settingsManager.notificationsLastScheduledDate = Date()
            }
        } else {
            Task {
                await notificationManager.cancelClockOutReminder()
            }
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
