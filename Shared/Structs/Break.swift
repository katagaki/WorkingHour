//
//  Break.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2024/10/12.
//

import Foundation

struct Break: Codable, Hashable {
    var start: Date
    var end: Date?

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

    func hash(into hasher: inout Hasher) {
        hasher.combine(start)
        hasher.combine(end)
    }

    static func == (lhs: Break, rhs: Break) -> Bool {
        return lhs.start == rhs.start && lhs.end == rhs.end
    }
}
