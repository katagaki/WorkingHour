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
                
                Section {
                    Button {
                        exportAllData()
                    } label: {
                        Label("Export All Data", systemImage: "square.and.arrow.up")
                    }
                    .tint(.primary)
                    
                    Button {
                        // Import functionality - would require file picker implementation
                    } label: {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                    }
                    .tint(.primary)
                    .disabled(true)
                } header: {
                    ListSectionHeader(text: "Data Management")
                } footer: {
                    Text("Export all your data for backup purposes. Import functionality coming soon.")
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
    
    func exportAllData() {
        // Create export folder if needed
        let documentsURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") ??
                           FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let exportsFolderURL = documentsURL.appendingPathComponent("Exports")
        
        if !directoryExistsAtPath(exportsFolderURL) {
            try? FileManager.default.createDirectory(at: exportsFolderURL, withIntermediateDirectories: true)
        }
        
        // Export all clock entries to JSON
        let fetchDescriptor = FetchDescriptor<ClockEntry>(sortBy: [SortDescriptor(\.clockInTime, order: .forward)])
        if let entries = try? modelContext.fetch(fetchDescriptor) {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd"
            let formattedDate = dateFormatter.string(from: .now)
            let filename = "\(formattedDate)-DataExport.json"
            let exportPath = exportsFolderURL.appendingPathComponent(filename)
            
            // Create export data structure
            let exportData: [[String: Any]] = entries.compactMap { entry in
                var data: [String: Any] = [:]
                data["id"] = entry.id
                if let clockInTime = entry.clockInTime {
                    data["clockInTime"] = ISO8601DateFormatter().string(from: clockInTime)
                }
                if let clockOutTime = entry.clockOutTime {
                    data["clockOutTime"] = ISO8601DateFormatter().string(from: clockOutTime)
                }
                data["isOnBreak"] = entry.isOnBreak
                data["projectTasks"] = entry.projectTasks
                
                let breaks: [[String: Any]] = entry.breakTimes.map { breakTime in
                    var breakData: [String: Any] = [:]
                    breakData["start"] = ISO8601DateFormatter().string(from: breakTime.start)
                    if let end = breakTime.end {
                        breakData["end"] = ISO8601DateFormatter().string(from: end)
                    }
                    return breakData
                }
                data["breakTimes"] = breaks
                
                return data
            }
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted) {
                try? jsonData.write(to: exportPath)
            }
        }
    }
    
    func directoryExistsAtPath(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = true
        let exists = FileManager.default.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}
