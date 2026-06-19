//
//  BreakWindowEditorView.swift
//  WorkingHour
//
//  Created by Assistant on 2026/06/20.
//

import SwiftData
import SwiftUI

struct BreakWindowEditorView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var breakWindow: BreakWindow?

    @State private var startTime: Date = BreakWindowEditorView.defaultTime(hour: 12)
    @State private var endTime: Date = BreakWindowEditorView.defaultTime(hour: 13)
    @State private var isEnabled: Bool = true

    private var isEditing: Bool {
        breakWindow != nil
    }

    var body: some View {
        List {
            Section {
                DatePicker(
                    "BreakWindow.Start",
                    selection: $startTime,
                    displayedComponents: .hourAndMinute
                )
                DatePicker(
                    "BreakWindow.End",
                    selection: $endTime,
                    displayedComponents: .hourAndMinute
                )
            } header: {
                Text("BreakWindow.Section.TimeRange")
            } footer: {
                Text("BreakWindow.TimeRange.Footer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("BreakWindow.Enabled", isOn: $isEnabled)
            }
        }
        .navigationTitle(isEditing ? "BreakWindow.Edit" : "BreakWindow.Add")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Shared.Save") {
                    save()
                }
            }
        }
        .task {
            if let breakWindow {
                startTime = dateFrom(breakWindow.startSeconds)
                endTime = dateFrom(breakWindow.endSeconds)
                isEnabled = breakWindow.isEnabled
            }
        }
    }

    private func save() {
        let startSeconds = secondsSinceMidnight(startTime)
        let endSeconds = secondsSinceMidnight(endTime)

        if let breakWindow {
            breakWindow.startSeconds = startSeconds
            breakWindow.endSeconds = endSeconds
            breakWindow.isEnabled = isEnabled
        } else {
            let newWindow = BreakWindow(startSeconds: startSeconds, endSeconds: endSeconds)
            newWindow.isEnabled = isEnabled
            modelContext.insert(newWindow)
        }

        try? modelContext.save()
        dismiss()
    }

    private func secondsSinceMidnight(_ date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 3600 + (components.minute ?? 0) * 60
    }

    private func dateFrom(_ seconds: Int) -> Date {
        var components = DateComponents()
        components.hour = seconds / 3600
        components.minute = (seconds % 3600) / 60
        return Calendar.current.date(from: components) ?? Date()
    }

    private static func defaultTime(hour: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
}
