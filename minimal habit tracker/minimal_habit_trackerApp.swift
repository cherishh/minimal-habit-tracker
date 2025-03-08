//
//  minimal_habit_trackerApp.swift
//  minimal habit tracker
//
//  Created by 王仲玺 on 2025/3/6.
//

import SwiftUI

@main
struct minimal_habit_trackerApp: App {
    @StateObject private var habitStore = HabitStore()
    @StateObject private var languageManager = LanguageManager.shared
    
    init() {
        // 在应用启动时打印语言设置信息，便于调试
        print("系统偏好语言列表: \(Locale.preferredLanguages)")
        print("当前应用语言: \(languageManager.currentLanguage)")
        print("Bundle本地化列表: \(Bundle.main.localizations)")
        
        // 确保应用使用正确的语言资源
        let _ = languageManager.systemLanguage
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(habitStore)
                .environmentObject(languageManager)
                .preferredColorScheme(.none) // 允许系统自动切换明暗模式
        }
    }
}
