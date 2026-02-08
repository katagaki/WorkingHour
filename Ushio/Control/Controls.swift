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
                Label("TimeClock.Work.ClockIn", systemImage: "figure.walk.arrival")
            }
        }
        .displayName("TimeClock.Work.ClockIn")
        .description("TimeClock.Work.StartSession")
    }
}

struct EndWorkSessionControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.tsubuzaki.WorkingHour.Ushio.End"
        ) {
            ControlWidgetButton(action: EndWorkSessionIntent()) {
                Label("TimeClock.Work.ClockOut", systemImage: "figure.walk.departure")
            }
        }
        .displayName("TimeClock.Work.ClockOut")
        .description("TimeClock.Work.ClockOutSession")
    }
}
