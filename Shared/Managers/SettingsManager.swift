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

    // MARK: - Initialization

    private init() {
        // Register defaults for first launch
        defaults.register(defaults: [
            Keys.standardWorkingHours: 8 * 3600,
            Keys.defaultBreakDuration: 3600,
            Keys.autoAddBreakTime: false
        ])
    }
}
