//
//  ExportView.swift
//  Working Hour
//
//  Created by シン・ジャスティン on 2024/11/04.
//

import Komponents
import SwiftData
import SwiftUI
import xlsxwriter

let isCloudSyncEnabled = FileManager.default.url(forUbiquityContainerIdentifier: nil) != nil
let documentsURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") ??
                   FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
let exportsFolderURL = documentsURL.appendingPathComponent("Exports")

struct ExportView: View {
    @Environment(\.openURL) var openURL
    @Environment(\.modelContext) var modelContext

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Group {
                        Button {
                            createIfNotExists(exportsFolderURL)
                            let filename = exportFilename()
                            let exportPath = exportsFolderURL
                                .appendingPathComponent(filename)
                                .path(percentEncoded: false)
                            let workbook = Workbook(name: exportPath)
                            let worksheet = workbook.addWorksheet(name: "Timesheet")
                            worksheet.gridline(screen: false)
                            writeHeaders(to: worksheet, in: workbook)
                            let fetchDescriptor = FetchDescriptor<ClockEntry>(
                                sortBy: [SortDescriptor(\.clockInTime, order: .forward)]
                            )
                            var entries: [ClockEntry] = (try? modelContext.fetch(fetchDescriptor)) ?? []
                            let dateNow = Date.now
                            let calendar = Calendar.current
                            entries.removeAll(where: { entry in
                                if let clockInTime = entry.clockInTime {
                                    return !calendar.isDate(clockInTime,
                                                            equalTo: dateNow,
                                                            toGranularity: .month)
                                } else {
                                    return true
                                }
                            })
                            writeRows(entries, to: worksheet, in: workbook)
                            workbook.close()
                            openURL(URL(string: "shareddocuments://\(exportPath)")!)
                        } label: {
                            ListRow(image: "ListIcon.Excel", title: "Excel")
                        }
                        Button {
                            createIfNotExists(exportsFolderURL)
                            let filename = exportCSVFilename()
                            let exportPath = exportsFolderURL
                                .appendingPathComponent(filename)
                            let fetchDescriptor = FetchDescriptor<ClockEntry>(
                                sortBy: [SortDescriptor(\.clockInTime, order: .forward)]
                            )
                            var entries: [ClockEntry] = (try? modelContext.fetch(fetchDescriptor)) ?? []
                            let dateNow = Date.now
                            let calendar = Calendar.current
                            entries.removeAll(where: { entry in
                                if let clockInTime = entry.clockInTime {
                                    return !calendar.isDate(clockInTime,
                                                            equalTo: dateNow,
                                                            toGranularity: .month)
                                } else {
                                    return true
                                }
                            })
                            exportToCSV(entries: entries, to: exportPath)
                            openURL(URL(string: "shareddocuments://\(exportPath.path(percentEncoded: false))")!)
                        } label: {
                            ListRow(image: "ListIcon.CSV", title: "CSV")
                        }
                    }
                    .tint(.primary)
                } header: {
                    ListSectionHeader(text: "Timesheet Export")
                }
                
                Section {
                    Group {
                        Button {
                            createIfNotExists(exportsFolderURL)
                            let filename = exportOvertimeExcelFilename()
                            let exportPath = exportsFolderURL
                                .appendingPathComponent(filename)
                                .path(percentEncoded: false)
                            let workbook = Workbook(name: exportPath)
                            let worksheet = workbook.addWorksheet(name: "Overtime Report")
                            worksheet.gridline(screen: false)
                            writeOvertimeHeaders(to: worksheet, in: workbook)
                            let fetchDescriptor = FetchDescriptor<ClockEntry>(
                                sortBy: [SortDescriptor(\.clockInTime, order: .forward)]
                            )
                            var entries: [ClockEntry] = (try? modelContext.fetch(fetchDescriptor)) ?? []
                            let dateNow = Date.now
                            let calendar = Calendar.current
                            entries.removeAll(where: { entry in
                                if let clockInTime = entry.clockInTime {
                                    return !calendar.isDate(clockInTime,
                                                            equalTo: dateNow,
                                                            toGranularity: .month)
                                } else {
                                    return true
                                }
                            })
                            let settings = (try? modelContext.fetch(FetchDescriptor<AppSettings>()))?.first
                            let standardWorkingTime = settings?.standardWorkingTimeInSeconds ?? 28800.0
                            writeOvertimeRows(entries, standardWorkingTime: standardWorkingTime, to: worksheet, in: workbook)
                            workbook.close()
                            openURL(URL(string: "shareddocuments://\(exportPath)")!)
                        } label: {
                            ListRow(image: "ListIcon.Excel", title: "Excel")
                        }
                        Button {
                            createIfNotExists(exportsFolderURL)
                            let filename = exportOvertimeCSVFilename()
                            let exportPath = exportsFolderURL
                                .appendingPathComponent(filename)
                            let fetchDescriptor = FetchDescriptor<ClockEntry>(
                                sortBy: [SortDescriptor(\.clockInTime, order: .forward)]
                            )
                            var entries: [ClockEntry] = (try? modelContext.fetch(fetchDescriptor)) ?? []
                            let dateNow = Date.now
                            let calendar = Calendar.current
                            entries.removeAll(where: { entry in
                                if let clockInTime = entry.clockInTime {
                                    return !calendar.isDate(clockInTime,
                                                            equalTo: dateNow,
                                                            toGranularity: .month)
                                } else {
                                    return true
                                }
                            })
                            let settings = (try? modelContext.fetch(FetchDescriptor<AppSettings>()))?.first
                            let standardWorkingTime = settings?.standardWorkingTimeInSeconds ?? 28800.0
                            exportOvertimeToCSV(entries: entries, standardWorkingTime: standardWorkingTime, to: exportPath)
                            openURL(URL(string: "shareddocuments://\(exportPath.path(percentEncoded: false))")!)
                        } label: {
                            ListRow(image: "ListIcon.CSV", title: "CSV")
                        }
                    }
                    .tint(.primary)
                } header: {
                    ListSectionHeader(text: "Overtime Report Export")
                }
            }
            .navigationTitle("ViewTitle.Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("ViewTitle.Export")
                        .font(.title)
                        .fontWeight(.bold)
                }
                ToolbarItem(placement: .principal) {
                    Spacer()
                }
            }
        }
    }

    // MARK: Excel

    func writeHeaders(to worksheet: Worksheet, in workbook: Workbook) {
        // Setup header styles
        let headerFormat = workbook.addFormat()
        headerFormat.background(color: Color(hex: 0x004561))
        headerFormat.font(color: .white)
        headerFormat.font(name: "Arial")
        headerFormat.bold()
        headerFormat.border(style: .thin)
        // Write headers
        worksheet.write(.string(String(localized: "Header.Date")), [0, 0], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.Day")), [0, 1], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.StartTime")), [0, 2], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.EndTime")), [0, 3], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.BreakTime")), [0, 4], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.WorkingTime")), [0, 5], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.Remarks")), [0, 6], format: headerFormat)
        // Set column widths
        worksheet.column([0, 0], width: 15.0)
        worksheet.column([2, 5], width: 15.0)
        worksheet.column([6, 6], width: 30.0)
    }

    func writeRows(_ entries: [ClockEntry], to worksheet: Worksheet, in workbook: Workbook) {
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
                worksheet.write(.string(entry.breakTimeString()), [currentRow, 4],
                                format: rowFormat)
                worksheet.write(.string(entry.timeWorkedString()), [currentRow, 5],
                                format: rowFormat)
                worksheet.write(.string(""), [currentRow, 6], format: rowFormat)
                currentRow += 1
            }
        }
    }

    // MARK: Files

    func exportFilename() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let formattedDate = dateFormatter.string(from: .now)
        return "\(formattedDate)-Timesheet.xlsx"
    }
    
    func exportCSVFilename() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let formattedDate = dateFormatter.string(from: .now)
        return "\(formattedDate)-Timesheet.csv"
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
    
    // MARK: CSV
    
    func exportToCSV(entries: [ClockEntry], to path: URL) {
        var csvString = "\(String(localized: "Header.Date")),\(String(localized: "Header.Day")),\(String(localized: "Header.StartTime")),\(String(localized: "Header.EndTime")),\(String(localized: "Header.BreakTime")),\(String(localized: "Header.WorkingTime")),\(String(localized: "Header.Remarks"))\n"
        
        for entry in entries {
            if let clockInDate = entry.clockInDateString(),
               let clockInDay = entry.clockInDayString(),
               let clockInTime = entry.clockInTimeString(),
               let clockOutTime = entry.clockOutTimeString() {
                let row = "\(escapeCSV(clockInDate)),\(escapeCSV(clockInDay)),\(escapeCSV(clockInTime)),\(escapeCSV(clockOutTime)),\(escapeCSV(entry.breakTimeString())),\(escapeCSV(entry.timeWorkedString())),"
                csvString.append(row + "\n")
            }
        }
        
        try? csvString.write(to: path, atomically: true, encoding: .utf8)
    }
    
    func escapeCSV(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
    
    // MARK: Overtime Export
    
    func exportOvertimeExcelFilename() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let formattedDate = dateFormatter.string(from: .now)
        return "\(formattedDate)-OvertimeReport.xlsx"
    }
    
    func exportOvertimeCSVFilename() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let formattedDate = dateFormatter.string(from: .now)
        return "\(formattedDate)-OvertimeReport.csv"
    }
    
    func writeOvertimeHeaders(to worksheet: Worksheet, in workbook: Workbook) {
        // Setup header styles
        let headerFormat = workbook.addFormat()
        headerFormat.background(color: Color(hex: 0x004561))
        headerFormat.font(color: .white)
        headerFormat.font(name: "Arial")
        headerFormat.bold()
        headerFormat.border(style: .thin)
        // Write headers
        worksheet.write(.string(String(localized: "Header.Date")), [0, 0], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.Day")), [0, 1], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.WorkingTime")), [0, 2], format: headerFormat)
        worksheet.write(.string("Standard Hours"), [0, 3], format: headerFormat)
        worksheet.write(.string("Overtime"), [0, 4], format: headerFormat)
        // Set column widths
        worksheet.column([0, 0], width: 15.0)
        worksheet.column([2, 4], width: 15.0)
    }
    
    func writeOvertimeRows(_ entries: [ClockEntry], standardWorkingTime: TimeInterval, to worksheet: Worksheet, in workbook: Workbook) {
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
        overtimeFormat.background(color: Color(hex: 0xFFF3E0))
        overtimeFormat.font(color: .black)
        overtimeFormat.font(name: "Arial")
        overtimeFormat.border(style: .thin)
        
        var currentRow: Int = 1
        for entry in entries {
            if let clockInDate = entry.clockInDateString(),
               let clockInDay = entry.clockInDayString() {
                worksheet.write(.string(clockInDate), [currentRow, 0], format: rowHeaderFormat)
                worksheet.write(.string(clockInDay), [currentRow, 1], format: rowHeaderFormat)
                worksheet.write(.string(entry.timeWorkedString()), [currentRow, 2], format: rowFormat)
                let standardHoursString = formatStandardHours(standardWorkingTime)
                worksheet.write(.string(standardHoursString), [currentRow, 3], format: rowFormat)
                worksheet.write(.string(entry.overtimeString(standardWorkingTime: standardWorkingTime)), 
                              [currentRow, 4], format: overtimeFormat)
                currentRow += 1
            }
        }
    }
    
    func exportOvertimeToCSV(entries: [ClockEntry], standardWorkingTime: TimeInterval, to path: URL) {
        var csvString = "\(String(localized: "Header.Date")),\(String(localized: "Header.Day")),\(String(localized: "Header.WorkingTime")),Standard Hours,Overtime\n"
        
        let standardHoursString = formatStandardHours(standardWorkingTime)
        for entry in entries {
            if let clockInDate = entry.clockInDateString(),
               let clockInDay = entry.clockInDayString() {
                let row = "\(escapeCSV(clockInDate)),\(escapeCSV(clockInDay)),\(escapeCSV(entry.timeWorkedString())),\(escapeCSV(standardHoursString)),\(escapeCSV(entry.overtimeString(standardWorkingTime: standardWorkingTime)))"
                csvString.append(row + "\n")
            }
        }
        
        try? csvString.write(to: path, atomically: true, encoding: .utf8)
    }
    
    func formatStandardHours(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .full
        return formatter.string(from: interval) ?? ""
    }
}
