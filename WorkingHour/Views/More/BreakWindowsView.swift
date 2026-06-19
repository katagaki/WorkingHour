//
//  BreakWindowsView.swift
//  WorkingHour
//
//  Created by Assistant on 2026/06/20.
//

import SwiftData
import SwiftUI

struct BreakWindowsView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \BreakWindow.startSeconds, order: .forward)
    private var breakWindows: [BreakWindow]

    @State private var showingDeleteAlert: Bool = false
    @State private var windowToDelete: BreakWindow?

    var body: some View {
        List {
            Section {
                ForEach(breakWindows) { window in
                    NavigationLink {
                        BreakWindowEditorView(breakWindow: window)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2.0) {
                                Text(timeRangeString(window))
                                    .fontWeight(.medium)
                                if !window.isEnabled {
                                    Text("BreakWindow.Disabled")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if window.isEnabled {
                                Image(systemName: "cup.and.saucer.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                            }
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            windowToDelete = window
                            showingDeleteAlert = true
                        } label: {
                            Label("Shared.Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            window.isEnabled.toggle()
                            try? modelContext.save()
                        } label: {
                            Label(
                                window.isEnabled ? "BreakWindow.Disable" : "BreakWindow.Enable",
                                systemImage: window.isEnabled ? "pause.circle" : "play.circle"
                            )
                        }
                        .tint(window.isEnabled ? .orange : .green)
                    }
                }

                NavigationLink {
                    BreakWindowEditorView()
                } label: {
                    Label("BreakWindow.Add", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("BreakWindow.Section.Windows")
            } footer: {
                Text("BreakWindow.Footer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("BreakWindow.Title")
        .toolbarTitleDisplayMode(.inline)
        .alert("BreakWindow.Delete.Title", isPresented: $showingDeleteAlert) {
            Button("Shared.Cancel", role: .cancel) {
                windowToDelete = nil
            }
            Button("Shared.Delete", role: .destructive) {
                if let windowToDelete {
                    modelContext.delete(windowToDelete)
                    try? modelContext.save()
                }
                windowToDelete = nil
            }
        } message: {
            Text("BreakWindow.Delete.Message")
        }
    }

    private func timeRangeString(_ window: BreakWindow) -> String {
        formatted(window.startSeconds) + " – " + formatted(window.endSeconds)
    }

    private func formatted(_ seconds: Int) -> String {
        var components = DateComponents()
        components.hour = seconds / 3600
        components.minute = (seconds % 3600) / 60
        let date = Calendar.current.date(from: components) ?? Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
