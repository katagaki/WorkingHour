//
//  SettingsManager.swift
//  WorkingHour
//
//  Created by Assistant on 2026/02/07.
//

import Foundation

@MainActor
@Observable
final class SettingsManager {

    static let shared = SettingsManager()

    private let defaults = UserDefaults(suiteName: "group.com.tsubuzaki.WorkingHour") ?? UserDefaults.standard

    // MARK: - Keys

    private enum Keys {
        static let standardWorkingHours = "standardWorkingHours"
        static let defaultBreakDuration = "defaultBreakDuration"
        static let autoAddBreakTime = "autoAddBreakTime"
        static let clockInReminderEnabled = "clockInReminderEnabled"
        static let clockOutReminderEnabled = "clockOutReminderEnabled"
        static let clockInReminderTime = "clockInReminderTime"
        static let clockOutReminderTime = "clockOutReminderTime"
        static let notificationsLastScheduledDate = "notificationsLastScheduledDate"
    }

    // MARK: - Properties

    var standardWorkingHours: TimeInterval {
        get {
            let value = defaults.double(forKey: Keys.standardWorkingHours)
            return value > 0 ? value : 8 * 3600
        }
        set {
            defaults.set(newValue, forKey: Keys.standardWorkingHours)
        }
    }

    var defaultBreakDuration: TimeInterval {
        get {
            let value = defaults.double(forKey: Keys.defaultBreakDuration)
            if defaults.object(forKey: Keys.defaultBreakDuration) == nil {
                return 3600
            }
            return value
        }
        set {
            defaults.set(newValue, forKey: Keys.defaultBreakDuration)
        }
    }

    var autoAddBreakTime: Bool {
        get {
            defaults.bool(forKey: Keys.autoAddBreakTime)
        }
        set {
            defaults.set(newValue, forKey: Keys.autoAddBreakTime)
        }
    }

    var clockInReminderEnabled: Bool {
        get {
            defaults.bool(forKey: Keys.clockInReminderEnabled)
        }
        set {
            defaults.set(newValue, forKey: Keys.clockInReminderEnabled)
        }
    }

    var clockOutReminderEnabled: Bool {
        get {
            defaults.bool(forKey: Keys.clockOutReminderEnabled)
        }
        set {
            defaults.set(newValue, forKey: Keys.clockOutReminderEnabled)
        }
    }

    /// Stored as seconds since midnight
    var clockInReminderTime: Double {
        get {
            let value = defaults.double(forKey: Keys.clockInReminderTime)
            if defaults.object(forKey: Keys.clockInReminderTime) == nil {
                return 8 * 3600 // Default: 08:00
            }
            return value
        }
        set {
            defaults.set(newValue, forKey: Keys.clockInReminderTime)
        }
    }

    /// Stored as seconds since midnight
    var clockOutReminderTime: Double {
        get {
            let value = defaults.double(forKey: Keys.clockOutReminderTime)
            if defaults.object(forKey: Keys.clockOutReminderTime) == nil {
                return 17 * 3600 // Default: 17:00
            }
            return value
        }
        set {
            defaults.set(newValue, forKey: Keys.clockOutReminderTime)
        }
    }

    /// The date when notifications were last bulk-scheduled, or `nil` if never.
    var notificationsLastScheduledDate: Date? {
        get {
            defaults.object(forKey: Keys.notificationsLastScheduledDate) as? Date
        }
        set {
            defaults.set(newValue, forKey: Keys.notificationsLastScheduledDate)
        }
    }

    /// Convenience: returns `DateComponents` (hour + minute) for the stored clock-in time.
    var clockInReminderTimeComponents: DateComponents {
        let totalSeconds = Int(clockInReminderTime)
        var components = DateComponents()
        components.hour = totalSeconds / 3600
        components.minute = (totalSeconds % 3600) / 60
        return components
    }

    // MARK: - Initialization

    private init() {
        // Register defaults for first launch
        defaults.register(defaults: [
            Keys.standardWorkingHours: 8 * 3600,
            Keys.defaultBreakDuration: 3600,
            Keys.autoAddBreakTime: false,
            Keys.clockInReminderEnabled: false,
            Keys.clockOutReminderEnabled: false,
            Keys.clockInReminderTime: 8 * 3600,
            Keys.clockOutReminderTime: 17 * 3600
        ])
    }
}
