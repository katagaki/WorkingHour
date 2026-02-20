//
//  HomeWidget.swift
//  Ushio
//
//  Created by シン・ジャスティン on 2026/02/20.
//

import SwiftUI
import WidgetKit

struct UshioHomeWidget: Widget {
    let kind: String = "com.tsubuzaki.WorkingHour.Ushio.Home"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HomeWidgetProvider()) { entry in
            HomeWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Widget.DisplayName")
        .description("Widget.Description")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    UshioHomeWidget()
} timeline: {
    HomeWidgetEntry.placeholder
    HomeWidgetEntry.empty
}

#Preview(as: .systemMedium) {
    UshioHomeWidget()
} timeline: {
    HomeWidgetEntry.placeholder
    HomeWidgetEntry.empty
}
