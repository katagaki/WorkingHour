//
//  ShareSheet.swift
//  WorkingHour
//
//  Created by Assistant on 2026/06/20.
//

import SwiftUI
import UIKit

/// A wrapper around an exported file URL so it can drive a `.sheet(item:)` presentation.
struct ShareableFile: Identifiable {
    let id = UUID()
    let url: URL
}

/// Presents the system share sheet (`UIActivityViewController`) so the user can send the
/// exported file wherever they like — Files, AirDrop, Mail, etc.
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
