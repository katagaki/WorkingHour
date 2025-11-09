//
//  AppSettings.swift
//  WorkingHour
//
//  Created by Copilot on 2025/11/09.
//

import Foundation
import SwiftData

@Model
final class AppSettings {
    var id: String = UUID().uuidString
    
    // Standard working hours per day in seconds (default: 8 hours)
    var standardWorkingTimeInSeconds: TimeInterval = 28800.0
    
    // Default break time in seconds (default: 1 hour)
    var defaultBreakTimeInSeconds: TimeInterval = 3600.0
    
    // Whether to add break time by default
    var addBreakTimeByDefault: Bool = false
    
    init() {}
    
    init(standardWorkingTimeInSeconds: TimeInterval, defaultBreakTimeInSeconds: TimeInterval, addBreakTimeByDefault: Bool = false) {
        self.standardWorkingTimeInSeconds = standardWorkingTimeInSeconds
        self.defaultBreakTimeInSeconds = defaultBreakTimeInSeconds
        self.addBreakTimeByDefault = addBreakTimeByDefault
    }
    
    func standardWorkingTimeString() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .full
        return formatter.string(from: standardWorkingTimeInSeconds) ?? ""
    }
    
    func defaultBreakTimeString() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .full
        return formatter.string(from: defaultBreakTimeInSeconds) ?? ""
    }
}
