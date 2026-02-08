//
//  Project.swift
//  WorkingHour
//
//  Created by Assistant on 2026/02/07.
//

import Foundation
import SwiftData

@Model
final class Project: Identifiable {
    var id: String = UUID().uuidString
    var name: String = ""
    var createdAt: Date = Date.now
    var isActive: Bool = true

    init(name: String = "") {
        self.name = name
    }
}
