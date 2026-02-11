//
//  ProjectEditorView.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2026/02/11.
//

import SwiftData
import SwiftUI

struct ProjectEditorView: View {
    @Environment(\.dismiss) var dismiss

    var project: Project
    @State private var editedName: String = ""
    @State private var isActive: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Projects.Name", text: $editedName)
                } header: {
                    Text("Projects.Name")
                }

                Section {
                    Toggle("Projects.Active", isOn: $isActive)
                }

                // Tasks linked to this project
                Section {
                    let tasks = (project.tasks ?? []).sorted {
                        ($0.clockEntry?.clockInTime ?? .distantPast) > ($1.clockEntry?.clockInTime ?? .distantPast)
                    }
                    if tasks.isEmpty {
                        Text("Projects.Tasks.Empty")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(tasks) { task in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.taskDescription)
                                    .font(.body)
                                if let clockInTime = task.clockEntry?.clockInTime {
                                    Text(clockInTime, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } header: {
                    Text("Projects.Tasks")
                }
            }
            .navigationTitle("Projects.Edit")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        project.name = editedName.trimmingCharacters(in: .whitespaces)
                        project.isActive = isActive
                        // dataManager.updateProject(project)
                        dismiss()
                    }
                    .disabled(editedName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                editedName = project.name
                isActive = project.isActive
            }
        }
    }
}
