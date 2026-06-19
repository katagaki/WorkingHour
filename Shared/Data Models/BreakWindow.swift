//
//  BreakWindow.swift
//  WorkingHour
//
//  Created by Assistant on 2026/06/20.
//

import Foundation
import SwiftData

/// A recurring daily time range during which leaving the geofence starts a
/// break instead of clocking out.
@Model
final class BreakWindow: Identifiable {
    var id: String = UUID().uuidString
    /// Start of the window, in seconds since midnight.
    var startSeconds: Int = 12 * 3600
    /// End of the window, in seconds since midnight.
    var endSeconds: Int = 13 * 3600
    var isEnabled: Bool = true
    var createdAt: Date = Date.now

    init(startSeconds: Int, endSeconds: Int) {
        self.startSeconds = startSeconds
        self.endSeconds = endSeconds
    }

    /// Whether the given date's time of day falls within this window.
    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        let seconds = (components.hour ?? 0) * 3600 + (components.minute ?? 0) * 60 + (components.second ?? 0)
        if startSeconds <= endSeconds {
            return seconds >= startSeconds && seconds < endSeconds
        } else {
            // Window wraps past midnight.
            return seconds >= startSeconds || seconds < endSeconds
        }
    }
}
