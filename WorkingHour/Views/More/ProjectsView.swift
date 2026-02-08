//
//  ProjectsView.swift
//  WorkingHour
//
//  Created by Assistant on 2026/02/07.
//

import Komponents
import SwiftData
import SwiftUI

struct ProjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Project> { $0.isActive }, sort: [SortDescriptor(\.name)])
    private var activeProjects: [Project]
    @Query(filter: #Predicate<Project> { !$0.isActive }, sort: [SortDescriptor(\.name)])
    private var archivedProjects: [Project]

    @State private var showingAddProject: Bool = false
    @State private var newProjectName: String = ""
    @State private var projectBeingEdited: Project?

    var body: some View {
        NavigationStack {
            List {
                // Active Projects
                Section {
                    ForEach(activeProjects) { project in
                        Button {
                            projectBeingEdited = project
                        } label: {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(.accent)
                                Text(project.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                withAnimation {
                                    project.isActive = false
                                    // dataManager.updateProject(project)
                                }
                            } label: {
                                Label("Projects.Archive", systemImage: "archivebox")
                            }
                            .tint(.orange)

                            Button(role: .destructive) {
                                withAnimation {
                                    modelContext.delete(project)
                                }
                            } label: {
                                Label("Shared.Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    ListSectionHeader(text: "Projects.Section.Active")
                }

                // Archived Projects
                if !archivedProjects.isEmpty {
                    Section {
                        ForEach(archivedProjects) { project in
                            HStack {
                                Image(systemName: "folder")
                                    .foregroundStyle(.secondary)
                                Text(project.name)
                                    .foregroundStyle(.secondary)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    withAnimation {
                                        project.isActive = true
                                        // dataManager.updateProject(project)
                                    }
                                } label: {
                                    Label("Projects.Restore", systemImage: "arrow.uturn.backward")
                                }
                                .tint(.accent)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        modelContext.delete(project)
                                    }
                                } label: {
                                    Label("Shared.Delete", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        ListSectionHeader(text: "Projects.Section.Archived")
                    }
                }
            }
            .navigationTitle("Projects.Title")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddProject = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.glassProminent)
                }
            }
            .alert("Projects.Add", isPresented: $showingAddProject) {
                TextField("Projects.Name.Placeholder", text: $newProjectName)
                Button("Shared.Cancel", role: .cancel) {
                    newProjectName = ""
                }
                Button("Shared.Add") {
                    addProject()
                }
            } message: {
                Text("Projects.Add.Message")
            }
            .sheet(item: $projectBeingEdited) { project in
                ProjectEditorView(project: project)
            }
        }
    }

    private func addProject() {
        guard !newProjectName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let project = Project(name: newProjectName.trimmingCharacters(in: .whitespaces))
        modelContext.insert(project)
        newProjectName = ""
    }
}

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
