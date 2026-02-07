//
//  SettingsView.swift
//  WorkingHour
//
//  Created by Assistant on 2026/02/07.
//

import Komponents
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss

    @Environment(\.modelContext) private var modelContext
    @State private var settingsManager = SettingsManager.shared
    // @State private var dataManager = DataManager.shared

    @State private var workingHours: Double = 8.0
    @State private var breakMinutes: Double = 60.0
    @State private var autoAddBreak: Bool = false

    // Import/Export
    @State private var showingExportSheet: Bool = false
    @State private var showingImportPicker: Bool = false
    @State private var exportURL: URL?
    @State private var showingExportSuccess: Bool = false
    @State private var showingImportSuccess: Bool = false
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""

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

                // Data Management Section
                Section {
                    Button {
                        exportData()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .frame(width: 30)
                                .foregroundStyle(.accent)
                            Text("Settings.ExportData")
                                .foregroundStyle(.primary)
                        }
                    }
                    .tint(.primary)

                    Button {
                        showingImportPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .frame(width: 30)
                                .foregroundStyle(.accent)
                            Text("Settings.ImportData")
                                .foregroundStyle(.primary)
                        }
                    }
                    .tint(.primary)
                } header: {
                    ListSectionHeader(text: "Settings.Section.Data")
                } footer: {
                    Text("Settings.Data.Footer")
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
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .sheet(isPresented: $showingExportSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("Settings.ExportSuccess", isPresented: $showingExportSuccess) {
                Button("Shared.OK", role: .cancel) {}
            }
            .alert("Settings.ImportSuccess", isPresented: $showingImportSuccess) {
                Button("Shared.OK", role: .cancel) {}
            }
            .alert("Shared.Error", isPresented: $showingError) {
                Button("Shared.OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
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

    private func exportData() {
        do {
            // Fetch All Data
            let entriesDescriptor = FetchDescriptor<ClockEntry>(sortBy: [SortDescriptor(\.clockInTime, order: .reverse)])
            let allEntries = try modelContext.fetch(entriesDescriptor)

            let projectsDescriptor = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            let allProjects = try modelContext.fetch(projectsDescriptor)

            let exportData = ExportData(
                entries: allEntries.map { ExportClockEntry(from: $0) },
                projects: allProjects.map { ExportProject(from: $0) },
                settings: ExportSettings(from: SettingsManager.shared)
            )

            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(exportData)

            // Save to temp file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("WorkingHour-Export-\(dateString()).json")
            try jsonData.write(to: tempURL)

            self.exportURL = tempURL
            self.showingExportSheet = true
            self.showingExportSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            do {
                guard url.startAccessingSecurityScopedResource() else {
                    throw NSError(domain: "SettingsView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not access file"])
                }
                let data = try Data(contentsOf: url)
                url.stopAccessingSecurityScopedResource()

                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let importData = try decoder.decode(ExportData.self, from: data)

                // Import entries
                for entryData in importData.entries {
                    let entry = ClockEntry(entryData.clockInTime)
                    entry.clockOutTime = entryData.clockOutTime
                    entry.breakTimes = entryData.breakTimes.map {
                        Break(start: $0.start, end: $0.end ?? $0.start)
                    }
                    entry.isOnBreak = entryData.isOnBreak
                    entry.projectTasks = entryData.projectTasks
                    modelContext.insert(entry)
                }

                // Import projects
                for projectData in importData.projects {
                    let project = Project(name: projectData.name)
                    project.isActive = projectData.isActive
                    modelContext.insert(project)
                }

                // Import settings
                if let settingsData = importData.settings {
                    SettingsManager.shared.standardWorkingHours = settingsData.standardWorkingHours
                    SettingsManager.shared.defaultBreakDuration = settingsData.defaultBreakDuration
                    SettingsManager.shared.autoAddBreakTime = settingsData.autoAddBreakTime
                }

                loadSettings()
                showingImportSuccess = true
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: .now)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
