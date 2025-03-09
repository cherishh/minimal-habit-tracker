import Foundation
import Combine

class HabitStore: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var habitLogs: [HabitLog] = []
    
    private let habitsKey = "habits"
    private let habitLogsKey = "habitLogs"
    
    init() {
        loadData()
    }
    
    // MARK: - Habits 操作
    
    func addHabit(_ habit: Habit) {
        habits.append(habit)
        saveData()
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