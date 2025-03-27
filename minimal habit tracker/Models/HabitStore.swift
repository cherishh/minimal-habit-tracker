import Foundation
import Combine
import WidgetKit
import UIKit

class HabitStore: ObservableObject {
    // 添加单例支持，便于Intent访问
    static let shared = HabitStore()
    
    @Published var habits: [Habit] = []
    @Published var habitLogs: [HabitLog] = []
    @Published var debugMode: Bool = false {
        didSet {
            sharedDefaults.set(debugMode, forKey: debugModeKey)
        }
    }
    @Published var isPro: Bool = false {
        didSet {
            sharedDefaults.set(isPro, forKey: isProKey)
        }
    }
    @Published var appLanguage: String = "" {
        didSet {
            sharedDefaults.set(appLanguage, forKey: appLanguageKey)
            NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
        }
    }
    
    private let habitsKey = "habits"
    private let habitLogsKey = "habitLogs"
    private let debugModeKey = "debugMode"
    private let isProKey = "isPro"
    private let appLanguageKey = "appLanguage"
    
    // 使用 App Group 的 UserDefaults 来共享数据
    private let sharedDefaults = UserDefaults(suiteName: "group.com.xi.HabitTracker.minimal-habit-tracker") ?? UserDefaults.standard
    
    // 定义常量
    static let maxHabitCount = 6 // 最大习惯数量
    static let maxCheckInCount = 5 // 最大打卡次数
    
    // 防止递归调用
    private var isSaving = false
    
    init() {
        print("【HabitStore】初始化HabitStore实例")
        // 加载 Pro 和 Debug 状态
        debugMode = sharedDefaults.bool(forKey: debugModeKey)
        isPro = sharedDefaults.bool(forKey: isProKey)
        
        // 加载语言设置
        if let savedLanguage = sharedDefaults.string(forKey: appLanguageKey) {
            appLanguage = savedLanguage
        } else {
            // 首次启动时默认为空字符串，表示跟随系统
            appLanguage = ""
            sharedDefaults.set(appLanguage, forKey: appLanguageKey)
        }
        
        loadData()
    }
    
    // MARK: - Habits 操作
    
    func addHabit(_ habit: Habit) {
        // 检查是否已达到最大习惯数量且不是Pro用户或Debug模式
        if !canAddHabit() {
            return
        }
        
        // 添加新习惯
        habits.append(habit)
        
        // 立即保存数据并刷新小组件
        saveData()
        refreshWidgets()
        
        // 发送通知
        objectWillChange.send()
    }
    
    // 检查是否可以添加新习惯
    func canAddHabit() -> Bool {
        return debugMode || isPro || habits.count < HabitStore.maxHabitCount
    }
    
    func removeHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        // 同时删除相关的日志
        habitLogs.removeAll { $0.habitId == habit.id }
        
        // 清除使用该习惯的 Widget 配置
        cleanupWidgetsForDeletedHabit(habitId: habit.id)
        
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
    
    func moveHabit(from source: IndexSet, to destination: Int) {
        habits.move(fromOffsets: source, toOffset: destination)
        saveData()
        refreshWidgets()
    }
    
    // 更新习惯顺序
    func updateHabitOrder(_ newHabits: [Habit]) {
        // 检查数量是否一致，避免数据丢失
        if newHabits.count == habits.count {
            habits = newHabits
            saveData()
            refreshWidgets()
        }
    }
    
    // MARK: - Habit Logs 操作
    
