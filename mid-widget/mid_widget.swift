//
//  mid_widget.swift
//  mid-widget
//
//  Created by 图蜥 on 2025/3/10.
//

import WidgetKit
import SwiftUI
import AppIntents

// 定义 Widget 的配置选项，允许用户选择要显示的习惯
struct HabitSelectionIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "选择习惯"
    static var description: IntentDescription = IntentDescription("选择要在 Widget 中显示的习惯")
    
    @Parameter(title: "习惯ID", default: "")
    var habitId: String
}

// Widget 的数据提供者
struct Provider: AppIntentTimelineProvider {
    // 定义Provider的Entry类型为HabitEntry
    typealias Entry = HabitEntry
    
    // 共享数据的 UserDefaults
    private let sharedDefaults = UserDefaults(suiteName: "group.com.xi.HabitTracker.minimal-habit-tracker") ?? UserDefaults.standard
    
    // 占位视图的数据
    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(
            date: Date(),
            habit: Habit(name: "读书", emoji: "📚", colorTheme: .github, habitType: .checkbox),
            logs: [],
            todayCount: 0,
            configuration: HabitSelectionIntent()
        )
    }
    
    // 快照视图的数据
    func snapshot(for configuration: HabitSelectionIntent, in context: Context) async -> HabitEntry {
        print("【Widget】生成snapshot，配置habitId: \(configuration.habitId)")
        
        // 检查是否是午夜更新
        let nowCalendar = Calendar.current
        let now = Date()
        let hour = nowCalendar.component(.hour, from: now)
        let minute = nowCalendar.component(.minute, from: now)
        
        if hour == 0 && minute < 10 {
            print("🌙【Widget深夜更新】时间 \(hour):\(String(format: "%02d", minute))，Widget已在午夜后更新数据")
        }
        
        // 每次都强制同步UserDefaults，确保读取到最新数据
        sharedDefaults.synchronize()
        
        // 从 UserDefaults 直接加载最新习惯数据 
        // 始终创建新实例不使用缓存
        let habitStore = loadHabitStore()
        
        // 获取选择的习惯，如果没有选择或找不到，则使用第一个习惯
        let selectedHabit: Habit
        if !configuration.habitId.isEmpty,
           let habit = habitStore.habits.first(where: { $0.id.uuidString == configuration.habitId }) {
            selectedHabit = habit
            print("【Widget】找到配置的习惯: \(habit.name)")
        } else if !habitStore.habits.isEmpty {
            selectedHabit = habitStore.habits[0]
            print("【Widget】使用第一个习惯: \(selectedHabit.name)")
        } else {
            // 如果没有习惯，使用默认习惯
            selectedHabit = Habit(name: "读书", emoji: "📚", colorTheme: .github, habitType: .checkbox)
            print("【Widget】没有找到习惯，使用默认习惯")
        }
        
        // 获取习惯的日志 - 强制从UserDefaults加载最新数据
        var logs: [HabitLog] = []
        if let logsData = sharedDefaults.data(forKey: "habitLogs"),
           let allLogs = try? JSONDecoder().decode([HabitLog].self, from: logsData) {
            logs = allLogs.filter { $0.habitId == selectedHabit.id }
            print("【Widget】snapshot直接从UserDefaults读取到\(logs.count)条该习惯的日志")
        }
        
        // 获取今天的打卡次数 - 直接计算而不是使用habitStore方法
        let calendar = Calendar.current
        let todayCount = logs.filter { 
            calendar.isDate($0.date, inSameDayAs: Date()) 
        }.first?.count ?? 0
        print("【Widget】今日打卡次数: \(todayCount)")
        
        // 返回带有最新数据的条目
        return HabitEntry(
            date: Date(),
            habit: selectedHabit,
            logs: logs,
            todayCount: todayCount,
            configuration: configuration
        )
    }
    
    // 时间线数据
    func timeline(for configuration: HabitSelectionIntent, in context: Context) async -> Timeline<HabitEntry> {
        // 强制同步UserDefaults以确保读取到最新数据
        sharedDefaults.synchronize()
        
        // 获取当前时间的快照
        let currentEntry = await snapshot(for: configuration, in: context)
        
        // 创建时间线条目数组，先添加当前条目
        var entries = [currentEntry]
        
        // 计算下一个午夜时间点（实际设为午夜后1分钟，避开系统可能的高负载时间）
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        dateComponents.day! += 1 // 明天
        dateComponents.hour = 0
        dateComponents.minute = 1
        dateComponents.second = 0
        
        if let midnightDate = calendar.date(from: dateComponents) {
            // 创建午夜更新的条目
            let midnightEntry = HabitEntry.midnightEntry(from: currentEntry, date: midnightDate)
            entries.append(midnightEntry)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZ"
            formatter.timeZone = TimeZone.current
            print("【Widget】已设置本地午夜更新时间点：\(formatter.string(from: midnightDate))")
            
            // 在午夜后请求新的时间线
            let refreshDate = midnightDate.addingTimeInterval(60) // 午夜后60秒
            return Timeline(entries: entries, policy: .after(refreshDate))
        }
        
        // 如果无法计算午夜时间，使用atEnd策略
        print("【Widget】无法计算午夜时间，使用.atEnd策略")
        return Timeline(entries: entries, policy: .atEnd)
    }
    
    // 从 UserDefaults 加载习惯数据
    private func loadHabitStore() -> HabitStore {
        print("【Widget Provider】开始loadHabitStore - 强制从UserDefaults读取")
        sharedDefaults.synchronize()
        // 创建新实例，避免使用可能未更新的共享单例
        let habitStore = HabitStore()
        
        // 直接从UserDefaults读取最新数据
        if let habitsData = sharedDefaults.data(forKey: "habits"),
           let decodedHabits = try? JSONDecoder().decode([Habit].self, from: habitsData) {
            habitStore.habits = decodedHabits
            print("【Widget Provider】直接从UserDefaults读取到\(decodedHabits.count)个习惯")
        } else {
            print("【Widget Provider】UserDefaults中没有找到习惯数据")
        }
        
        // 读取日志数据
        if let logsData = sharedDefaults.data(forKey: "habitLogs"),
           let decodedLogs = try? JSONDecoder().decode([HabitLog].self, from: logsData) {
            habitStore.habitLogs = decodedLogs
            print("【Widget Provider】直接从UserDefaults读取到\(decodedLogs.count)个日志")
        } else {
            print("【Widget Provider】UserDefaults中没有找到日志数据")
        }
        
        return habitStore
    }
}

