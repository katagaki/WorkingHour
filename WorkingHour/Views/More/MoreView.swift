//
//  MoreView.swift
//  Working Hour
//
//  Created by シン・ジャスティン on 2024/10/12.
//

import Komponents
import SwiftUI

struct MoreView: View {
    @State var isSettingsViewOpen: Bool = false
    
    var body: some View {
        NavigationStack {
            MoreList(repoName: "katagaki/WorkingHour") {
                Section {
                    Button {
                        isSettingsViewOpen = true
                    } label: {
                        ListRow(image: "ListIcon.Settings", title: "Settings")
                    }
                    .tint(.primary)
                } header: {
                    ListSectionHeader(text: "App Settings")
                }
            }
            .navigationTitle("ViewTitle.More")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("ViewTitle.More")
                        .font(.title)
                        .fontWeight(.bold)
                }
                ToolbarItem(placement: .principal) {
                    Spacer()
                }
            }
            .sheet(isPresented: $isSettingsViewOpen) {
                SettingsView()
            }
        }
    }
}
