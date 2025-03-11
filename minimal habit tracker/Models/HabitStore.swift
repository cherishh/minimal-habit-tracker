import Foundation
import Combine
import WidgetKit
import UIKit

class HabitStore: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var habitLogs: [HabitLog] = []
    
    private let habitsKey = "habits"
    private let habitLogsKey = "habitLogs"
    
    // 使用 App Group 的 UserDefaults 来共享数据
    private let sharedDefaults = UserDefaults(suiteName: "group.com.xi.HabitTracker.minimal-habit-tracker") ?? UserDefaults.standard
    
    // 定义最大习惯数量常量
    static let maxHabitCount = 10
    
    // 添加一个跟踪最后一次从Widget收到更新的时间戳
    private var lastWidgetUpdateTimestamp: Double = 0
    
    init() {
        // 加载已保存的数据
        loadData()
        
        // 设置通知监听器，以便检测应用进入前台时更新数据
        setupObservers()
    }
    
    private func setupObservers() {
        // 监听应用进入前台的通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // 监听UserDefaults变化，用于检测Widget的更新
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDefaultsDidChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }
    
    @objc private func appWillEnterForeground() {
        // 当应用进入前台时，检查Widget是否更新了数据
        checkForWidgetUpdates()
    }
    
    @objc private func userDefaultsDidChange(_ notification: Notification) {
        // 当UserDefaults变化时，检查是否由Widget更新了数据
        checkForWidgetUpdates()
    }
    
    private func checkForWidgetUpdates() {
        // 获取shared UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.com.xi.HabitTracker.minimal-habit-tracker") ?? UserDefaults.standard
        
        // 检查Widget更新时间戳
        let updateTimestampKey = "widgetDataUpdateTimestamp"
        let currentTimestamp = sharedDefaults.double(forKey: updateTimestampKey)
        
        // 如果时间戳比上次记录的更新，则重新加载数据
        if currentTimestamp > lastWidgetUpdateTimestamp && currentTimestamp > 0 {
            lastWidgetUpdateTimestamp = currentTimestamp
            
            // 重新加载数据
            loadData()
            
            // 发出通知，表示已从Widget更新数据
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: Notification.Name("WidgetDataSynced"),
                    object: nil
                )
            }
        }
    }
    
    // MARK: - Habits 操作
    
    func addHabit(_ habit: Habit) {
        // 检查是否已达到最大习惯数量
        guard habits.count < HabitStore.maxHabitCount else {
            return
        }
        
        habits.append(habit)
        saveData()
        refreshWidgets()
    }
    
    // 检查是否可以添加新习惯
    func canAddHabit() -> Bool {
        return habits.count < HabitStore.maxHabitCount
    }
    
    func removeHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        // 同时删除相关的日志
        habitLogs.removeAll { $0.habitId == habit.id }
        saveData()
        refreshWidgets()
    }
    
    func updateHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
            saveData()
            refreshWidgets()
        }
    }
    
    // MARK: - Habit Logs 操作
    
    func logHabit(habitId: UUID, date: Date) {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let normalizedDate = calendar.date(from: dateComponents)!
        
        // 查找对应的习惯
        guard let habit = habits.first(where: { $0.id == habitId }) else { return }
        
        if let existingLogIndex = habitLogs.firstIndex(where: { log in
            log.habitId == habitId && calendar.isDate(log.date, inSameDayAs: normalizedDate)
        }) {
            // 根据习惯类型更新现有记录
            let currentCount = habitLogs[existingLogIndex].count
            
            switch habit.habitType {
            case .checkbox:
                // 对于checkbox类型，第二次点击会取消记录
                if currentCount > 0 {
                    habitLogs.remove(at: existingLogIndex)
                }
            case .count:
                // 对于count类型，第5次点击会清零记录
                if currentCount >= 4 {
                    habitLogs.remove(at: existingLogIndex)
                } else {
                    habitLogs[existingLogIndex].count += 1
                }
            }
        } else {
            // 创建新记录，对于checkbox类型使用最深的颜色(count=4)
            let initialCount = habit.habitType == .checkbox ? 4 : 1
            let newLog = HabitLog(habitId: habitId, date: normalizedDate, count: initialCount)
            habitLogs.append(newLog)
        }
        
        saveData()
        refreshWidgets()
    }
    
    func getLogCountForDate(habitId: UUID, date: Date) -> Int {
        let calendar = Calendar.current
        
        if let log = habitLogs.first(where: { log in
            log.habitId == habitId && calendar.isDate(log.date, inSameDayAs: date)
        }) {
            return log.count
        }
        
        return 0
    }
    
    // 获取习惯打卡总天数
    func getTotalLoggedDays(habitId: UUID) -> Int {
        return habitLogs.filter { $0.habitId == habitId }.count
    }
    
    // 获取习惯最长连续打卡天数
    func getLongestStreak(habitId: UUID) -> Int {
        let filteredLogs = habitLogs.filter { $0.habitId == habitId }
        guard !filteredLogs.isEmpty else { return 0 }
        
        // 按日期排序
        let sortedDates = filteredLogs.map { $0.date }.sorted()
        
        let calendar = Calendar.current
        var currentStreak = 1
        var longestStreak = 1
        
        for i in 1..<sortedDates.count {
            let previousDate = sortedDates[i-1]
            let currentDate = sortedDates[i]
            
            // 检查是否为连续日期
            let dayDifference = calendar.dateComponents([.day], from: previousDate, to: currentDate).day ?? 0
            
            if dayDifference == 1 {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else if dayDifference > 1 {
                currentStreak = 1
            }
        }
        
        return longestStreak
    }
    
    // MARK: - Widget 刷新
    
    /// 刷新所有相关的 Widget
    private func refreshWidgets() {
        #if canImport(WidgetKit)
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
        #endif
    }
    
    // MARK: - 持久化
    
    func saveData() {
        // 获取shared UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.com.xi.HabitTracker.minimal-habit-tracker") ?? UserDefaults.standard
        
        do {
            // 保存习惯列表
            let habitsData = try JSONEncoder().encode(habits)
            sharedDefaults.set(habitsData, forKey: habitsKey)
            
            // 保存习惯日志
            let habitLogsData = try JSONEncoder().encode(habitLogs)
            sharedDefaults.set(habitLogsData, forKey: habitLogsKey)
            
            // 更新时间戳，标记数据已经更新
            let updateTimestampKey = "widgetDataUpdateTimestamp"
            lastWidgetUpdateTimestamp = Date().timeIntervalSince1970
            sharedDefaults.set(lastWidgetUpdateTimestamp, forKey: updateTimestampKey)
            
            // 同步确保数据写入
            sharedDefaults.synchronize()
            
            // 确保数据变化通知发送给观察者
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
            
            // 刷新所有Widget
            refreshWidgets()
        } catch {
            print("保存数据失败: \(error)")
        }
    }
    
    private func loadData() {
        // 从共享的 UserDefaults 加载数据
        if let habitsData = sharedDefaults.data(forKey: habitsKey),
           let decodedHabits = try? JSONDecoder().decode([Habit].self, from: habitsData) {
            habits = decodedHabits
        }
        
        if let logsData = sharedDefaults.data(forKey: habitLogsKey),
           let decodedLogs = try? JSONDecoder().decode([HabitLog].self, from: logsData) {
            habitLogs = decodedLogs
        }
    }
} 