    func logHabit(habitId: UUID, date: Date) {
        print("【HabitStore】开始执行logHabit - habitId: \(habitId), date: \(date)")
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let normalizedDate = calendar.date(from: dateComponents)!
        
        // 查找对应的习惯
        guard let habit = habits.first(where: { $0.id == habitId }) else {
            print("【HabitStore】找不到指定习惯")
            return
        }
        
        print("【HabitStore】找到习惯 - 名称: \(habit.name), 类型: \(habit.habitType), 最大打卡次数: \(habit.maxCheckInCount)")
        
        // 在修改前先读取当前的日志状态
        print("【HabitStore】内存中当前日志数量: \(habitLogs.count)")
        
        if let existingLogIndex = habitLogs.firstIndex(where: { log in
            log.habitId == habitId && calendar.isDate(log.date, inSameDayAs: normalizedDate)
        }) {
            // 根据习惯类型更新现有记录
            let currentCount = habitLogs[existingLogIndex].count
            print("【HabitStore】找到该习惯的现有日志 - 当前次数: \(currentCount)")
            
            switch habit.habitType {
            case .checkbox:
                // 对于checkbox类型，第二次点击会取消记录
                if currentCount > 0 {
                    print("【HabitStore】Checkbox类型 - 取消打卡")
                    habitLogs.remove(at: existingLogIndex)
                }
            case .count:
                // 对于count类型，超过自定义上限时点击会清零记录
                if currentCount >= habit.maxCheckInCount {
                    print("【HabitStore】Count类型 - 达到上限，重置打卡")
                    habitLogs.remove(at: existingLogIndex)
                } else {
                    print("【HabitStore】Count类型 - 增加打卡次数")
                    habitLogs[existingLogIndex].count += 1
                }
            }
        } else {
            // 创建新记录，对于checkbox类型使用最深的颜色
            let initialCount = habit.habitType == .checkbox ? habit.maxCheckInCount : 1
            print("【HabitStore】创建新打卡记录 - 初始次数: \(initialCount)")
            let newLog = HabitLog(habitId: habitId, date: normalizedDate, count: initialCount)
            habitLogs.append(newLog)
        }
        
        print("【HabitStore】内存中更新后日志数量: \(habitLogs.count)")
        
        // 关键修改：将数据直接写入UserDefaults
        print("【HabitStore】开始保存数据到UserDefaults")
        saveData()
        
        // 额外检查：确认数据已正确写入UserDefaults
        if let logsData = sharedDefaults.data(forKey: habitLogsKey),
           let decodedLogs = try? JSONDecoder().decode([HabitLog].self, from: logsData) {
            let todayLogs = decodedLogs.filter { log in
                log.habitId == habitId && calendar.isDate(log.date, inSameDayAs: normalizedDate)
            }
            if let todayLog = todayLogs.first {
                print("【HabitStore】确认UserDefaults中已保存 - 习惯ID: \(habitId), 打卡次数: \(todayLog.count)")
            } else {
                print("【HabitStore】确认UserDefaults中该习惯今日无打卡记录")
            }
        } else {
            print("【HabitStore】无法从UserDefaults读取保存的日志数据")
        }
        
        refreshWidgets()
        print("【HabitStore】已刷新Widgets")
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
    func refreshWidgets() {
        // 刷新所有 Widget
        print("【HabitStore】正在刷新所有Widget")
        
        // 强制写入一个时间戳到UserDefaults，确保Widget检测到变化
        let timestamp = Date().timeIntervalSince1970
        sharedDefaults.set(timestamp, forKey: "widget_refresh_timestamp")
        sharedDefaults.synchronize()
        
        // 延迟0.1秒后再刷新Widget，确保UserDefaults数据已写入
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            WidgetCenter.shared.reloadAllTimelines()
            print("【HabitStore】已发送Widget刷新请求，时间戳: \(timestamp)")
        }
    }
    
    // MARK: - 数据持久化
    
