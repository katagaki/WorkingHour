//
//  TaskEditorView.swift
//  WorkingHour
//
//  Created by Copilot on 2025/11/09.
//

import Komponents
import SwiftData
import SwiftUI

struct TaskEditorView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @Query(sort: [SortDescriptor(\Project.name)]) var projects: [Project]
    
    @Bindable var entry: ClockEntry
    
    @State var selectedProjectId: String = ""
    @State var taskDescription: String = ""
    
    var body: some View {
        NavigationStack {
            List {
                if projects.isEmpty {
                    Section {
                        VStack(alignment: .center, spacing: 8.0) {
                            Image(systemName: "folder.badge.plus")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("No projects available")
                                .foregroundStyle(.secondary)
                            Text("Create projects in the Projects tab first")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                } else {
                    Section {
                        ForEach(projects) { project in
                            VStack(alignment: .leading, spacing: 8.0) {
                                HStack {
                                    Text(project.name)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    if entry.projectTasks[project.id] != nil {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                }
                                
                                if let task = entry.projectTasks[project.id], !task.isEmpty {
                                    Text(task)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                
                                Button {
                                    selectedProjectId = project.id
                                    taskDescription = entry.projectTasks[project.id] ?? ""
                                } label: {
                                    Label(entry.projectTasks[project.id] == nil ? "Add Task" : "Edit Task",
                                          systemImage: entry.projectTasks[project.id] == nil ? "plus.circle" : "pencil")
                                    .font(.caption)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        ListSectionHeader(text: "Projects")
                    }
                }
            }
            .navigationTitle("Report Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton {
                        dismiss()
                    }
                }
            }
            .alert("Task for \(projectName(for: selectedProjectId))", isPresented: Binding(
                get: { !selectedProjectId.isEmpty },
                set: { if !$0 { selectedProjectId = "" } }
            )) {
                TextField("Task description", text: $taskDescription, axis: .vertical)
                    .lineLimit(3...5)
                Button("Cancel", role: .cancel) {
                    selectedProjectId = ""
                    taskDescription = ""
                }
                Button("Remove", role: .destructive) {
                    entry.projectTasks.removeValue(forKey: selectedProjectId)
                    selectedProjectId = ""
                    taskDescription = ""
                }
                .disabled(entry.projectTasks[selectedProjectId] == nil)
                Button("Save") {
                    if !taskDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        entry.projectTasks[selectedProjectId] = taskDescription
                    }
                    selectedProjectId = ""
                    taskDescription = ""
                }
            } message: {
                Text("Enter the tasks you completed for this project")
            }
        }
    }
    
    func projectName(for id: String) -> String {
        projects.first(where: { $0.id == id })?.name ?? "Project"
    }
}
