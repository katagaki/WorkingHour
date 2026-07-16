//
//  TimesheetExporter+PDF.swift
//  WorkingHour
//
//  Created by Assistant on 2026/07/16.
//

import Foundation
import UIKit

// MARK: - PDF Export

extension TimesheetExporter {

    private enum PDFLayout {
        // A4 in points
        static let pageSize = CGSize(width: 595.2, height: 841.8)
        static let margin = 40.0
        static let headerRowHeight = 26.0
        static let minimumRowHeight = 24.0
        static let cellPadding = 6.0

        static let headerColor = UIColor(red: 0.0, green: 0.27, blue: 0.38, alpha: 1.0) // matches Excel header
        static let stripeColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        static let totalColor = UIColor(red: 0.90, green: 0.93, blue: 0.94, alpha: 1.0)

        /// Column widths for: date, day, start, end, break, working time, remarks.
        static var columnWidths: [Double] {
            let contentWidth = pageSize.width - margin * 2
            let fixed: [Double] = [80, 55, 48, 48, 52, 60]
            return fixed + [contentWidth - fixed.reduce(0, +)]
        }
    }

    func exportTimesheetToPDF(month: Int, year: Int) -> URL? {
        createIfNotExists(exportsFolderURL)
        let filename = exportFilename(prefix: "Timesheet", extension: "pdf", month: month, year: year)
        let exportURL = exportsFolderURL.appendingPathComponent(filename)

        let entries = fetchEntries(month: month, year: year)
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(origin: .zero, size: PDFLayout.pageSize)
        )

