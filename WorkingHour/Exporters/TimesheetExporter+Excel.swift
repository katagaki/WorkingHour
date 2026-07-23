//
//  TimesheetExporter+Excel.swift
//  WorkingHour
//
//  Created by Assistant on 2026/07/16.
//

import Foundation
import SwiftUI
import xlsxwriter

// MARK: - Excel Exports

extension TimesheetExporter {

    /// Row heights giving cell content breathing space (Excel default is ~15).
    private static let headerRowHeight = 28.0
    private static let dataRowHeight = 24.0

    // MARK: Cell Value Helpers

    /// The time of day as an Excel serial fraction (0.5 = 12:00), using the
    /// local calendar so the cell shows the same wall-clock time as the app.
    func excelTime(_ date: Date) -> Double {
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        let seconds = Double((components.hour ?? 0) * 3600 + (components.minute ?? 0) * 60 + (components.second ?? 0))
        return seconds / 86400
    }

    /// A duration as an Excel serial fraction, for use with the `[h]:mm` format.
    func excelDuration(_ interval: TimeInterval) -> Double {
        interval / 86400
    }

    // MARK: Timesheet

    func exportTimesheetToExcel(month: Int, year: Int) -> URL? {
        createIfNotExists(exportsFolderURL)
        let filename = exportFilename(prefix: "Timesheet", extension: "xlsx", month: month, year: year)
        let exportURL = exportsFolderURL.appendingPathComponent(filename)
        let workbook = Workbook(name: exportURL.path(percentEncoded: false))
        let worksheet = workbook.addWorksheet(name: "Timesheet")
        worksheet.gridline(screen: false)
        writeTimesheetHeaders(to: worksheet, in: workbook)
        let entries = fetchEntries(month: month, year: year)
        let lastRowWritten = writeTimesheetRows(entries, to: worksheet, in: workbook)
        writeTimesheetFooter(entries, at: lastRowWritten, to: worksheet, in: workbook)
        workbook.close()
        return exportURL
    }

