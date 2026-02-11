//
//  TasksEditorView.swift
//  WorkingHour
//
//  Created by Assistant on 2026/02/07.
//

import SwiftData
import SwiftUI

struct TasksEditorView: View {
    @Environment(\.dismiss) var dismiss

    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Project> { $0.isActive }, sort: [SortDescriptor(\.name)])
    private var activeProjects: [Project]

    var entry: ClockEntry

    // Tracks task description text per project ID
    @State private var projectDescriptions: [String: String] = [:]
    // Tracks task description for the "Others" category (no project)
    @State private var othersDescription: String = ""

    var body: some View {
        NavigationStack {
            List {
                // Projects
                if !activeProjects.isEmpty {
                    ForEach(activeProjects) { project in
                        Section {
                            TextField("Tasks.Description.Placeholder",
                                      text: binding(for: project.id),
                                      axis: .vertical)
                            .lineLimit(3...6)
                        } header: {
                            Label(project.name, systemImage: "folder.fill")
                                .font(.headline)
                                .foregroundStyle(.accent)
                        }
                    }
                }

                // Others
                Section {
                    TextField("Tasks.Others.Placeholder",
                              text: $othersDescription,
                              axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Label("Tasks.Others", systemImage: "ellipsis.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)
                } footer: {
                    Text("Tasks.Others.Footer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Tasks.Title")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        saveTasks()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadTasks()
            }
        }
    }

    private func binding(for projectId: String) -> Binding<String> {
        Binding(
            get: { projectDescriptions[projectId] ?? "" },
            set: { projectDescriptions[projectId] = $0 }
        )
    }

    private func loadTasks() {
        // Load existing tasks from the entry's relationship
        for task in entry.tasks ?? [] {
            if let project = task.project {
                projectDescriptions[project.id] = task.taskDescription
            } else {
                othersDescription = task.taskDescription
            }
        }
    }

    private func saveTasks() {
        // Build a lookup of existing tasks by project ID (nil key = "others")
        var existingByProjectId: [String?: ProjectTask] = [:]
        for task in entry.tasks ?? [] {
            existingByProjectId[task.project?.id] = task
        }

        // Update or create tasks for each project
        for (projectId, description) in projectDescriptions {
            let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                // Remove the task if description is now empty
                if let existing = existingByProjectId[projectId] {
                    modelContext.delete(existing)
                }
            } else if let existing = existingByProjectId[projectId] {
                // Update existing task
                existing.taskDescription = trimmed
            } else {
                // Create a new task linked to this entry and project
                let project = activeProjects.first { $0.id == projectId }
                let newTask = ProjectTask(taskDescription: trimmed, clockEntry: entry, project: project)
                modelContext.insert(newTask)
            }
        }

        // Handle "Others" (no project)
        let trimmedOthers = othersDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedOthers.isEmpty {
            if let existing = existingByProjectId[nil] {
                modelContext.delete(existing)
            }
        } else if let existing = existingByProjectId[nil] {
            existing.taskDescription = trimmedOthers
        } else {
            let newTask = ProjectTask(taskDescription: trimmedOthers, clockEntry: entry, project: nil)
            modelContext.insert(newTask)
        }
    }
}