// Widget 的数据模型
struct HabitEntry: TimelineEntry {
    let date: Date
    let habit: Habit
    let logs: [HabitLog]
    let todayCount: Int
    let configuration: HabitSelectionIntent
    var renderDate: Date // 改为var使其可变
    
    init(date: Date, habit: Habit, logs: [HabitLog], todayCount: Int, configuration: HabitSelectionIntent) {
        self.date = date
        self.habit = habit
        self.logs = logs
        self.todayCount = todayCount
        self.configuration = configuration
        self.renderDate = date // 默认使用entry的date
    }
    
    // 专门用于创建午夜更新的entry
    static func midnightEntry(from entry: HabitEntry, date: Date) -> HabitEntry {
        var newEntry = HabitEntry(
            date: date,
            habit: entry.habit,
            logs: entry.logs,
            todayCount: 0, // 新的一天从0开始
            configuration: entry.configuration
        )
        newEntry.renderDate = date // 确保使用新的日期渲染
        return newEntry
    }
}

// Widget 的视图
struct HabitWidgetEntryView: View {
    var entry: HabitEntry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // 上部分：习惯名称和连续打卡天数
            HStack {
                Text(entry.habit.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .primary.opacity(0.8) : .primary)
                    .padding(.vertical, 8) // 减小垂直内边距
                    .padding(.horizontal, 16)
                    .padding(.leading, 10)
                
                Spacer()
                
                // 获取连续打卡天数
                if let currentStreak = getStreak(habit: entry.habit, logs: entry.logs), currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundColor(colorScheme == .dark 
                                ? getTheme(habit: entry.habit).color(for: 4, isDarkMode: true)
                                : getTheme(habit: entry.habit).color(for: 5, isDarkMode: false))
                        
                        Text("\(currentStreak)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(colorScheme == .dark 
                                ? getTheme(habit: entry.habit).color(for: 4, isDarkMode: true)
                                : getTheme(habit: entry.habit).color(for: 5, isDarkMode: false))
                    }
                    .padding(.trailing, 28)
                }
            }
            .padding(.top, 16) // 增加顶部边距
            .background(colorScheme == .dark ? Color.black : Color.white)
            
            // 下部分：微型热力图和打卡按钮
            HStack(spacing: 12) {
                // 左侧：微型热力图
                Link(destination: URL(string: "habittracker://open?habitId=\(entry.habit.id.uuidString)")!) {
                    WidgetMiniHeatmapView(
                        logs: entry.logs,
                        habit: entry.habit,
                        colorScheme: colorScheme,
                        renderDate: entry.renderDate // 传递渲染日期
                    )
                    .padding(.vertical, 8)
                    .padding(.horizontal, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(colorScheme == .dark 
                                ? Color.black.opacity(0.3) 
                                : Color.white.opacity(0.3))
                    )
                    .padding(.leading, 16)
                    .padding(.top, 2) // 减小上边距
                    .padding(.bottom, 16)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // 右侧：打卡按钮
                WidgetCheckInButton(
                    habit: entry.habit,
                    todayCount: entry.todayCount,
                    colorScheme: colorScheme
                )
                .padding(.trailing, 20)
                .padding(.vertical, 8)
            }
            .background(colorScheme == .dark ? Color.black : Color.white)
        }
        .padding(.top, 8) // 增加整体顶部边距
        .padding(.bottom, 12) // 增加整体底部边距
        .cornerRadius(12)
    }
    
    // 获取习惯对应的主题颜色
    private func getTheme(habit: Habit) -> ColorTheme {
        return ColorTheme.getTheme(for: habit.colorTheme)
    }
    
    // 计算连续打卡天数
    private func getStreak(habit: Habit, logs: [HabitLog]) -> Int? {
        let calendar = Calendar.current
        let today = Date()
        var dayCount = 0
        
        // 从今天开始向前查找连续打卡的天数
        for dayOffset in 0..<77 { // 最多查找70天
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            // 查找该日期是否有打卡记录
            let logsForDate = logs.filter { calendar.isDate($0.date, inSameDayAs: date) }
            
            // 如果这天有打卡记录，增加计数
            if !logsForDate.isEmpty {
                dayCount += 1
            } else if dayOffset > 0 { // 遇到未打卡的日期且不是今天，结束计数
                break
            }
        }
        
        return dayCount
    }
}

