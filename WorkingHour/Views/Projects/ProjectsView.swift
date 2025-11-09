//
//  ProjectsView.swift
//  WorkingHour
//
//  Created by Copilot on 2025/11/09.
//

import Komponents
import SwiftData
import SwiftUI

struct ProjectsView: View {
    @Environment(\.modelContext) var modelContext: ModelContext
    
    @Query(sort: [SortDescriptor(\Project.createdAt, order: .reverse)]) var projects: [Project]
    
    @State var isAddingProject: Bool = false
    @State var newProjectName: String = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(projects) { project in
                    HStack {
                        Text(project.name)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button("Shared.Delete", systemImage: "xmark") {
                            modelContext.delete(project)
                            try? modelContext.save()
                        }
                        .tint(.red)
                    }
                }
            }
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Projects")
                        .font(.title)
                        .fontWeight(.bold)
                }
                ToolbarItem(placement: .principal) {
                    Spacer()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddingProject = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Add Project", isPresented: $isAddingProject) {
                TextField("Project Name", text: $newProjectName)
                Button("Cancel", role: .cancel) {
                    newProjectName = ""
                }
                Button("Add") {
                    addProject()
                }
            } message: {
                Text("Enter a name for your project")
            }
        }
    }
    
    func addProject() {
        guard !newProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let project = Project(name: newProjectName)
        modelContext.insert(project)
        try? modelContext.save()
        newProjectName = ""
    }
}
