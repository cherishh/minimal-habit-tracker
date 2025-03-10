//
//  mid_widgetBundle.swift
//  mid-widget
//
//  Created by 王仲玺 on 2025/3/10.
//

import WidgetKit
import SwiftUI

@main
struct mid_widgetBundle: WidgetBundle {
    var body: some Widget {
        // 只包含我们的习惯 Widget
        HabitWidget()
        SmartStackHabitWidget()
    }
}
