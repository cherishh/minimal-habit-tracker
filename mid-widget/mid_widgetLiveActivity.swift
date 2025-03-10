#if false // 暂时禁用这个文件的编译
//
//  mid_widgetLiveActivity.swift
//  mid-widget
//
//  Created by 王仲玺 on 2025/3/10.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct mid_widgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct mid_widgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: mid_widgetAttributes.self) { context in
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

extension mid_widgetAttributes {
    fileprivate static var preview: mid_widgetAttributes {
        mid_widgetAttributes(name: "World")
    }
}

extension mid_widgetAttributes.ContentState {
    fileprivate static var smiley: mid_widgetAttributes.ContentState {
        mid_widgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: mid_widgetAttributes.ContentState {
         mid_widgetAttributes.ContentState(emoji: "🤩")
     }
}

#if DEBUG
struct mid_widgetLiveActivity_Previews: PreviewProvider {
    static var previews: some View {
        mid_widgetAttributes.ContentState.smiley
            .previewContext(mid_widgetAttributes(name: "World"))
            .previewDisplayName("Smiley")
            
        mid_widgetAttributes.ContentState.starEyes
            .previewContext(mid_widgetAttributes(name: "World"))
            .previewDisplayName("Star Eyes")
    }
}
#endif

#endif // 结束条件编译
