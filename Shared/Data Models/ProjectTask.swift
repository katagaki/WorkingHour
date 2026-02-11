//
//  ProjectTask.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2026/02/11.
//

import Foundation
import SwiftData

@Model
final class ProjectTask: Identifiable {
    var id: String = UUID().uuidString
    var taskDescription: String = ""
    var createdAt: Date = Date.now

    @Relationship(inverse: \ClockEntry.tasks)
    var clockEntry: ClockEntry?

    @Relationship(inverse: \Project.tasks)
    var project: Project?

    init(taskDescription: String = "", clockEntry: ClockEntry? = nil, project: Project? = nil) {
        self.taskDescription = taskDescription
        self.clockEntry = clockEntry
        self.project = project
    }
}
