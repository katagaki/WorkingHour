//
//  Controls.swift
//  Ushio
//
//  Created by シン・ジャスティン on 2024/12/09.
//

import SwiftUI
import WidgetKit

struct StartWorkSessionControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.tsubuzaki.WorkingHour.Ushio.Start"
        ) {
            ControlWidgetButton(action: StartWorkSessionIntent()) {
                Label("Clock In", systemImage: "figure.walk.arrival")
            }
        }
        .displayName("Clock In")
        .description("Start a new work session")
    }
}

struct EndWorkSessionControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.tsubuzaki.WorkingHour.Ushio.End"
        ) {
            ControlWidgetButton(action: EndWorkSessionIntent()) {
                Label("Clock Out", systemImage: "figure.walk.departure")
            }
        }
        .displayName("Clock Out")
        .description("End the current work session")
    }
}
