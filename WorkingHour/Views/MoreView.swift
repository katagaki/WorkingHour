//
//  MoreView.swift
//  Working Hour
//
//  Created by シン・ジャスティン on 2024/10/12.
//

import Komponents
import SwiftUI

struct MoreView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            MoreList(repoName: "katagaki/WorkingHour") {
                Section {
                    
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("More")
                        .font(.title)
                        .fontWeight(.bold)
                }
                ToolbarItem(placement: .principal) {
                    Spacer()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton {
                        dismiss()
                    }
                }
            }
        }
    }
}
