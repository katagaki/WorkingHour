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
    @Query(filter: #Predicate<Project> { $0.isActive }, sort: [SortDescriptor(\.name)]) private var activeProjects: [Project]

    var entry: ClockEntry

    @State private var taskDescriptions: [String: String] = [:]
    @State private var othersDescription: String = ""

    private let othersKey = "others"

    var body: some View {
        NavigationStack {
            List {
                // Projects
                if !activeProjects.isEmpty {
                    Section {
                        ForEach(activeProjects) { project in
                            VStack(alignment: .leading, spacing: 8.0) {
                                Label(project.name, systemImage: "folder.fill")
                                    .font(.headline)
                                    .foregroundStyle(.accent)

                                TextField("Tasks.Description.Placeholder",
                                          text: binding(for: project.id),
                                          axis: .vertical)
                                    .lineLimit(3...6)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("Tasks.Section.Projects")
                    }
                }

                // Others
                Section {
                    VStack(alignment: .leading, spacing: 8.0) {
                        Label("Tasks.Others", systemImage: "ellipsis.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)

                        TextField("Tasks.Others.Placeholder",
                                  text: $othersDescription,
                                  axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Tasks.Section.Others")
                } footer: {
                    Text("Tasks.Others.Footer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Tasks.Title")
            .toolbarTitleDisplayMode(.inlineLarge)
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
