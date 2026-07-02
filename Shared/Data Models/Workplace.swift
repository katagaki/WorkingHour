//
//  Workplace.swift
//  WorkingHour
//
//  Created by Assistant on 2026/02/20.
//

import Foundation
import SwiftData

@Model
final class Workplace: Identifiable {

    /// iOS region monitoring relies on coarse (cell/Wi-Fi) location in the
    /// background, which typically has 100m+ accuracy. Radii smaller than
    /// this are prone to missed, delayed, or spurious entry/exit events.
    static let minimumReliableRadius: Double = 100.0

    var id: String = UUID().uuidString
    var name: String = ""
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    /// Geofence radius in meters
    var radius: Double = 100.0
    var isEnabled: Bool = true
    var createdAt: Date = Date.now

    init(name: String, latitude: Double, longitude: Double, radius: Double = 100.0) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
    }
}
