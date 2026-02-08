//
//  SettingsView.swift
//  WorkingHour
//
//  Created by Assistant on 2026/02/07.
//

import Komponents
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss

    @Environment(\.modelContext) private var modelContext
    @State private var settingsManager = SettingsManager.shared
    // @State private var dataManager = DataManager.shared

    @State private var workingHours: Double = 8.0
    @State private var breakMinutes: Double = 60.0
    @State private var autoAddBreak: Bool = false

    var body: some View {
        NavigationStack {
            List {
                // Working Hours Section
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
                } header: {
                    ListSectionHeader(text: "Settings.Section.WorkingTime")
                } footer: {
                    Text("Settings.WorkingHours.Footer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Break Settings Section
                Section {
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
                    ListSectionHeader(text: "Settings.Section.Break")
                } footer: {
                    Text("Settings.AutoAddBreak.Footer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

            }
            .navigationTitle("Settings.Title")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .confirm) {
                        saveSettings()
                        dismiss()
                    }
                }
            }
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
}
