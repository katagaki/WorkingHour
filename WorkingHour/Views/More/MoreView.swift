//
//  MoreView.swift
//  Working Hour
//
//  Created by シン・ジャスティン on 2024/10/12.
//

import Komponents
import SwiftUI
import SwiftData

struct MoreView: View {
    @Environment(\.modelContext) var modelContext
    @State var settingsManager = SettingsManager.shared
    @State var dataManager = DataManager.shared

    @Query private var breakWindows: [BreakWindow]

    @State private var workingHours: Double = 8.0
    @State private var breakMinutes: Double = 60.0
    @State private var autoAddBreak: Bool = false

    /// Auto-adding break time is only available when geofencing is enabled and
    /// at least one break time range is configured.
    private var canAutoAddBreak: Bool {
        settingsManager.geofencingEnabled && !breakWindows.isEmpty
    }

    var body: some View {
        NavigationStack {
            MoreList(repoName: "katagaki/WorkingHour") {
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
                        .disabled(!canAutoAddBreak)
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
                enforceAutoBreakGate()
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
            .onChange(of: canAutoAddBreak) { _, _ in
                enforceAutoBreakGate()
            }
        }
    }

    private func loadSettings() {
        workingHours = settingsManager.standardWorkingHours / 3600.0
        breakMinutes = settingsManager.defaultBreakDuration / 60.0
        autoAddBreak = settingsManager.autoAddBreakTime
    }

    /// Forces auto-add-break off (and persists it) whenever its prerequisites
    /// are not met, so it can't keep adding breaks while disabled.
    private func enforceAutoBreakGate() {
        guard !canAutoAddBreak else { return }
        if settingsManager.autoAddBreakTime {
            settingsManager.autoAddBreakTime = false
        }
        autoAddBreak = false
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
