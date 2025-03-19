//
//  minimal_habit_trackerApp.swift
//  minimal habit tracker
//
//  Created by 王仲玺 on 2025/3/6.
//

import SwiftUI

@main
struct minimal_habit_trackerApp: App {
    // 使用shared单例
    @StateObject private var habitStore = HabitStore.shared
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(habitStore)
                .onOpenURL { url in
                    print("【App】通过URL打开: \(url)")
                    handleURL(url)
                }
                .preferredColorScheme(isDarkMode ? .dark : .light)
                // 优化前台刷新逻辑，避免频繁刷新
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    print("【App】应用即将进入前台，刷新数据")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        habitStore.reloadData()
                    }
                }
                .onAppear {
                    // 应用初始化时的日志
                    print("【App】应用初始化，当前habits: \(habitStore.habits.count)个，logs: \(habitStore.habitLogs.count)个")
                }
        }
    }
    
    // 处理从 Widget 打开的 URL
    private func handleURL(_ url: URL) {
        // 支持新的URL scheme
        guard url.scheme == "easyhabit" || url.scheme == "habittracker" else { return }
        
        // 解析 URL 路径和参数
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let habitIdItem = components.queryItems?.first(where: { $0.name == "habitId" }),
              let habitIdString = habitIdItem.value,
              let habitId = UUID(uuidString: habitIdString) else {
            return
        }
        
        // 处理各种不同的路径和格式
        if url.path == "/checkin" || url.host == "checkin" {
            // 执行打卡操作 (旧版Widget的URL仍然支持)
            habitStore.logHabit(habitId: habitId, date: Date())
        } else if url.path == "/open" || url.host == "open" || url.path.isEmpty {
            // 仅打开应用，可选择跳转到习惯详情页
            if let habit = habitStore.habits.first(where: { $0.id == habitId }) {
                // 通过通知中心发送消息，触发导航到详情页
                NotificationCenter.default.post(name: NSNotification.Name("NavigateToDetail"), object: habit)
            }
        }
    }
}
