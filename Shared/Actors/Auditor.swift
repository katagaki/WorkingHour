//
//  Auditor.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2024/12/09.
//

import Foundation
import SwiftData

@ModelActor
actor Auditor {

    func entries(in month: Int, _ year: Int) -> [PersistentIdentifier] {
        let (startDate, endDate) = firstAndLastDayOfMonth(month: month, year: year)
        let fetchDescriptor = FetchDescriptor<ClockEntry>(
            sortBy: [SortDescriptor(\.clockInTime)]
        )
        if let entries = try? modelContext.fetch(fetchDescriptor) {
            return entries
                .filter { entry in
                    return (entry.clockInTime ?? .distantFuture) >= startDate &&
                    (entry.clockOutTime ?? .distantPast) <= endDate
                }
                .map { entry in
                    entry.persistentModelID
                }
        } else {
            return []
        }
    }

    func firstAndLastDayOfMonth(month: Int, year: Int) -> (firstDay: Date, lastDay: Date) {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0

        let calendar = Calendar.current
        if let firstDay = calendar.date(from: components) {
            if let firstDayOfNextMonth = calendar.date(byAdding: .month, value: 1, to: firstDay),
               let lastDay = calendar.date(byAdding: .day, value: -1, to: firstDayOfNextMonth) {
                return (firstDay, lastDay)
            }
        }
        return (.distantPast, .distantFuture)

    }
}
