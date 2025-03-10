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
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(habitStore)
                .onOpenURL { url in
                    handleURL(url)
                }
                .preferredColorScheme(isDarkMode ? .dark : .light) // 使用用户设置的主题模式
        }
    }
    
    // 处理从 Widget 打开的 URL
    private func handleURL(_ url: URL) {
        guard url.scheme == "easyhabit" else { return }
        
        // 解析 URL 路径
        if url.host == "widget" {
            // 从 URL 查询参数中获取习惯 ID
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                  let habitIdItem = components.queryItems?.first(where: { $0.name == "habitId" }),
                  let habitIdString = habitIdItem.value,
                  let habitId = UUID(uuidString: habitIdString) else {
                return
            }
            
            if url.path == "/checkin" {
                // 执行打卡操作
                habitStore.logHabit(habitId: habitId, date: Date())
            } else if url.path == "/open" {
                // 仅打开应用，可选择跳转到习惯详情页
                if let habit = habitStore.habits.first(where: { $0.id == habitId }) {
                    // 通过通知中心发送消息，触发导航到详情页
                    NotificationCenter.default.post(name: NSNotification.Name("NavigateToDetail"), object: habit)
                }
            }
        }
    }
}