    private func saveData() {
        // 防止递归调用
        if isSaving {
            print("【HabitStore】检测到递归调用saveData，已跳过")
            return
        }
        
        isSaving = true
        print("【HabitStore】开始saveData - habits: \(habits.count)个, logs: \(habitLogs.count)个")
        
        // 编码和保存 habits
        if let encoded = try? JSONEncoder().encode(habits) {
            sharedDefaults.set(encoded, forKey: habitsKey)
            print("【HabitStore】成功保存habits到UserDefaults")
        } else {
            print("【HabitStore】保存habits失败")
        }
        
        // 编码和保存 habitLogs
        if let encoded = try? JSONEncoder().encode(habitLogs) {
            sharedDefaults.set(encoded, forKey: habitLogsKey)
            print("【HabitStore】成功保存habitLogs到UserDefaults")
        } else {
            print("【HabitStore】保存habitLogs失败")
        }
        
        // 强制UserDefaults立即同步
        sharedDefaults.synchronize()
        print("【HabitStore】已调用synchronize强制同步UserDefaults")
        
        // 确保数据变化通知发送给观察者
        DispatchQueue.main.async {
            self.objectWillChange.send()
            print("【HabitStore】已发送objectWillChange通知")
        }
        
        // 刷新所有小组件
        refreshWidgets()
        
        isSaving = false
    }
    
    private func loadData() {
        print("【HabitStore】开始loadData")
        // 解码和加载 habits
        if let data = sharedDefaults.data(forKey: habitsKey),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            self.habits = decoded
            print("【HabitStore】成功从UserDefaults加载habits: \(habits.count)个")
        } else {
            self.habits = []
            print("【HabitStore】从UserDefaults加载habits失败，使用空数组")
        }
        
        // 解码和加载 habitLogs
        if let data = sharedDefaults.data(forKey: habitLogsKey),
           let decoded = try? JSONDecoder().decode([HabitLog].self, from: data) {
            self.habitLogs = decoded
            print("【HabitStore】成功从UserDefaults加载habitLogs: \(habitLogs.count)个")
        } else {
            self.habitLogs = []
            print("【HabitStore】从UserDefaults加载habitLogs失败，使用空数组")
        }
    }
    
    // 添加主动刷新方法，供主应用调用
    func reloadData() {
        print("【HabitStore】主动调用reloadData刷新数据")
        loadData()
        objectWillChange.send()
    }
    
    // 调整习惯记录的打卡次数（当用户减少打卡次数上限时）
    func adjustLogCounts(habitId: UUID, newMaxCount: Int) {
        // 获取所有相关的打卡记录
        for index in habitLogs.indices {
            if habitLogs[index].habitId == habitId && habitLogs[index].count > newMaxCount {
                // 如果打卡次数超过新上限，则调整为新上限
                habitLogs[index].count = newMaxCount
            }
        }
        
        // 保存更新后的数据
        saveData()
        refreshWidgets()
    }
    
    // 公开方法，用于导入导出功能
    func saveDataForExport() {
        print("【HabitStore】导入导出功能调用保存数据")
        saveData()
    }
    
    // 检查是否可以使用高级主题
    func canUseProTheme(_ themeName: Habit.ColorThemeName) -> Bool {
        let basicThemes: [Habit.ColorThemeName] = [.github, .blueOcean, .sunset]
        return debugMode || isPro || basicThemes.contains(themeName)
    }
    
    // 切换 Debug 模式
    func toggleDebugMode() {
        debugMode.toggle()
        if !debugMode {
            // 关闭 debug 模式时，清除购买状态
            isPro = false
        }
        objectWillChange.send()
    }
    
    // 升级到 Pro 版本
    func upgradeToPro() {
        isPro = true
        objectWillChange.send()
    }
    
    // MARK: - Widget 配置清理
    
    /// 清除使用被删除习惯的 Widget 配置
    private func cleanupWidgetsForDeletedHabit(habitId: UUID) {
        print("【HabitStore】清理使用已删除习惯的Widget配置: \(habitId.uuidString)")
        
        // 删除后，我们只需刷新所有 Widget
        // Widget 数据提供者会自动处理找不到配置的习惯的情况
        // 延迟刷新确保数据已保存
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // 强制刷新所有 Widget，确保数据一致性
            WidgetCenter.shared.reloadAllTimelines()
            print("【HabitStore】强制刷新所有 Widget")
        }
    }
    
    // 设置应用语言
    func setAppLanguage(_ language: String) {
        appLanguage = language
        objectWillChange.send()
    }
} 