// 微型热力图组件 - 专为 Widget 优化
struct WidgetMiniHeatmapView: View {
    let logs: [HabitLog]
    let habit: Habit
    let colorScheme: ColorScheme
    let renderDate: Date // 从外部传入的渲染日期参数
    
    // 热力图大小配置
    private let cellSize: CGFloat = 11
    private let cellSpacing: CGFloat = 3
    
    // 热力图布局配置
    private let columnsToShow = 11 // 显示11列（11周）
    private let daysInWeek = 7 // 每周7天
    
    // 获取习惯的主题颜色
    private var theme: ColorTheme {
        ColorTheme.getTheme(for: habit.colorTheme)
    }
    
    // 生成热力图日期网格，按周组织 - 每列代表一周，从周一到周日
    private var dateGrid: [[Date?]] {
        let calendar = Calendar.current
        let today = renderDate
        
        // 简化调试日志
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        // print("【Widget热力图】使用渲染日期：\(formatter.string(from: today))")
        
        // 1. 确定当前是周几（1是周日，2是周一...7是周六）
        let currentWeekday = calendar.component(.weekday, from: today)
        
        // 2. 计算到本周一的偏移量（如果今天是周一，偏移量为0）
        let daysToSubtractForCurrentWeekStart = (currentWeekday == 1) ? 6 : (currentWeekday - 2)
        
        // 3. 计算本周一的日期
        guard let currentWeekMonday = calendar.date(byAdding: .day, value: -daysToSubtractForCurrentWeekStart, to: today) else {
            return []
        }
        
        // 4. 计算需要显示的最早那周的周一（往前推 columns-1 周）
        guard let firstMonday = calendar.date(byAdding: .weekOfYear, value: -(columnsToShow - 1), to: currentWeekMonday) else {
            return []
        }
        
        // 5. 初始化一个7行（周一到周日）x 11列（11周）的二维数组
        var grid: [[Date?]] = Array(repeating: Array(repeating: nil, count: columnsToShow), count: daysInWeek)
        
        // 6. 填充日期网格
        for column in 0..<columnsToShow {
            for row in 0..<daysInWeek {
                // 计算对应的日期：从第一个周一开始，每列递增一周，每行递增一天
                // column代表第几周，row代表周几（0是周一，6是周日）
                if let date = calendar.date(byAdding: .day, value: (column * daysInWeek) + row, to: firstMonday) {
                    // 只添加不超过今天的日期
                    if date <= today {
                        grid[row][column] = date
                    }
                }
            }
        }
        
        return grid
    }
    
