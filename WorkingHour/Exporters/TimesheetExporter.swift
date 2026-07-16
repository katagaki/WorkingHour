//
//  TimesheetExporter.swift
//  WorkingHour
//
//  Created by Assistant on 2026/02/07.
//

import Foundation
import SwiftData
import SwiftUI
import xlsxwriter

let isCloudSyncEnabled = FileManager.default.url(forUbiquityContainerIdentifier: nil) != nil
let documentsURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") ??
FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
let exportsFolderURL = documentsURL.appendingPathComponent("Exports")

enum TimesheetExportFormat {
    case timesheetExcel
    case timesheetCSV
    case timesheetPDF
    case overtimeExcel
    case overtimeCSV
}

// MARK: - Timesheet & Overtime Exporter

@MainActor
struct TimesheetExporter {
    let modelContext: ModelContext
    let settingsManager: SettingsManager

    /// Rounding interval applied to punches in exports (0 = off).
    var roundingMinutes: Int {
        settingsManager.timeRoundingMinutes
    }

    /// Generates the requested export for the given month/year and returns the file URL, or `nil` on failure.
    func export(_ format: TimesheetExportFormat, month: Int, year: Int) -> URL? {
        switch format {
        case .timesheetExcel: exportTimesheetToExcel(month: month, year: year)
        case .timesheetCSV: exportTimesheetToCSV(month: month, year: year)
        case .timesheetPDF: exportTimesheetToPDF(month: month, year: year)
        case .overtimeExcel: exportOvertimeToExcel(month: month, year: year)
        case .overtimeCSV: exportOvertimeToCSV(month: month, year: year)
        }
    }

    func fetchEntries(month: Int, year: Int) -> [ClockEntry] {
        let calendar = Calendar.current

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0

        let startDate = calendar.date(from: components) ?? .distantPast
        let endDate = calendar.date(byAdding: .month, value: 1, to: startDate)?.addingTimeInterval(-1) ?? .distantFuture

        let descriptor = FetchDescriptor<ClockEntry>(
            predicate: #Predicate<ClockEntry> { entry in
                if let clockInTime = entry.clockInTime {
                    clockInTime >= startDate && clockInTime <= endDate
                } else {
                    false
                }
            },
            sortBy: [SortDescriptor(\.clockInTime)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching entries for export: \(error)")
            return []
        }
    }

    // MARK: - CSV

    func exportTimesheetToCSV(month: Int, year: Int) -> URL? {
        createIfNotExists(exportsFolderURL)
        let filename = exportFilename(prefix: "Timesheet", extension: "csv", month: month, year: year)
        let exportURL = exportsFolderURL.appendingPathComponent(filename)

        var csvContent = ""

        let headers = [
            String(localized: "Header.Date"),
            String(localized: "Header.Day"),
            String(localized: "Header.StartTime"),
            String(localized: "Header.EndTime"),
            String(localized: "Header.BreakTime"),
            String(localized: "Header.WorkingTime"),
            String(localized: "Header.Remarks")
        ]
        csvContent += headers.map { escapeCSV($0) }.joined(separator: ",") + "\n"

        let entries = fetchEntries(month: month, year: year)
        for entry in entries {
            if let clockInDate = entry.clockInDateString(),
               let clockInDay = entry.clockInDayString(),
               let clockInTime = entry.roundedClockInTime(minutes: roundingMinutes),
               let clockOutTime = entry.roundedClockOutTime(minutes: roundingMinutes) {
                let row = [
                    clockInDate,
                    clockInDay,
                    formatTime(clockInTime),
                    formatTime(clockOutTime),
                    formatTimeInterval(entry.roundedBreakTime(minutes: roundingMinutes)),
                    formatTimeInterval(entry.roundedTimeWorked(minutes: roundingMinutes) ?? .zero),
                    formatProjectTasks(entry.tasks ?? [])
                ]
                csvContent += row.map { escapeCSV($0) }.joined(separator: ",") + "\n"
            }
        }

        do {
            try csvContent.write(to: exportURL, atomically: true, encoding: .utf8)
            return exportURL
        } catch {
            print("Error exporting CSV: \(error)")
            return nil
        }
    }

    func exportOvertimeToCSV(month: Int, year: Int) -> URL? {
        createIfNotExists(exportsFolderURL)
        let filename = exportFilename(prefix: "OvertimeReport", extension: "csv", month: month, year: year)
        let exportURL = exportsFolderURL.appendingPathComponent(filename)

        var csvContent = ""

        let headers = [
            String(localized: "Header.Date"),
            String(localized: "Header.Day"),
            String(localized: "Header.WorkingTime"),
            String(localized: "Header.StandardHours"),
            String(localized: "Header.Overtime")
        ]
        csvContent += headers.map { escapeCSV($0) }.joined(separator: ",") + "\n"

        let standardHours = settingsManager.standardWorkingHours

        let entries = fetchEntries(month: month, year: year)
        for entry in entries {
            if let clockInDate = entry.clockInDateString(),
               let clockInDay = entry.clockInDayString(),
               let timeWorked = entry.roundedTimeWorked(minutes: roundingMinutes) {
                let overtime = entry.roundedOvertime(
                    standardWorkingTime: standardHours,
                    minutes: roundingMinutes
                ) ?? .zero

                let row = [
                    clockInDate,
                    clockInDay,
                    formatTimeInterval(timeWorked),
                    formatTimeInterval(standardHours),
                    formatTimeInterval(overtime)
                ]
                csvContent += row.map { escapeCSV($0) }.joined(separator: ",") + "\n"
            }
        }

        do {
            try csvContent.write(to: exportURL, atomically: true, encoding: .utf8)
            return exportURL
        } catch {
            print("Error exporting CSV: \(error)")
            return nil
        }
    }

    // MARK: - Helper Functions

    func exportFilename(prefix: String, extension ext: String, month: Int, year: Int) -> String {
        let yearMonth = String(format: "%04d%02d", year, month)
        return "\(yearMonth)-\(prefix).\(ext)"
    }

    func createIfNotExists(_ url: URL?) {
        if let url, !directoryExistsAtPath(url) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
        }
    }

    func directoryExistsAtPath(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = true
        let exists = FileManager.default.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    func escapeCSV(_ string: String) -> String {
        var result = string
        if result.contains("\"") || result.contains(",") || result.contains("\n") {
            result = result.replacingOccurrences(of: "\"", with: "\"\"")
            result = "\"\(result)\""
        }
        return result
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func formatTimeInterval(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .full
        return formatter.string(from: interval) ?? ""
    }

    func formatProjectTasks(_ tasks: [ProjectTask]) -> String {
        guard !tasks.isEmpty else { return "" }

        return tasks.map { task in
            let projectName = task.project?.name ?? String(localized: "Tasks.Others")
            return "\(projectName): \(task.taskDescription)"
        }.joined(separator: "; ")
    }
}
