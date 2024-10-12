//
//  Project.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2024/10/11.
//

import Foundation
import SwiftData

@Model
final class Project {
    var id: String = UUID().uuidString
    var name: String?
    var isDeleted: Bool = false

    init(name: String) {
        self.name = name
    }
}