    // 获取指定日期的打卡次数
    private func getLogCountForDate(date: Date) -> Int {
        let calendar = Calendar.current
        
        // 只保留日期部分进行比较
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let normalizedDate = calendar.date(from: dateComponents)!
        
        // 使用标准化的日期查找匹配的日志
        let matchingLog = logs.first { log in
            let logComponents = calendar.dateComponents([.year, .month, .day], from: log.date)
            let normalizedLogDate = calendar.date(from: logComponents)!
            return normalizedLogDate == normalizedDate
        }
        
        return matchingLog?.count ?? 0
    }
    
    // 获取日期的热力图颜色 - 与主程序保持一致的逻辑
    private func getColorForDate(date: Date) -> Color {
        let count = getLogCountForDate(date: date)
        
        // 未打卡情况 - 保持原来的底色逻辑
        if count == 0 {
            return colorScheme == .dark ? theme.color(for: 0, isDarkMode: true) : Color(hex: "ebedf0")
        }
        
        // 打卡情况 - 根据习惯类型使用不同颜色逻辑
        if habit.habitType == .checkbox {
            // checkbox类型: 使用最深颜色
            return colorScheme == .dark 
                ? theme.color(for: 4, isDarkMode: true) 
                : theme.color(for: 5, isDarkMode: false)
        } else {
            // count类型: 根据打卡次数使用渐变颜色
            // 计算颜色级别: 1-5
            let level = max(1, min(5, Int(ceil(Double(count) / Double(habit.maxCheckInCount) * 4.0))))
            return colorScheme == .dark 
                ? theme.color(for: level, isDarkMode: true) 
                : theme.color(for: level, isDarkMode: false)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: cellSpacing) {
            // 每行代表星期几（0是周一，6是周日）
            ForEach(0..<daysInWeek, id: \.self) { row in
                HStack(spacing: cellSpacing) {
                    // 每列代表一周
                    ForEach(0..<columnsToShow, id: \.self) { column in
                        // 获取该位置的日期
                        if let date = dateGrid[row][column] {
                            // 使用统一的颜色获取方法
                            RoundedRectangle(cornerRadius: 2)
                                .fill(getColorForDate(date: date))
                                .frame(width: cellSize, height: cellSize)
                        } else {
                            // 没有日期的位置（例如超过今天的日期）
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.clear)
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
        .frame(height: CGFloat(daysInWeek) * (cellSize + cellSpacing) - cellSpacing)
        .frame(width: CGFloat(columnsToShow) * (cellSize + cellSpacing) + cellSpacing) // 确保宽度足够
        .id("heatmap-\(Calendar.current.startOfDay(for: renderDate))") // 使用传入的渲染日期
    }
}

// Widget 打卡按钮
struct WidgetCheckInButton: View {
    let habit: Habit
    let todayCount: Int
    let colorScheme: ColorScheme
    
    // 获取习惯对应的主题颜色
    private var theme: ColorTheme {
        ColorTheme.getTheme(for: habit.colorTheme)
    }
    
    // 判断今天是否已完成打卡
    private var isCompletedToday: Bool {
        todayCount > 0
    }
    
    // 获取计数型习惯的进度百分比 (0-1)
    private var countProgress: CGFloat {
        let count = CGFloat(todayCount)
        return min(count / CGFloat(habit.maxCheckInCount), 1.0)
    }

    var body: some View {
        Button(intent: CheckInHabitIntent(habitId: habit.id.uuidString)) {
            ZStack {
                // 圆环
                if habit.habitType == .checkbox {
                    // Checkbox型习惯的圆环 - 先显示底色轨道
                    Circle()
                        .stroke(
                            colorScheme == .dark ?
                                theme.color(for: 1, isDarkMode: true).opacity(0.7) :
                                theme.color(for: 1, isDarkMode: false).opacity(0.4),
                            style: StrokeStyle(lineWidth: 10)
                        )
                        .frame(width: 64, height: 64)
                    
                    // 完成圆环
                    Circle()
                        .trim(from: 0, to: isCompletedToday ? 1 : 0)
                        .stroke(
                            colorScheme == .dark ?
                                theme.color(for: min(habit.maxCheckInCount, 4), isDarkMode: true) :
                                theme.color(for: 5, isDarkMode: false),
                            style: StrokeStyle(
                                lineWidth: 10,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                } else {
                    // Count型习惯的圆环 - 先显示底色轨道
                    Circle()
                        .stroke(
                            colorScheme == .dark ?
                                theme.color(for: 1, isDarkMode: true).opacity(0.7) :
                                theme.color(for: 1, isDarkMode: false).opacity(0.4),
                            style: StrokeStyle(lineWidth: 10)
                        )
                        .frame(width: 64, height: 64)
                    
                    // 进度环
                    Circle()
                        .trim(from: 0, to: countProgress)
                        .stroke(
                            colorScheme == .dark ?
                                theme.color(for: min(habit.maxCheckInCount, 4), isDarkMode: true) :
                                theme.color(for: 5, isDarkMode: false),
                            style: StrokeStyle(
                                lineWidth: 10,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                }
                
                VStack(spacing: 2) {
                    // Emoji
                    Text(habit.emoji)
                        .font(.system(size: 28))
                    
                    // // 计数类型显示当前次数/最大次数
                    // if habit.habitType == .count {
                    //     Text("\(todayCount)/\(habit.maxCheckInCount)")
                    //         .font(.system(size: 12))
                    //         .foregroundColor(.secondary)
                    // }
                }
            }
        }
        .buttonStyle(.plain)
        .frame(width: 74, height: 74)
    }
}

// 打卡操作的 Intent
struct CheckInHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "打卡习惯"
    static var description: LocalizedStringResource = "记录习惯打卡"
    
    @Parameter(title: "习惯ID")
    var habitId: String
    
    @Parameter(title: "打卡日期", default: Date())
    var date: Date
    
    init() {}
    
    init(habitId: String) {
        self.habitId = habitId
        self.date = Date()
    }
    
    // 实现功能
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        print("【打卡】开始执行打卡操作，habitId: \(habitId)")
        
        // 强制使用最新日期，而不是使用传入的可能过时的date参数
        let currentDate = Date()
        
        // 检查传入日期与当前日期是否为同一天
        let calendar = Calendar.current
        let isSameDay = calendar.isDate(date, inSameDayAs: currentDate)
        if !isSameDay {
            // 如果不是同一天，打印警告并使用最新日期
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            print("⚠️【Widget打卡警告】传入日期 \(formatter.string(from: date)) 与当前日期 \(formatter.string(from: currentDate)) 不在同一天，将使用当前日期")
            
            // 更新date为当前日期
            date = currentDate
        }
        
        // 获取共享的UserDefaults实例
        var sharedDefaultsIntent = UserDefaults(suiteName: "group.com.xi.HabitTracker.minimal-habit-tracker")!
        
        // 1. 从UserDefaults读取数据
        let habitStore = HabitStore()
        
        // 读取习惯数据
        if let habitsData = sharedDefaultsIntent.data(forKey: "habits"),
           let decodedHabits = try? JSONDecoder().decode([Habit].self, from: habitsData) {
            habitStore.habits = decodedHabits
            print("【Widget】Intent直接从UserDefaults读取到\(decodedHabits.count)个习惯")
        } else {
            print("【Widget】Intent中UserDefaults没有找到习惯数据")
        }
        
        // 读取日志数据
        if let logsData = sharedDefaultsIntent.data(forKey: "habitLogs"),
           let decodedLogs = try? JSONDecoder().decode([HabitLog].self, from: logsData) {
            habitStore.habitLogs = decodedLogs
        }
        
        guard let habitUUID = UUID(uuidString: habitId),
              let habit = habitStore.habits.first(where: { $0.id == habitUUID }) else {
            // 习惯不存在，返回错误
            print("【Widget】找不到指定习惯，habitId: \(habitId)")
            return .result(dialog: "找不到指定习惯")
        }
        
        // 获取打卡前的状态 - 直接从内存中计算，不依赖habitStore方法
        let calendarForCount = Calendar.current
        let beforeCount = habitStore.habitLogs.filter { log in
            calendarForCount.isDate(log.date, inSameDayAs: date) && log.habitId == habitUUID
        }.first?.count ?? 0
        print("【Widget】打卡前习惯状态 - 名称: \(habit.name), 打卡次数: \(beforeCount)/\(habit.maxCheckInCount)")
        
        // 2. 执行打卡操作
        // 查找对应habitUUID的日志
        // 找到同一天的日志，如果存在则增加计数，否则创建新日志
        let calendarIntent = Calendar.current
        let todayLogs = habitStore.habitLogs.filter { log in
            calendarIntent.isDate(log.date, inSameDayAs: date) && log.habitId == habitUUID
        }
        
        if let existingLog = todayLogs.first {
            // 如果已有该习惯今天的日志
            let currentCount = existingLog.count
            
            // 对于checkbox类型，切换状态；对于count类型，增加计数直到达到上限后重置
            if habit.habitType == .checkbox {
                // 切换状态: 如果已打卡则取消，否则打卡
                if currentCount > 0 {
                    // 找到并删除该日志
                    if let indexToRemove = habitStore.habitLogs.firstIndex(where: { log in
                        calendarIntent.isDate(log.date, inSameDayAs: date) && log.habitId == habitUUID
                    }) {
                        habitStore.habitLogs.remove(at: indexToRemove)
                    }
                } else {
                    // 将count设为最大值（与主程序保持一致）
                    if let indexToUpdate = habitStore.habitLogs.firstIndex(where: { log in
                        calendarIntent.isDate(log.date, inSameDayAs: date) && log.habitId == habitUUID
                    }) {
                        habitStore.habitLogs[indexToUpdate].count = 5
                    }
                }
            } else {
                // 计数类型
                if currentCount >= habit.maxCheckInCount {
                    // 达到上限，重置计数
                    if let indexToRemove = habitStore.habitLogs.firstIndex(where: { log in
                        calendarIntent.isDate(log.date, inSameDayAs: date) && log.habitId == habitUUID
                    }) {
                        habitStore.habitLogs.remove(at: indexToRemove)
                    }
                } else {
                    // 增加计数
                    if let indexToUpdate = habitStore.habitLogs.firstIndex(where: { log in
                        calendarIntent.isDate(log.date, inSameDayAs: date) && log.habitId == habitUUID
                    }) {
                        habitStore.habitLogs[indexToUpdate].count += 1
                    }
                }
            }
        } else {
            // 如果没有今天的日志，创建一个新日志
            let initialCount = habit.habitType == .checkbox ? 5 : 1
            let newLog = HabitLog(habitId: habitUUID, date: date, count: initialCount)
            habitStore.habitLogs.append(newLog)
        }
        
        // 保存更新后的数据到UserDefaults
        if let logsData = try? JSONEncoder().encode(habitStore.habitLogs) {
            // 先保存日志数据
            sharedDefaultsIntent.set(logsData, forKey: "habitLogs")
            print("【Widget】已保存更新后的日志数据到UserDefaults")
            
            // 强制同步确保数据写入
            sharedDefaultsIntent.synchronize()
        }
        
        // 刷新Widget
        WidgetCenter.shared.reloadTimelines(ofKind: "HabitWidget")
        
        // 获取操作后的状态
        let afterCount = habitStore.habitLogs.filter { log in
            calendarIntent.isDate(log.date, inSameDayAs: date) && log.habitId == habitUUID
        }.first?.count ?? 0
        print("【Widget】打卡后习惯状态 - 打卡次数: \(afterCount)/\(habit.maxCheckInCount)")
        
        // 返回结果
        if habit.habitType == .checkbox {
            if beforeCount > 0 && afterCount == 0 {
                return .result(dialog: "已取消打卡")
            } else if beforeCount == 0 && afterCount > 0 {
                return .result(dialog: "已完成打卡")
            }
        } else { // count类型
            if beforeCount >= habit.maxCheckInCount && afterCount == 0 {
                return .result(dialog: "打卡已重置")
            } else {
                return .result(dialog: "已打卡 \(afterCount)/\(habit.maxCheckInCount)")
            }
        }
        
        return .result(dialog: "打卡状态已更新")
    }
}

// Widget 配置
struct HabitWidget: Widget {
    let kind: String = "HabitWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: HabitSelectionIntent.self,
            provider: Provider()
        ) { entry in
            HabitWidgetEntryView(entry: entry)
                .containerBackground(.fill.quaternary, for: .widget)
        }
        .configurationDisplayName("习惯追踪")
        .description("直接从桌面打卡你的习惯，习惯ID从习惯详情设置页获取")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()  // 添加此行以确保Widget能准确接收系统刷新
    }
}

#if DEBUG
// 预览
struct HabitWidget_Previews: PreviewProvider {
    static var previews: some View {
        // 创建模拟数据
        let habit = Habit(name: "读书", emoji: "📚", colorTheme: .github, habitType: .count, maxCheckInCount: 3)
        let intent = HabitSelectionIntent()
        intent.habitId = habit.id.uuidString
        
        // 创建模拟日志
        let calendar = Calendar.current
        let today = Date()
        var logs: [HabitLog] = []
        
        // 添加一些连续的日志
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let log = HabitLog(habitId: habit.id, date: date, count: i % 4)
                logs.append(log)
            }
        }
        
        // 创建条目
        let entry = HabitEntry(
            date: Date(),
            habit: habit,
            logs: logs,
            todayCount: 2,
            configuration: intent
        )
        
        // 返回预览视图
        return Group {
            HabitWidgetEntryView(entry: entry)
                .containerBackground(.fill.quaternary, for: .widget)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("习惯小组件 (浅色)")
                
            HabitWidgetEntryView(entry: entry)
                .containerBackground(.fill.quaternary, for: .widget)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .environment(\.colorScheme, .dark)
                .previewDisplayName("习惯小组件 (深色)")
        }
    }
}
#endif
