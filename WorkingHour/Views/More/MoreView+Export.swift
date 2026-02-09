//
//  MoreView+Export.swift
//  Working Hour
//
//  Created by Assistant on 2026/02/07.
//

import Foundation
import SwiftUI
import SwiftData
import xlsxwriter

let isCloudSyncEnabled = FileManager.default.url(forUbiquityContainerIdentifier: nil) != nil
let documentsURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") ??
FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
let exportsFolderURL = documentsURL.appendingPathComponent("Exports")

// MARK: - Export Helper Functions
extension MoreView {
    func fetchCurrentMonthEntries() -> [ClockEntry] {
        let dateNow = Date.now
        let calendar = Calendar.current
        let month = calendar.component(.month, from: dateNow)
        let year = calendar.component(.year, from: dateNow)

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

    func exportTimesheetToExcel() {
        createIfNotExists(exportsFolderURL)
        let filename = exportFilename(prefix: "Timesheet", extension: "xlsx")
        let exportPath = exportsFolderURL
            .appendingPathComponent(filename)
            .path(percentEncoded: false)
        let workbook = Workbook(name: exportPath)
        let worksheet = workbook.addWorksheet(name: "Timesheet")
        worksheet.gridline(screen: false)
        writeTimesheetHeaders(to: worksheet, in: workbook)
        let entries = fetchCurrentMonthEntries()
        let lastRowWritten = writeTimesheetRows(entries, to: worksheet, in: workbook)
        writeTimesheetFooter(entries, at: lastRowWritten, to: worksheet, in: workbook)
        workbook.close()
        openURL(URL(string: "shareddocuments://\(exportPath)")!)
    }

    func writeTimesheetHeaders(to worksheet: Worksheet, in workbook: Workbook) {
        let headerFormat = workbook.addFormat()
        headerFormat.background(color: Color(hex: 0x004561))
        headerFormat.font(color: .white)
        headerFormat.font(name: "Arial")
        headerFormat.bold()
        headerFormat.border(style: .thin)

        worksheet.write(.string(String(localized: "Header.Date")), [0, 0], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.Day")), [0, 1], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.StartTime")), [0, 2], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.EndTime")), [0, 3], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.BreakTime")), [0, 4], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.WorkingTime")), [0, 5], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.Remarks")), [0, 6], format: headerFormat)

        worksheet.column([0, 0], width: 15.0)
        worksheet.column([2, 5], width: 15.0)
        worksheet.column([6, 6], width: 30.0)
    }

    func writeTimesheetRows(_ entries: [ClockEntry], to worksheet: Worksheet, in workbook: Workbook) -> Int {
        let rowHeaderFormat = workbook.addFormat()
        rowHeaderFormat.background(color: Color(hex: 0xF2F2F7))
        rowHeaderFormat.font(color: .black)
        rowHeaderFormat.font(name: "Arial")
        rowHeaderFormat.border(style: .thin)

        let rowFormat = workbook.addFormat()
        rowFormat.background(color: .white)
        rowFormat.font(color: .black)
        rowFormat.font(name: "Arial")
        rowFormat.border(style: .thin)

        var currentRow: Int = 1
        for entry in entries {
            if let clockInDate = entry.clockInDateString(),
               let clockInDay = entry.clockInDayString(),
               let clockInTime = entry.clockInTimeString(),
               let clockOutTime = entry.clockOutTimeString() {
                worksheet.write(.string(clockInDate), [currentRow, 0], format: rowHeaderFormat)
                worksheet.write(.string(clockInDay), [currentRow, 1], format: rowHeaderFormat)
                worksheet.write(.string(clockInTime), [currentRow, 2], format: rowFormat)
                worksheet.write(.string(clockOutTime), [currentRow, 3], format: rowFormat)
                worksheet.write(.string(entry.breakTimeString()), [currentRow, 4], format: rowFormat)
                worksheet.write(.string(entry.timeWorkedString()), [currentRow, 5], format: rowFormat)
                worksheet.write(.string(formatProjectTasks(entry.projectTasks)), [currentRow, 6], format: rowFormat)
                currentRow += 1
            }
        }
        return currentRow
    }

    func writeTimesheetFooter(_ entries: [ClockEntry], at row: Int, to worksheet: Worksheet, in workbook: Workbook) {
        let footerFormat = workbook.addFormat()
        footerFormat.background(color: Color(hex: 0xE6EDF0))
        footerFormat.font(color: .black)
        footerFormat.font(name: "Arial")
        footerFormat.bold()
        footerFormat.border(style: .thin)

        let totalHours = entries.reduce(into: TimeInterval.zero) { $0 += ($1.timeWorked() ?? .zero) }
        worksheet.merge(range: [row, 0, row, 4], string: String(localized: "Header.Total"), format: footerFormat)
        worksheet.write(.string(formatTimeInterval(totalHours)), [row, 5], format: footerFormat)
        worksheet.write(.blank, [row, 6], format: footerFormat)
    }

    func exportTimesheetToCSV() {
        createIfNotExists(exportsFolderURL)
        let filename = exportFilename(prefix: "Timesheet", extension: "csv")
        let exportPath = exportsFolderURL
            .appendingPathComponent(filename)

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

        let entries = fetchCurrentMonthEntries()
        for entry in entries {
            if let clockInDate = entry.clockInDateString(),
               let clockInDay = entry.clockInDayString(),
               let clockInTime = entry.clockInTimeString(),
               let clockOutTime = entry.clockOutTimeString() {
                let row = [
                    clockInDate,
                    clockInDay,
                    clockInTime,
                    clockOutTime,
                    entry.breakTimeString(),
                    entry.timeWorkedString(),
                    formatProjectTasks(entry.projectTasks)
                ]
                csvContent += row.map { escapeCSV($0) }.joined(separator: ",") + "\n"
            }
        }

        do {
            try csvContent.write(to: exportPath, atomically: true, encoding: .utf8)
            openURL(URL(string: "shareddocuments://\(exportPath.path(percentEncoded: false))")!)
        } catch {
            print("Error exporting CSV: \(error)")
        }
    }

    func exportOvertimeToExcel() {
        createIfNotExists(exportsFolderURL)
        let filename = exportFilename(prefix: "OvertimeReport", extension: "xlsx")
        let exportPath = exportsFolderURL
            .appendingPathComponent(filename)
            .path(percentEncoded: false)
        let workbook = Workbook(name: exportPath)
        let worksheet = workbook.addWorksheet(name: "Overtime Report")
        worksheet.gridline(screen: false)
        writeOvertimeHeaders(to: worksheet, in: workbook)
        let entries = fetchCurrentMonthEntries()
        writeOvertimeRows(entries, to: worksheet, in: workbook)
        workbook.close()
        openURL(URL(string: "shareddocuments://\(exportPath)")!)
    }

    func writeOvertimeHeaders(to worksheet: Worksheet, in workbook: Workbook) {
        let headerFormat = workbook.addFormat()
        headerFormat.background(color: Color(hex: 0x8B0000))
        headerFormat.font(color: .white)
        headerFormat.font(name: "Arial")
        headerFormat.bold()
        headerFormat.border(style: .thin)

        worksheet.write(.string(String(localized: "Header.Date")), [0, 0], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.Day")), [0, 1], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.WorkingTime")), [0, 2], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.StandardHours")), [0, 3], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.Overtime")), [0, 4], format: headerFormat)

        worksheet.column([0, 0], width: 15.0)
        worksheet.column([2, 4], width: 15.0)
    }

    func writeOvertimeRows(_ entries: [ClockEntry], to worksheet: Worksheet, in workbook: Workbook) {
        let rowHeaderFormat = workbook.addFormat()
        rowHeaderFormat.background(color: Color(hex: 0xF2F2F7))
        rowHeaderFormat.font(color: .black)
        rowHeaderFormat.font(name: "Arial")
        rowHeaderFormat.border(style: .thin)

        let rowFormat = workbook.addFormat()
        rowFormat.background(color: .white)
        rowFormat.font(color: .black)
        rowFormat.font(name: "Arial")
        rowFormat.border(style: .thin)

        let overtimeFormat = workbook.addFormat()
        overtimeFormat.background(color: Color(hex: 0xFFE4E1))
        overtimeFormat.font(color: Color(hex: 0x8B0000))
        overtimeFormat.font(name: "Arial")
        overtimeFormat.border(style: .thin)

        let standardHours = settingsManager.standardWorkingHours

        var currentRow: Int = 1
        var totalOvertime: TimeInterval = 0

        for entry in entries {
            if let clockInDate = entry.clockInDateString(),
               let clockInDay = entry.clockInDayString(),
               entry.timeWorked() != nil {
                let overtime = entry.overtime(standardWorkingTime: standardHours) ?? 0
                totalOvertime += overtime

                worksheet.write(.string(clockInDate), [currentRow, 0], format: rowHeaderFormat)
                worksheet.write(.string(clockInDay), [currentRow, 1], format: rowHeaderFormat)
                worksheet.write(.string(entry.timeWorkedString()), [currentRow, 2], format: rowFormat)
                worksheet.write(.string(formatTimeInterval(standardHours)), [currentRow, 3], format: rowFormat)
                worksheet.write(.string(entry.overtimeString(standardWorkingTime: standardHours)),
                                [currentRow, 4], format: overtime > 0 ? overtimeFormat : rowFormat)
                currentRow += 1
            }
        }

        // writeOvertimeFooter
        let totalFormat = workbook.addFormat()
        totalFormat.background(color: Color(hex: 0xE27373))
        totalFormat.font(color: .white)
        totalFormat.font(name: "Arial")
        totalFormat.bold()
        totalFormat.border(style: .thin)

        worksheet.merge(range: [currentRow, 0, currentRow, 3], string: String(localized: "Header.Total"), format: totalFormat)
        worksheet.write(.string(formatTimeInterval(totalOvertime)), [currentRow, 4], format: totalFormat)
    }

    func exportOvertimeToCSV() {
        createIfNotExists(exportsFolderURL)
        let filename = exportFilename(prefix: "OvertimeReport", extension: "csv")
        let exportPath = exportsFolderURL
            .appendingPathComponent(filename)

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
        var totalOvertime: TimeInterval = 0

        let entries = fetchCurrentMonthEntries()
        for entry in entries {
            if let clockInDate = entry.clockInDateString(),
               let clockInDay = entry.clockInDayString() {
                let overtime = entry.overtime(standardWorkingTime: standardHours) ?? 0
                totalOvertime += overtime

                let row = [
                    clockInDate,
                    clockInDay,
                    entry.timeWorkedString(),
                    formatTimeInterval(standardHours),
                    entry.overtimeString(standardWorkingTime: standardHours)
                ]
                csvContent += row.map { escapeCSV($0) }.joined(separator: ",") + "\n"
            }
        }

        do {
            try csvContent.write(to: exportPath, atomically: true, encoding: .utf8)
            openURL(URL(string: "shareddocuments://\(exportPath.path(percentEncoded: false))")!)
        } catch {
            print("Error exporting CSV: \(error)")
        }
    }

    // MARK: - Helper Functions

    func exportFilename(prefix: String, extension ext: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let formattedDate = dateFormatter.string(from: .now)
        return "\(formattedDate)-\(prefix).\(ext)"
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

    func formatTimeInterval(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .full
        return formatter.string(from: interval) ?? ""
    }

    func formatProjectTasks(_ tasks: [String: String]) -> String {
        guard !tasks.isEmpty else { return "" }

        let projectDict = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0.name) })

        return tasks.map { projectId, task in
            let projectName = projectDict[projectId] ?? "Unknown Project"
            return "\(projectName): \(task)"
        }.joined(separator: "; ")
    }
}
