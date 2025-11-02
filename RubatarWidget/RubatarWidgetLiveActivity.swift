//
//  RubatarWidgetLiveActivity.swift
//  RubatarWidget
//
//  Created by Meghdad Abbaszadegan on 11/1/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct RubatarWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct RubatarWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RubatarWidgetAttributes.self) { context in
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

extension RubatarWidgetAttributes {
    fileprivate static var preview: RubatarWidgetAttributes {
        RubatarWidgetAttributes(name: "World")
    }
}

extension RubatarWidgetAttributes.ContentState {
    fileprivate static var smiley: RubatarWidgetAttributes.ContentState {
        RubatarWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: RubatarWidgetAttributes.ContentState {
         RubatarWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: RubatarWidgetAttributes.preview) {
   RubatarWidgetLiveActivity()
} contentStates: {
    RubatarWidgetAttributes.ContentState.smiley
    RubatarWidgetAttributes.ContentState.starEyes
}
