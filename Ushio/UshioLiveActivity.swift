//
//  UshioLiveActivity.swift
//  Ushio
//
//  Created by シン・ジャスティン on 2024/12/09.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct UshioAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct UshioLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: UshioAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension UshioAttributes {
    fileprivate static var preview: UshioAttributes {
        UshioAttributes(name: "World")
    }
}

extension UshioAttributes.ContentState {
    fileprivate static var smiley: UshioAttributes.ContentState {
        UshioAttributes.ContentState(emoji: "😌")
     }

     fileprivate static var starEyes: UshioAttributes.ContentState {
         UshioAttributes.ContentState(emoji: "😊")
     }
}

#Preview("Notification", as: .content, using: UshioAttributes.preview) {
   UshioLiveActivity()
} contentStates: {
    UshioAttributes.ContentState.smiley
    UshioAttributes.ContentState.starEyes
}
