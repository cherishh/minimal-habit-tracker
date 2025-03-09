import Foundation
import Combine

class HabitStore: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var habitLogs: [HabitLog] = []
    
    private let habitsKey = "habits"
    private let habitLogsKey = "habitLogs"
    
    // 定义最大习惯数量常量
    static let maxHabitCount = 4
    
    init() {
        loadData()
    }
    
    // MARK: - Habits 操作
    
    func addHabit(_ habit: Habit) {
        // 检查是否已达到最大习惯数量
        guard habits.count < HabitStore.maxHabitCount else {
            return
        }
        
        habits.append(habit)
        saveData()
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
    }
    
    func updateHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
            saveData()
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
    
    // MARK: - 持久化
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: habitsKey)
        }
        
        if let encoded = try? JSONEncoder().encode(habitLogs) {
            UserDefaults.standard.set(encoded, forKey: habitLogsKey)
        }
    }
    
    private func loadData() {
        if let habitsData = UserDefaults.standard.data(forKey: habitsKey),
           let decodedHabits = try? JSONDecoder().decode([Habit].self, from: habitsData) {
            habits = decodedHabits
        }
        
        if let logsData = UserDefaults.standard.data(forKey: habitLogsKey),
           let decodedLogs = try? JSONDecoder().decode([HabitLog].self, from: logsData) {
            habitLogs = decodedLogs
        }
    }
} 