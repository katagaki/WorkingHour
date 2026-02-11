//
//  Break.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2024/10/12.
//

import Foundation
import SwiftData

@Model
final class Break: Identifiable {
    var id: String = UUID().uuidString
    var start: Date = Date.now
    var end: Date?

    @Relationship(inverse: \ClockEntry.breakTimes)
    var clockEntry: ClockEntry?

    init(start: Date) {
        self.start = start
    }

    init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }

    func time() -> TimeInterval {
        if let end {
            return end.timeIntervalSince(start)
        } else {
            return .zero
        }
    }
}
