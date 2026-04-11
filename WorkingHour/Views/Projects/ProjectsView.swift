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
                        Button(project.name, systemImage: "folder.fill") {
                            projectBeingEdited = project
                        }
                        .tint(.primary)
                        .swipeActions(edge: .trailing) {
                            Button("Shared.Delete", systemImage: "trash", role: .destructive) {
                                withAnimation {
                                    modelContext.delete(project)
                                }
                            }
                            Button("Projects.Archive", systemImage: "archivebox") {
                                withAnimation {
                                    project.isActive = false
                                    // dataManager.updateProject(project)
                                }
                            }
                            .tint(.orange)
                        }
                    }
                } header: {
                    ListSectionHeader(text: "Projects.Section.Active")
                }

                // Archived Projects
                if !archivedProjects.isEmpty {
                    Section {
                        ForEach(archivedProjects) { project in
                            Button {
                                projectBeingEdited = project
                            } label: {
                                Label(project.name, systemImage: "folder.fill")
                            }
                            .tint(.primary)
                            .swipeActions(edge: .leading) {
                                Button("Projects.Restore", systemImage: "arrow.uturn.backward") {
                                    withAnimation {
                                        project.isActive = true
                                        // dataManager.updateProject(project)
                                    }
                                }
                                .tint(.accent)
                            }
                            .swipeActions(edge: .trailing) {
                                Button("Shared.Delete", systemImage: "trash", role: .destructive) {
                                    withAnimation {
                                        modelContext.delete(project)
                                    }
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
                    if #available(iOS 26, *) {
                        Button {
                            showingAddProject = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.glassProminent)
                    } else {
                        Button {
                            showingAddProject = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
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
