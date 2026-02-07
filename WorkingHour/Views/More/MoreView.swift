//
//  MoreView.swift
//  Working Hour
//
//  Created by シン・ジャスティン on 2024/10/12.
//

import Komponents
import SwiftUI

struct MoreView: View {
    @State private var showingSettings: Bool = false
    @State private var showingProjects: Bool = false

    var body: some View {
        NavigationStack {
            MoreList(repoName: "katagaki/WorkingHour") {
                Section {
                    Button {
                        showingSettings = true
                    } label: {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .frame(width: 30)
                                .foregroundStyle(.accent)
                            Text("More.Settings")
                                .foregroundStyle(.primary)
                        }
                    }
                    .tint(.primary)

                    Button {
                        showingProjects = true
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill")
                                .frame(width: 30)
                                .foregroundStyle(.accent)
                            Text("More.Projects")
                                .foregroundStyle(.primary)
                        }
                    }
                    .tint(.primary)
                } header: {
                    ListSectionHeader(text: "More.Section.App")
                }
            }
            .navigationTitle("ViewTitle.More")
            .toolbarTitleDisplayMode(.inlineLarge)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingProjects) {
                ProjectsView()
            }
        }
    }
}