    func writeTimesheetHeaders(to worksheet: Worksheet, in workbook: Workbook) {
        let headerFormat = workbook.addFormat()
        headerFormat.background(color: Color(hex: 0x004561))
        headerFormat.font(color: .white)
        headerFormat.font(name: "Arial")
        headerFormat.bold()
        headerFormat.border(style: .thin)
        headerFormat.align(vertical: .center)

        worksheet.write(.string(String(localized: "Header.Date")), [0, 0], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.Day")), [0, 1], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.StartTime")), [0, 2], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.EndTime")), [0, 3], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.BreakTime")), [0, 4], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.WorkingTime")), [0, 5], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.Remarks")), [0, 6], format: headerFormat)

        worksheet.column([0, 0], width: 16.0)
        worksheet.column([1, 1], width: 12.0)
        worksheet.column([2, 5], width: 16.0)
        worksheet.column([6, 6], width: 36.0)
        worksheet.row(0, height: Self.headerRowHeight)
    }

    func writeTimesheetRows(_ entries: [ClockEntry], to worksheet: Worksheet, in workbook: Workbook) -> Int {
        let rowHeaderFormat = workbook.addFormat()
        applyRowStyle(to: rowHeaderFormat, background: Color(hex: 0xF2F2F7))

        let rowFormat = workbook.addFormat()
        applyRowStyle(to: rowFormat, background: .white)

        let timeFormat = workbook.addFormat()
        applyRowStyle(to: timeFormat, background: .white)
        timeFormat.set(num_format: "hh:mm")

        let durationFormat = workbook.addFormat()
        applyRowStyle(to: durationFormat, background: .white)
        durationFormat.set(num_format: "[h]:mm")

        var currentRow: Int = 1
        for entry in entries {
            if let clockInDate = entry.clockInDateString(),
               let clockInDay = entry.clockInDayString(),
               let clockInTime = entry.roundedClockInTime(minutes: roundingMinutes),
               let clockOutTime = entry.roundedClockOutTime(minutes: roundingMinutes) {
                worksheet.write(.string(clockInDate), [currentRow, 0], format: rowHeaderFormat)
                worksheet.write(.string(clockInDay), [currentRow, 1], format: rowHeaderFormat)
                worksheet.write(.number(excelTime(clockInTime)), [currentRow, 2], format: timeFormat)
                worksheet.write(.number(excelTime(clockOutTime)), [currentRow, 3], format: timeFormat)
                worksheet.write(
                    .number(excelDuration(entry.roundedBreakTime(minutes: roundingMinutes))),
                    [currentRow, 4],
                    format: durationFormat
                )
                worksheet.write(
                    .number(excelDuration(entry.roundedTimeWorked(minutes: roundingMinutes) ?? .zero)),
                    [currentRow, 5],
                    format: durationFormat
                )
                worksheet.write(.string(formatProjectTasks(entry.tasks ?? [])), [currentRow, 6], format: rowFormat)
                worksheet.row(UInt32(currentRow), height: Self.dataRowHeight)
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
        footerFormat.align(vertical: .center)

        let footerDurationFormat = workbook.addFormat()
        footerDurationFormat.background(color: Color(hex: 0xE6EDF0))
        footerDurationFormat.font(color: .black)
        footerDurationFormat.font(name: "Arial")
        footerDurationFormat.bold()
        footerDurationFormat.border(style: .thin)
        footerDurationFormat.align(vertical: .center)
        footerDurationFormat.set(num_format: "[h]:mm")

        let totalHours = entries.reduce(into: TimeInterval.zero) {
            $0 += ($1.roundedTimeWorked(minutes: roundingMinutes) ?? .zero)
        }
        worksheet.merge(range: [row, 0, row, 4], string: String(localized: "Header.Total"), format: footerFormat)
        worksheet.write(.number(excelDuration(totalHours)), [row, 5], format: footerDurationFormat)
        worksheet.write(.blank, [row, 6], format: footerFormat)
        worksheet.row(UInt32(row), height: Self.headerRowHeight)
    }

    // MARK: Overtime

    func exportOvertimeToExcel(month: Int, year: Int) -> URL? {
        createIfNotExists(exportsFolderURL)
        let filename = exportFilename(prefix: "OvertimeReport", extension: "xlsx", month: month, year: year)
        let exportURL = exportsFolderURL.appendingPathComponent(filename)
        let workbook = Workbook(name: exportURL.path(percentEncoded: false))
        let worksheet = workbook.addWorksheet(name: "Overtime Report")
        worksheet.gridline(screen: false)
        writeOvertimeHeaders(to: worksheet, in: workbook)
        let entries = fetchEntries(month: month, year: year)
        writeOvertimeRows(entries, to: worksheet, in: workbook)
        workbook.close()
        return exportURL
    }

    func writeOvertimeHeaders(to worksheet: Worksheet, in workbook: Workbook) {
        let headerFormat = workbook.addFormat()
        headerFormat.background(color: Color(hex: 0x8B0000))
        headerFormat.font(color: .white)
        headerFormat.font(name: "Arial")
        headerFormat.bold()
        headerFormat.border(style: .thin)
        headerFormat.align(vertical: .center)

        worksheet.write(.string(String(localized: "Header.Date")), [0, 0], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.Day")), [0, 1], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.WorkingTime")), [0, 2], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.StandardHours")), [0, 3], format: headerFormat)
        worksheet.write(.string(String(localized: "Header.Overtime")), [0, 4], format: headerFormat)

        worksheet.column([0, 0], width: 16.0)
        worksheet.column([1, 1], width: 12.0)
        worksheet.column([2, 4], width: 16.0)
        worksheet.row(0, height: Self.headerRowHeight)
    }

    // swiftlint:disable:next function_body_length
    func writeOvertimeRows(_ entries: [ClockEntry], to worksheet: Worksheet, in workbook: Workbook) {
        let rowHeaderFormat = workbook.addFormat()
        applyRowStyle(to: rowHeaderFormat, background: Color(hex: 0xF2F2F7))

        let durationFormat = workbook.addFormat()
        applyRowStyle(to: durationFormat, background: .white)
        durationFormat.set(num_format: "[h]:mm")

        let overtimeFormat = workbook.addFormat()
        applyRowStyle(to: overtimeFormat, background: Color(hex: 0xFFE4E1))
        overtimeFormat.font(color: Color(hex: 0x8B0000))
        overtimeFormat.set(num_format: "[h]:mm")

        let standardHours = settingsManager.standardWorkingHours

        var currentRow: Int = 1
        var totalOvertime: TimeInterval = 0

        for entry in entries {
            if let clockInDate = entry.clockInDateString(),
               let clockInDay = entry.clockInDayString(),
               let timeWorked = entry.roundedTimeWorked(minutes: roundingMinutes) {
                let overtime = entry.roundedOvertime(
                    standardWorkingTime: standardHours,
                    minutes: roundingMinutes
                ) ?? 0
                totalOvertime += overtime

                worksheet.write(.string(clockInDate), [currentRow, 0], format: rowHeaderFormat)
                worksheet.write(.string(clockInDay), [currentRow, 1], format: rowHeaderFormat)
                worksheet.write(.number(excelDuration(timeWorked)), [currentRow, 2], format: durationFormat)
                worksheet.write(.number(excelDuration(standardHours)), [currentRow, 3], format: durationFormat)
                worksheet.write(.number(excelDuration(overtime)),
                                [currentRow, 4], format: overtime > 0 ? overtimeFormat : durationFormat)
                worksheet.row(UInt32(currentRow), height: Self.dataRowHeight)
                currentRow += 1
            }
        }

        let totalFormat = workbook.addFormat()
        totalFormat.background(color: Color(hex: 0xE27373))
        totalFormat.font(color: .white)
        totalFormat.font(name: "Arial")
        totalFormat.bold()
        totalFormat.border(style: .thin)
        totalFormat.align(vertical: .center)

        let totalDurationFormat = workbook.addFormat()
        totalDurationFormat.background(color: Color(hex: 0xE27373))
        totalDurationFormat.font(color: .white)
        totalDurationFormat.font(name: "Arial")
        totalDurationFormat.bold()
        totalDurationFormat.border(style: .thin)
        totalDurationFormat.align(vertical: .center)
        totalDurationFormat.set(num_format: "[h]:mm")

        worksheet.merge(
            range: [currentRow, 0, currentRow, 3],
            string: String(localized: "Header.Total"),
            format: totalFormat
        )
        worksheet.write(.number(excelDuration(totalOvertime)), [currentRow, 4], format: totalDurationFormat)
        worksheet.row(UInt32(currentRow), height: Self.headerRowHeight)
    }

    // MARK: Format Helpers

    /// Applies the common body-cell style: Arial, black text, thin border,
    /// vertically centered so taller rows read with breathing space.
    private func applyRowStyle(to format: Format, background: xlsxwriter.Color) {
        format.background(color: background)
        format.font(color: .black)
        format.font(name: "Arial")
        format.border(style: .thin)
        format.align(vertical: .center)
    }
}
