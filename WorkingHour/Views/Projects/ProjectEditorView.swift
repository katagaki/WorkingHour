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
