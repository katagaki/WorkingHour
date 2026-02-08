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
                Label("Clock In", image: .clockIn)
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
                Label("Clock Out", image: .clockOut)
            }
        }
        .displayName("Clock Out")
        .description("End the current work session")
    }
}
