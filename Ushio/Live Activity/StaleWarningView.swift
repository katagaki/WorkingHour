//
//  StaleWarningView.swift
//  Ushio
//
//  Created by シン・ジャスティン on 2026/04/10.
//

import SwiftUI

/// Prompt shown in place of the live activity action buttons when the
/// activity has gone stale. ActivityKit caps the stale date at 8 hours,
/// so once it elapses we ask the user to open the app to refresh it or
/// end their session from the main UI.
struct StaleWarningView: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.arrow.circlepath")
                .font(.caption)
            Text("LiveActivity.Stale.Message")
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.blue)
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.15))
        )
    }
}
