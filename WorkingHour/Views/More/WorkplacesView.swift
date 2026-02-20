//
//  WorkplacesView.swift
//  WorkingHour
//
//  Created by Assistant on 2026/02/20.
//

import CoreLocation
import SwiftData
import SwiftUI

struct WorkplacesView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Workplace.createdAt, order: .reverse)
    private var workplaces: [Workplace]

    @State private var geofencingManager = GeofencingManager.shared
    @State private var settingsManager = SettingsManager.shared

    @State private var geofencingEnabled: Bool = false
    @State private var autoClockInEnabled: Bool = true
    @State private var autoClockOutEnabled: Bool = true

    @State private var showingDeleteAlert: Bool = false
    @State private var workplaceToDelete: Workplace?

    var body: some View {
        List {
            // Geofencing toggle
            Section {
                Toggle("Workplace.Geofencing.Enable", isOn: $geofencingEnabled)

                if geofencingEnabled {
                    // Authorization status
                    if !geofencingManager.hasAlwaysAuthorization {
                        Button {
                            geofencingManager.requestAlwaysAuthorization()
                        } label: {
                            Label {
                                VStack(alignment: .leading, spacing: 2.0) {
                                    Text("Workplace.Location.Request")
                                        .foregroundStyle(.primary)
                                    Text("Workplace.Location.Request.Description")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "location.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                    } else {
                        Label {
                            Text("Workplace.Location.Authorized")
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Workplace.Section.Geofencing")
            } footer: {
                Text("Workplace.Geofencing.Footer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if geofencingEnabled {
                // Auto clock-in/out settings
                Section {
                    Toggle("Workplace.AutoClockIn", isOn: $autoClockInEnabled)
                    Toggle("Workplace.AutoClockOut", isOn: $autoClockOutEnabled)
                } header: {
                    Text("Workplace.Section.Automation")
                } footer: {
                    Text("Workplace.Automation.Footer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Workplace list
                Section {
                    ForEach(workplaces) { workplace in
                        NavigationLink {
                            WorkplaceEditorView(workplace: workplace)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2.0) {
                                    Text(workplace.name)
                                        .fontWeight(.medium)
                                    Text(String(format: "%.0f", workplace.radius) + " "
                                         + String(localized: "Workplace.Radius.Meters"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if workplace.isEnabled {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .foregroundStyle(.green)
                                        .font(.caption)
                                }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                workplaceToDelete = workplace
                                showingDeleteAlert = true
                            } label: {
                                Label("Shared.Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                workplace.isEnabled.toggle()
                                try? modelContext.save()
                                GeofencingManager.shared.startMonitoringWorkplaces()
                            } label: {
                                Label(
                                    workplace.isEnabled
                                        ? "Workplace.Disable"
                                        : "Workplace.Enable",
                                    systemImage: workplace.isEnabled
                                        ? "pause.circle"
                                        : "play.circle"
                                )
                            }
                            .tint(workplace.isEnabled ? .orange : .green)
                        }
                    }

                    NavigationLink {
                        WorkplaceEditorView()
                    } label: {
                        Label("Workplace.Add", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Workplace.Section.Workplaces")
                }
            }
        }
        .navigationTitle("Workplace.Title")
        .toolbarTitleDisplayMode(.inline)
        .task {
            geofencingEnabled = settingsManager.geofencingEnabled
            autoClockInEnabled = settingsManager.autoClockInEnabled
            autoClockOutEnabled = settingsManager.autoClockOutEnabled
        }
        .onChange(of: geofencingEnabled) { _, newValue in
            settingsManager.geofencingEnabled = newValue
            if newValue {
                if !geofencingManager.hasAlwaysAuthorization {
                    geofencingManager.requestAlwaysAuthorization()
                }
                geofencingManager.startMonitoringWorkplaces()
            } else {
                geofencingManager.stopMonitoringAllRegions()
            }
        }
        .onChange(of: autoClockInEnabled) { _, newValue in
            settingsManager.autoClockInEnabled = newValue
        }
        .onChange(of: autoClockOutEnabled) { _, newValue in
            settingsManager.autoClockOutEnabled = newValue
        }
        .alert("Workplace.Delete.Title", isPresented: $showingDeleteAlert) {
            Button("Shared.Cancel", role: .cancel) {
                workplaceToDelete = nil
            }
            Button("Shared.Delete", role: .destructive) {
                if let workplace = workplaceToDelete {
                    modelContext.delete(workplace)
                    try? modelContext.save()
                    GeofencingManager.shared.startMonitoringWorkplaces()
                }
                workplaceToDelete = nil
            }
        } message: {
            Text("Workplace.Delete.Message")
        }
    }
}