        do {
            try renderer.writePDF(to: exportURL) { context in
                var cursorY = beginPage(context, month: month, year: year)
                cursorY = drawTableHeader(at: cursorY)

                for entry in entries {
                    guard let row = pdfRow(for: entry) else { continue }
                    let rowHeight = rowHeight(for: row)
                    if cursorY + rowHeight > PDFLayout.pageSize.height - PDFLayout.margin {
                        cursorY = beginPage(context, month: month, year: year)
                        cursorY = drawTableHeader(at: cursorY)
                    }
                    cursorY = drawRow(row, at: cursorY, height: rowHeight)
                }

                cursorY = drawTotalRow(entries, at: cursorY, in: context, month: month, year: year)
                drawEarningsSummary(entries, at: cursorY + 24.0)
            }
            return exportURL
        } catch {
            print("Error exporting PDF: \(error)")
            return nil
        }
    }

    // MARK: Page Scaffolding

    /// Starts a new page and draws the document title. Returns the y position
    /// where content may continue.
    private func beginPage(_ context: UIGraphicsPDFRendererContext, month: Int, year: Int) -> Double {
        context.beginPage()

        let title = String(localized: "Export.Section.Timesheet")
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20.0, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        title.draw(
            at: CGPoint(x: PDFLayout.margin, y: PDFLayout.margin),
            withAttributes: titleAttributes
        )

        var components = DateComponents()
        components.year = year
        components.month = month
        let monthDate = Calendar.current.date(from: components) ?? .now
        let subtitle = monthDate.formatted(.dateTime.year().month(.wide))
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13.0, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]
        subtitle.draw(
            at: CGPoint(x: PDFLayout.margin, y: PDFLayout.margin + 26.0),
            withAttributes: subtitleAttributes
        )

        return PDFLayout.margin + 56.0
    }

    private func drawTableHeader(at cursorY: Double) -> Double {
        let headers = [
            String(localized: "Header.Date"),
            String(localized: "Header.Day"),
            String(localized: "Header.StartTime"),
            String(localized: "Header.EndTime"),
            String(localized: "Header.BreakTime"),
            String(localized: "Header.WorkingTime"),
            String(localized: "Header.Remarks")
        ]

        let rect = CGRect(
            x: PDFLayout.margin,
            y: cursorY,
            width: PDFLayout.pageSize.width - PDFLayout.margin * 2,
            height: PDFLayout.headerRowHeight
        )
        PDFLayout.headerColor.setFill()
        UIBezierPath(rect: rect).fill()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10.0, weight: .semibold),
            .foregroundColor: UIColor.white
        ]
        drawCells(headers, at: cursorY, height: PDFLayout.headerRowHeight, attributes: attributes)
        return cursorY + PDFLayout.headerRowHeight
    }

    // MARK: Rows

    private func pdfRow(for entry: ClockEntry) -> [String]? {
        guard let clockInDate = entry.clockInDateString(),
              let clockInDay = entry.clockInDayString(),
              let clockInTime = entry.roundedClockInTime(minutes: roundingMinutes),
              let clockOutTime = entry.roundedClockOutTime(minutes: roundingMinutes) else {
            return nil
        }
        return [
            clockInDate,
            clockInDay,
            formatTime(clockInTime),
            formatTime(clockOutTime),
            formatShortTimeInterval(entry.roundedBreakTime(minutes: roundingMinutes)),
            formatShortTimeInterval(entry.roundedTimeWorked(minutes: roundingMinutes) ?? .zero),
            formatProjectTasks(entry.tasks ?? [])
        ]
    }

    private func rowHeight(for row: [String]) -> Double {
        // Remarks is the only column that wraps.
        let remarksWidth = PDFLayout.columnWidths[6] - PDFLayout.cellPadding * 2
        let bounding = (row[6] as NSString).boundingRect(
            with: CGSize(width: remarksWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin],
            attributes: [.font: UIFont.systemFont(ofSize: 10.0)],
            context: nil
        )
        return max(PDFLayout.minimumRowHeight, bounding.height + PDFLayout.cellPadding * 2)
    }

    private func drawRow(_ row: [String], at cursorY: Double, height: Double, stripe: Bool = true) -> Double {
        let rect = CGRect(
            x: PDFLayout.margin,
            y: cursorY,
            width: PDFLayout.pageSize.width - PDFLayout.margin * 2,
            height: height
        )
        if stripe {
            PDFLayout.stripeColor.setFill()
        } else {
            PDFLayout.totalColor.setFill()
        }
        UIBezierPath(rect: rect).fill()

        UIColor.white.setFill()
        let innerRect = rect.insetBy(dx: 0.0, dy: 0.5)
        UIBezierPath(rect: innerRect).fill()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10.0),
            .foregroundColor: UIColor.black
        ]
        drawCells(row, at: cursorY, height: height, attributes: attributes)
        return cursorY + height
    }

    private func drawTotalRow(
        _ entries: [ClockEntry],
        at cursorY: Double,
        in context: UIGraphicsPDFRendererContext,
        month: Int,
        year: Int
    ) -> Double {
        var cursorY = cursorY
        if cursorY + PDFLayout.headerRowHeight > PDFLayout.pageSize.height - PDFLayout.margin {
            cursorY = beginPage(context, month: month, year: year)
        }

        let totalHours = entries.reduce(into: TimeInterval.zero) {
            $0 += ($1.roundedTimeWorked(minutes: roundingMinutes) ?? .zero)
        }

        let rect = CGRect(
            x: PDFLayout.margin,
            y: cursorY,
            width: PDFLayout.pageSize.width - PDFLayout.margin * 2,
            height: PDFLayout.headerRowHeight
        )
        PDFLayout.totalColor.setFill()
        UIBezierPath(rect: rect).fill()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10.0, weight: .semibold),
            .foregroundColor: UIColor.black
        ]
        let row = [
            String(localized: "Header.Total"), "", "", "", "",
            formatShortTimeInterval(totalHours), ""
        ]
        drawCells(row, at: cursorY, height: PDFLayout.headerRowHeight, attributes: attributes)
        return cursorY + PDFLayout.headerRowHeight
    }

    /// Draws the estimated pay block below the table when earnings tracking
    /// is set up.
    private func drawEarningsSummary(_ entries: [ClockEntry], at cursorY: Double) {
        guard settingsManager.isEarningsTrackingEnabled else { return }

        let summary = EarningsCalculator.summarize(
            entries,
            standardWorkingHours: settingsManager.standardWorkingHours,
            hourlyRate: settingsManager.hourlyRate,
            overtimeMultiplier: settingsManager.overtimeRateMultiplier,
            roundingMinutes: roundingMinutes
        )
        let currency = settingsManager.currencyCode

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10.0),
            .foregroundColor: UIColor.darkGray
        ]
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10.0, weight: .semibold),
            .foregroundColor: UIColor.black
        ]

        var lineY = cursorY
        let lines: [(String, String)] = [
            (String(localized: "Earnings.RegularPay"),
             summary.regularPay.formatted(.currency(code: currency))),
            (String(localized: "Earnings.OvertimePay"),
             summary.overtimePay.formatted(.currency(code: currency))),
            (String(localized: "Earnings.TotalPay"),
             summary.totalPay.formatted(.currency(code: currency)))
        ]
        for (label, value) in lines {
            label.draw(at: CGPoint(x: PDFLayout.margin, y: lineY), withAttributes: labelAttributes)
            let valueSize = (value as NSString).size(withAttributes: valueAttributes)
            value.draw(
                at: CGPoint(x: PDFLayout.margin + 200.0 - valueSize.width, y: lineY),
                withAttributes: valueAttributes
            )
            lineY += 16.0
        }

        let disclaimer = String(localized: "Earnings.Estimate.Footer")
        disclaimer.draw(
            at: CGPoint(x: PDFLayout.margin, y: lineY + 4.0),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 8.0),
                .foregroundColor: UIColor.gray
            ]
        )
    }

    // MARK: Drawing Helpers

    private func drawCells(
        _ values: [String],
        at cursorY: Double,
        height: Double,
        attributes: [NSAttributedString.Key: Any]
    ) {
        var cellX = PDFLayout.margin
        for (index, value) in values.enumerated() {
            let width = PDFLayout.columnWidths[index]
            let textRect = CGRect(
                x: cellX + PDFLayout.cellPadding,
                y: cursorY + PDFLayout.cellPadding,
                width: width - PDFLayout.cellPadding * 2,
                height: height - PDFLayout.cellPadding * 2
            )
            (value as NSString).draw(
                with: textRect,
                options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine],
                attributes: attributes,
                context: nil
            )
            cellX += width
        }
    }

    private func formatShortTimeInterval(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: max(0, interval)) ?? ""
    }
}
