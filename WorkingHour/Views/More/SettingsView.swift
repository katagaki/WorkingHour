//
//  SettingsView.swift
//  WorkingHour
//
//  Created by Copilot on 2025/11/09.
//

import Komponents
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) var modelContext: ModelContext
    @Environment(\.dismiss) var dismiss
    
    @Query var settings: [AppSettings]
    
    @State var standardWorkingHours: Double = 8.0
    @State var defaultBreakMinutes: Double = 60.0
    @State var addBreakByDefault: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8.0) {
                        HStack {
                            Text("Standard Working Hours")
                            Spacer()
                            Text(String(format: "%.1f hours", standardWorkingHours))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $standardWorkingHours, in: 1...12, step: 0.5)
                    }
                    .padding(.vertical, 4)
                } header: {
                    ListSectionHeader(text: "Working Hours")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8.0) {
                        HStack {
                            Text("Default Break Time")
                            Spacer()
                            Text(String(format: "%.0f minutes", defaultBreakMinutes))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $defaultBreakMinutes, in: 0...120, step: 15)
                    }
                    .padding(.vertical, 4)
                    
                    Toggle("Add Break Time Automatically", isOn: $addBreakByDefault)
                } header: {
                    ListSectionHeader(text: "Break Time")
                } footer: {
                    Text("When enabled, the default break time will be automatically added to your clock entries")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveSettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .task {
                loadSettings()
            }
        }
    }
    
    func loadSettings() {
        if let currentSettings = settings.first {
            standardWorkingHours = currentSettings.standardWorkingTimeInSeconds / 3600.0
            defaultBreakMinutes = currentSettings.defaultBreakTimeInSeconds / 60.0
            addBreakByDefault = currentSettings.addBreakTimeByDefault
        }
    }
    
    func saveSettings() {
        let settingsToSave: AppSettings
        if let existingSettings = settings.first {
            settingsToSave = existingSettings
        } else {
            settingsToSave = AppSettings()
            modelContext.insert(settingsToSave)
        }
        
        settingsToSave.standardWorkingTimeInSeconds = standardWorkingHours * 3600.0
        settingsToSave.defaultBreakTimeInSeconds = defaultBreakMinutes * 60.0
        settingsToSave.addBreakTimeByDefault = addBreakByDefault
        
        try? modelContext.save()
    }
}
