//
//  minimal_habit_trackerApp.swift
//  minimal habit tracker
//
//  Created by 图蜥 on 2025/3/6.
//

import SwiftUI
import WidgetKit

@main
struct minimal_habit_trackerApp: App {
    // 使用shared单例
    @StateObject private var habitStore = HabitStore.shared
    @AppStorage("themeMode") private var themeMode: Int = 0 // 0: 自适应系统, 1: 明亮模式, 2: 暗黑模式
    
    // 用于监听语言改变的状态变量
    @State private var languageUpdateTrigger = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(habitStore)
                .onOpenURL { url in
                    print("【App】通过URL打开: \(url)")
                    handleURL(url)
                }
                .preferredColorScheme(getPreferredColorScheme())
                // 优化前台刷新逻辑，避免频繁刷新
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    print("【App】应用即将进入前台，刷新数据")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        habitStore.reloadData()
                        // 检查日期变更并更新Widget
                        checkDateChangeAndUpdateWidget()
                    }
                }
                // 监听语言变化事件
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
                    // 语言变化时刷新整个应用
                    languageUpdateTrigger.toggle()
                }
                .id(languageUpdateTrigger) // 通过ID强制刷新整个应用
                .onAppear {
                    // 应用初始化时的日志
                    print("【App】应用初始化，当前habits: \(habitStore.habits.count)个，logs: \(habitStore.habitLogs.count)个")
                    
                    // 兼容旧版本设置迁移
                    migrateOldSettings()
                }
        }
    }
    
    // 根据设置返回颜色模式
    private func getPreferredColorScheme() -> ColorScheme? {
        switch themeMode {
            case 1: return .light     // 明亮模式
            case 2: return .dark      // 暗黑模式
            default: return nil       // 自适应系统
        }
    }
    
    // 迁移旧版本的暗黑模式设置到新的主题模式
    private func migrateOldSettings() {
        // 检查是否有旧版本设置
        if UserDefaults.standard.object(forKey: "isDarkMode") != nil {
            let oldDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
            // 如果之前设置了暗黑模式，则转为对应的主题模式
            themeMode = oldDarkMode ? 2 : 1
            // 移除旧设置
            UserDefaults.standard.removeObject(forKey: "isDarkMode")
            print("【App】已将旧版主题设置迁移到新版")
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
    
    // 检查日期变更并更新Widget
    private func checkDateChangeAndUpdateWidget() {
        let sharedDefaults = UserDefaults(suiteName: "group.com.xi.HabitTracker.minimal-habit-tracker")!
        let currentDate = Calendar.current.startOfDay(for: Date())
        
        // 获取上次活跃的日期
        let lastActiveDate = sharedDefaults.object(forKey: "last_active_date") as? Date ?? Date(timeIntervalSince1970: 0)
        let lastActiveDay = Calendar.current.startOfDay(for: lastActiveDate)
        
        // 如果日期不同，刷新Widget
        if !Calendar.current.isDate(currentDate, inSameDayAs: lastActiveDay) {
            print("【App】检测到日期变更，刷新Widget")
            // 只刷新习惯追踪相关的Widget
            WidgetCenter.shared.reloadTimelines(ofKind: "HabitWidget")
        }
        
        // 更新最后活跃日期
        sharedDefaults.set(currentDate, forKey: "last_active_date")
    }
}
