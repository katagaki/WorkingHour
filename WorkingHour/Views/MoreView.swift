//
//  MoreView.swift
//  Working Hour
//
//  Created by シン・ジャスティン on 2024/10/12.
//

import Komponents
import SwiftData
import SwiftUI
import xlsxwriter

let isCloudSyncEnabled = FileManager.default.url(forUbiquityContainerIdentifier: nil) != nil
let documentsURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") ??
                   FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
let exportsFolderURL = documentsURL.appendingPathComponent("Exports")

struct MoreView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @Environment(\.modelContext) var modelContext

    var body: some View {
        NavigationStack {
            MoreList(repoName: "katagaki/WorkingHour") {
                Section {
                    Group {
                        Button {
                            createIfNotExists(exportsFolderURL)
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyyMMdd"
                            let formattedDate = dateFormatter.string(from: .now)
                            let filename = "\(formattedDate)-Timesheet.xlsx"
                            let exportPath = exportsFolderURL.appendingPathComponent(filename).path(percentEncoded: false)
                            let workbook = Workbook(name: exportPath)
                            let worksheet = workbook.addWorksheet(name: "Timesheet")
                            let headerFormat = workbook.addFormat()
                            headerFormat.background(color: .navy)
                            headerFormat.font(color: .white)
                            headerFormat.font(name: "Arial")
                            headerFormat.bold()
                            headerFormat.border(style: .hair)
                            worksheet.write(.string("Date"), [0, 0], format: headerFormat)
                            worksheet.write(.string("Day"), [0, 1], format: headerFormat)
                            worksheet.write(.string("Start Time"), [0, 2], format: headerFormat)
                            worksheet.write(.string("End Time"), [0, 3], format: headerFormat)
                            worksheet.write(.string("Break Time"), [0, 4], format: headerFormat)
                            worksheet.write(.string("Working Time"), [0, 5], format: headerFormat)
                            worksheet.write(.string("Remarks"), [0, 6], format: headerFormat)
                            let fetchDescriptor = FetchDescriptor<ClockEntry>(
                                sortBy: [SortDescriptor(\.clockInTime, order: .forward)]
                            )
                            let entries: [ClockEntry] = (try? modelContext.fetch(fetchDescriptor)) ?? []
                            var currentRow: Int = 1
                            for entry in entries {
                                if let clockInDate = entry.clockInDateString(),
                                   let clockInDay = entry.clockInDayString(),
                                   let clockInTime = entry.clockInTimeString(),
                                   let clockOutTime = entry.clockOutTimeString() {
                                    worksheet.write(.string(clockInDate), [currentRow, 0])
                                    worksheet.write(.string(clockInDay), [currentRow, 1])
                                    worksheet.write(.string(clockInTime), [currentRow, 2])
                                    worksheet.write(.string(clockOutTime), [currentRow, 3])
                                    worksheet.write(.string(entry.breakTimeString()), [currentRow, 4])
                                    worksheet.write(.string(entry.timeWorkedString()), [currentRow, 5])
                                    currentRow += 1
                                }
                            }
                            workbook.close()
                            debugPrint(exportPath)
                            openURL(URL(string: "shareddocuments://\(exportPath)")!)
                        } label: {
                            ListRow(image: "ListIcon.Excel", title: "Excel")
                        }
                        Button {
                            // TODO
                        } label: {
                            ListRow(image: "ListIcon.CSV", title: "CSV")
                        }
                    }
                    .tint(.primary)
                } header: {
                    ListSectionHeader(text: "Export")
                }
            }
            .navigationTitle("More")
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

}
