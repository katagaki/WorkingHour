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
        static let clockInReminderEnabled = "clockInReminderEnabled"
        static let clockOutReminderEnabled = "clockOutReminderEnabled"
        static let clockInReminderTime = "clockInReminderTime"
        static let clockOutReminderTime = "clockOutReminderTime"
        static let notificationsLastScheduledDate = "notificationsLastScheduledDate"
        static let geofencingEnabled = "geofencingEnabled"
        static let autoClockInEnabled = "autoClockInEnabled"
        static let autoClockOutEnabled = "autoClockOutEnabled"
        static let breakStartReminderEnabled = "breakStartReminderEnabled"
        static let breakEndReminderEnabled = "breakEndReminderEnabled"
        static let sessionConfirmedAtWorkplace = "sessionConfirmedAtWorkplace"
        static let isOnAwayBreak = "isOnAwayBreak"
        static let hourlyRate = "hourlyRate"
        static let overtimeRateMultiplier = "overtimeRateMultiplier"
        static let currencyCode = "currencyCode"
        static let timeRoundingMinutes = "timeRoundingMinutes"
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

    var geofencingEnabled: Bool {
        get {
            defaults.bool(forKey: Keys.geofencingEnabled)
        }
        set {
            defaults.set(newValue, forKey: Keys.geofencingEnabled)
        }
    }

    var autoClockInEnabled: Bool {
        get {
            defaults.bool(forKey: Keys.autoClockInEnabled)
        }
        set {
            defaults.set(newValue, forKey: Keys.autoClockInEnabled)
        }
    }

    var autoClockOutEnabled: Bool {
        get {
            defaults.bool(forKey: Keys.autoClockOutEnabled)
        }
        set {
            defaults.set(newValue, forKey: Keys.autoClockOutEnabled)
        }
    }

    /// Whether to send a reminder 15 minutes before a break window starts.
    var breakStartReminderEnabled: Bool {
        get {
            defaults.bool(forKey: Keys.breakStartReminderEnabled)
        }
        set {
            defaults.set(newValue, forKey: Keys.breakStartReminderEnabled)
        }
    }

    /// Whether to send a reminder 15 minutes before a break window ends.
    var breakEndReminderEnabled: Bool {
        get {
            defaults.bool(forKey: Keys.breakEndReminderEnabled)
        }
        set {
            defaults.set(newValue, forKey: Keys.breakEndReminderEnabled)
        }
    }

    // MARK: - Pay & Rounding

    /// The user's hourly pay rate, or 0 when earnings tracking is not set up.
    var hourlyRate: Double {
        get {
            defaults.double(forKey: Keys.hourlyRate)
        }
        set {
            defaults.set(newValue, forKey: Keys.hourlyRate)
        }
    }

    /// Multiplier applied to the hourly rate for overtime (e.g. 1.25 or 1.5).
    var overtimeRateMultiplier: Double {
        get {
            let value = defaults.double(forKey: Keys.overtimeRateMultiplier)
            return value > 0 ? value : 1.0
        }
        set {
            defaults.set(newValue, forKey: Keys.overtimeRateMultiplier)
        }
    }

    /// ISO 4217 currency code used to display earnings.
    var currencyCode: String {
        get {
            defaults.string(forKey: Keys.currencyCode)
                ?? Locale.current.currency?.identifier
                ?? "USD"
        }
        set {
            defaults.set(newValue, forKey: Keys.currencyCode)
        }
    }

    /// Whether the user has set up earnings tracking.
    var isEarningsTrackingEnabled: Bool {
        hourlyRate > 0
    }

    /// Rounding interval in minutes applied to clock-in/out times in exports
    /// and earnings calculations, or 0 when rounding is off. Times are always
    /// rounded to the nearest interval; stored times are never modified.
    var timeRoundingMinutes: Int {
        get {
            defaults.integer(forKey: Keys.timeRoundingMinutes)
        }
        set {
            defaults.set(newValue, forKey: Keys.timeRoundingMinutes)
        }
    }

    // MARK: - Geofencing Session State

    // These are runtime state rather than user preferences, persisted here so
    // that background relaunches (geofence events) do not lose them.

    /// Whether the current session is known to be at a workplace.
    var sessionConfirmedAtWorkplace: Bool {
        get {
            defaults.bool(forKey: Keys.sessionConfirmedAtWorkplace)
        }
        set {
            defaults.set(newValue, forKey: Keys.sessionConfirmedAtWorkplace)
        }
    }

    /// Whether the current break started because the user left the workplace.
    var isOnAwayBreak: Bool {
        get {
            defaults.bool(forKey: Keys.isOnAwayBreak)
        }
        set {
            defaults.set(newValue, forKey: Keys.isOnAwayBreak)
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

    /// Convenience: returns `DateComponents` (hour + minute) for the stored clock-out time.
    var clockOutReminderTimeComponents: DateComponents {
        let totalSeconds = Int(clockOutReminderTime)
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
            Keys.clockInReminderEnabled: false,
            Keys.clockOutReminderEnabled: false,
            Keys.clockInReminderTime: 8 * 3600,
            Keys.clockOutReminderTime: 17 * 3600,
            Keys.geofencingEnabled: false,
            Keys.autoClockInEnabled: true,
            Keys.autoClockOutEnabled: true,
            Keys.breakStartReminderEnabled: false,
            Keys.breakEndReminderEnabled: false,
            Keys.sessionConfirmedAtWorkplace: false,
            Keys.isOnAwayBreak: false,
            Keys.hourlyRate: 0.0,
            Keys.overtimeRateMultiplier: 1.0,
            Keys.timeRoundingMinutes: 0
        ])
    }
}
