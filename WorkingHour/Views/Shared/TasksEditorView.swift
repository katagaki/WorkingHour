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

    @State private var taskDescriptions: [String: String] = [:]
    @State private var othersDescription: String = ""

    private let othersKey = "others"

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
            get: { taskDescriptions[projectId] ?? "" },
            set: { taskDescriptions[projectId] = $0 }
        )
    }

    private func loadTasks() {
        taskDescriptions = entry.projectTasks.filter { $0.key != othersKey }
        othersDescription = entry.projectTasks[othersKey] ?? ""
    }

    private func saveTasks() {
        var allTasks: [String: String] = [:]

        // Add project tasks
        for (key, value) in taskDescriptions {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                allTasks[key] = trimmed
            }
        }

        // Add others
        let trimmedOthers = othersDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedOthers.isEmpty {
            allTasks[othersKey] = trimmedOthers
        }

        entry.projectTasks = allTasks
        // dataManager.updateClockEntry(entry)
    }
}
