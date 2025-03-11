//
//  minimal_habit_trackerApp.swift
//  minimal habit tracker
//
//  Created by 王仲玺 on 2025/3/6.
//

import SwiftUI
import WidgetKit

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
                .onAppear {
                    print("📱 App 已启动")
                    setupObservers()
                }
        }
    }
    
    private func setupObservers() {
        // 监听 Widget 操作完成的通知
        NotificationCenter.default.addObserver(
            forName: Notification.Name("WidgetCheckInCompleted"),
            object: nil,
            queue: .main
        ) { notification in
            print("📣 收到 Widget 打卡完成通知")
            if let habitId = notification.object as? UUID {
                print("📣 习惯ID: \(habitId)")
            }
            // 强制刷新 Widget 以更新视图
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // 处理从 Widget 打开的 URL
    private func handleURL(_ url: URL) {
        print("📲 收到 URL 请求: \(url.absoluteString)")
        
        // 检查 URL scheme
        guard url.scheme == "easyhabit" else {
            print("❌ URL scheme 不匹配: \(url.scheme ?? "nil")")
            return
        }
        
        print("✅ URL scheme 匹配: easyhabit")
        print("📊 URL 组件: host=\(url.host ?? "nil"), path=\(url.path)")
        
        // 详细记录 URL 查询参数
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            if let queryItems = components.queryItems {
                print("📊 URL 查询参数:")
                for item in queryItems {
                    print("    - \(item.name): \(item.value ?? "nil")")
                }
            } else {
                print("📊 URL 无查询参数")
            }
        }
        
        // 解析 URL 路径
        if url.host == "widget" {
            // 从 URL 查询参数中获取习惯 ID
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                  let habitIdItem = components.queryItems?.first(where: { $0.name == "habitId" }),
                  let habitIdString = habitIdItem.value,
                  let habitId = UUID(uuidString: habitIdString) else {
                print("❌ URL 参数解析失败")
                return
            }
            
            print("✅ 解析到习惯ID: \(habitIdString)")
            
            // 检查习惯ID是否存在
            guard habitStore.habits.contains(where: { $0.id == habitId }) else {
                print("❌ 习惯ID不存在于 habitStore 中")
                return
            }
            
            if url.path == "/checkin" {
                print("🔄 执行打卡操作")
                // 执行打卡操作
                habitStore.logHabit(habitId: habitId, date: Date())
                print("✅ 打卡操作完成")
                
                // 发送 Widget 打卡完成通知
                NotificationCenter.default.post(
                    name: Notification.Name("WidgetCheckInCompleted"), 
                    object: habitId
                )
                print("📣 已发送 Widget 打卡完成通知")
                
                // 发送通知表示数据已更新
                NotificationCenter.default.post(
                    name: Notification.Name("WidgetDataUpdated"), 
                    object: nil
                )
                print("📣 已发送 Widget 数据更新通知")
                
                // 刷新 Widget
                WidgetCenter.shared.reloadAllTimelines()
                print("🔄 已请求刷新所有 Widget")
                
            } else if url.path == "/open" {
                print("📱 打开习惯详情")
                // 仅打开应用，可选择跳转到习惯详情页
                if let habit = habitStore.habits.first(where: { $0.id == habitId }) {
                    // 通过通知中心发送消息，触发导航到详情页
                    NotificationCenter.default.post(name: NSNotification.Name("NavigateToDetail"), object: habit)
                    print("✅ 已发送导航到详情页的通知")
                } else {
                    print("❌ 未找到匹配的习惯")
                }
            } else {
                print("❓ 未知的 URL 路径: \(url.path)")
            }
        } else {
            print("❌ 未知的 URL host: \(url.host ?? "nil")")
        }
    }
}
