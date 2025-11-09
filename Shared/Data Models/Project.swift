//
//  Project.swift
//  WorkingHour
//
//  Created by Copilot on 2025/11/09.
//

import Foundation
import SwiftData

@Model
final class Project {
    var id: String = UUID().uuidString
    var name: String
    var createdAt: Date
    
    init(name: String) {
        self.name = name
        self.createdAt = .now
    }
}
