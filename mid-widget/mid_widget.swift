//
//  mid_widget.swift
//  mid-widget
//
//  Created by 王仲玺 on 2025/3/10.
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
        
        // 检查刷新时间戳
        let lastTimestamp = sharedDefaults.double(forKey: "widget_refresh_timestamp")
        if lastTimestamp > 0 {
            print("【Widget】检测到更新时间戳: \(lastTimestamp)")
        }
        
        // 从 UserDefaults 直接加载最新习惯数据
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
        
        // 获取习惯的日志
        let logs = habitStore.habitLogs.filter { $0.habitId == selectedHabit.id }
        print("【Widget】过滤出该习惯的日志数量: \(logs.count)条")
        
        // 获取今天的打卡次数
        let todayCount = habitStore.getLogCountForDate(habitId: selectedHabit.id, date: Date())
        print("【Widget】今日打卡次数: \(todayCount)")
        
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
        let entry = await snapshot(for: configuration, in: context)
        
        // 计算多个更新时间点以实现更频繁的刷新
        var entries = [entry]
        let currentDate = Date()
        
        // 未来5分钟、15分钟和30分钟各安排一次更新
        let updateTimes = [5, 15, 30]
        for minutes in updateTimes {
            if let futureDate = Calendar.current.date(byAdding: .minute, value: minutes, to: currentDate) {
                let futureEntry = HabitEntry(
                    date: futureDate,
                    habit: entry.habit,
                    logs: entry.logs,
                    todayCount: entry.todayCount,
                    configuration: entry.configuration
                )
                entries.append(futureEntry)
            }
        }
        
        print("【Widget】计划了\(entries.count)个时间点的更新")
        return Timeline(entries: entries, policy: .atEnd)
    }
    
    // 从 UserDefaults 加载习惯数据
    private func loadHabitStore() -> HabitStore {
        print("【Widget Provider】开始loadHabitStore - 强制从UserDefaults读取")
        
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
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .primary.opacity(0.8) : .primary)
                    .padding(.vertical,18)
                    .padding(.horizontal, 16)
                
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
                    .padding(.trailing, 16)
                }
            }
            .background(colorScheme == .dark ? Color.black : Color.white)
            
            // 下部分：微型热力图和打卡按钮
            HStack(spacing: 16) {
                // 左侧：微型热力图
                Link(destination: URL(string: "habittracker://open?habitId=\(entry.habit.id.uuidString)")!) {
                    WidgetMiniHeatmapView(
                        logs: entry.logs,
                        habit: entry.habit,
                        colorScheme: colorScheme
                    )
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(colorScheme == .dark 
                                ? Color.black.opacity(0.3) 
                                : Color.gray.opacity(0.1))
                    )
                    .padding(.leading, 12)
                    .padding(.top, 0)
                    .padding(.bottom, 12)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // 右侧：打卡按钮
                WidgetCheckInButton(
                    habit: entry.habit,
                    todayCount: entry.todayCount,
                    colorScheme: colorScheme
                )
                .padding(.trailing, 16)
                .padding(.vertical, 8)
            }
            .background(colorScheme == .dark ? Color.black : Color.white)
        }
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
        for dayOffset in 0..<100 { // 最多查找100天
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
    
    // 热力图大小配置
    private let cellSize: CGFloat = 8
    private let cellSpacing: CGFloat = 3
    
    // 热力图日期配置
    private let daysToShow = 100 // 显示过去100天
    
    // 获取习惯的主题颜色
    private var theme: ColorTheme {
        ColorTheme.getTheme(for: habit.colorTheme)
    }
    
    // 生成过去100天的日期网格，按周组织
    private var dateGrid: [[Date?]] {
        let calendar = Calendar.current
        let today = Date()
        
        // 1. 计算100天前的日期
        guard let startDate100DaysAgo = calendar.date(byAdding: .day, value: -(daysToShow-1), to: today) else {
            return []
        }
        
        // 2. 找到起始日期所在周的周一
        var startDate = startDate100DaysAgo
        let startWeekday = calendar.component(.weekday, from: startDate)
        // 将startDate调整为那周的周一（weekday=2是周一）
        let daysToSubtract = (startWeekday == 1) ? 6 : (startWeekday - 2)
        if daysToSubtract > 0 {
            startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: startDate) ?? startDate
        }
        
        // 3. 计算需要多少列（周）才能覆盖到今天
        // 计算从起始日期到今天一共有多少天
        let components = calendar.dateComponents([.day], from: startDate, to: today)
        let totalDays = components.day ?? 0
        // 加上7天确保有足够的列来显示，然后除以7得到周数
        let totalColumns = (totalDays + 7) / 7 + 1
        
        // 4. 构建日期网格（比实际需要的多一点以确保所有日期都能显示）
        var grid: [[Date?]] = Array(repeating: Array(repeating: nil, count: totalColumns), count: 7)
        
        // 5. 填充日期网格
        for column in 0..<totalColumns {
            for row in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: (column * 7) + row, to: startDate) {
                    // 如果日期超过今天，则不添加
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
        
        if let log = logs.first(where: { log in
            calendar.isDate(log.date, inSameDayAs: date)
        }) {
            return log.count
        }
        
        return 0
    }
    
    var body: some View {
        // 计算总共需要显示的列数
        let columnCount = dateGrid.isEmpty ? 0 : dateGrid[0].count
        
        VStack(alignment: .leading, spacing: cellSpacing) {
            // 每行代表星期几（0是周一，6是周日）
            ForEach(0..<7, id: \.self) { row in
                HStack(spacing: cellSpacing) {
                    // 每列代表一周
                    ForEach(0..<columnCount, id: \.self) { column in
                        // 获取该位置的日期
                        if let date = dateGrid[row][column] {
                            let count = getLogCountForDate(date: date)
                            
                            // 单个格子
                            RoundedRectangle(cornerRadius: 1)
                                .fill(count > 0 
                                      ? theme.colorForCount(count: count, maxCount: habit.maxCheckInCount, isDarkMode: colorScheme == .dark)
                                      : (colorScheme == .dark 
                                         ? theme.color(for: 0, isDarkMode: true) 
                                         : Color(hex: "ebedf0")))
                                .frame(width: cellSize, height: cellSize)
                        } else {
                            // 没有日期的位置（例如超过今天的日期）
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.clear)
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
        .frame(height: 7 * (cellSize + cellSpacing) - cellSpacing)
        .frame(width: 185) // 从190减小到185，提供更多边距空间
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
    func perform() async throws -> some IntentResult {
        // 调试日志：开始执行打卡操作
        print("【Widget】开始执行打卡操作，habitId: \(habitId)")
        
        // 1. 获取当前习惯信息
        let habitStore = HabitStore.shared
        
        // 调试：检查Widget中读取到的习惯和日志
        print("【Widget】当前内存中的习惯数量: \(habitStore.habits.count)")
        print("【Widget】当前内存中的日志数量: \(habitStore.habitLogs.count)")
        
        // 调试：直接从UserDefaults读取一次数据检查
        let sharedDefaults = UserDefaults(suiteName: "group.com.xi.HabitTracker.minimal-habit-tracker")!
        if let habitsData = sharedDefaults.data(forKey: "habits"),
           let decodedHabits = try? JSONDecoder().decode([Habit].self, from: habitsData) {
            print("【Widget】UserDefaults中的习惯数量: \(decodedHabits.count)")
        } else {
            print("【Widget】UserDefaults中没有找到习惯数据")
        }
        
        if let logsData = sharedDefaults.data(forKey: "habitLogs"),
           let decodedLogs = try? JSONDecoder().decode([HabitLog].self, from: logsData) {
            print("【Widget】UserDefaults中的日志数量: \(decodedLogs.count)")
        } else {
            print("【Widget】UserDefaults中没有找到日志数据")
        }
        
        guard let habitUUID = UUID(uuidString: habitId),
              let habit = habitStore.habits.first(where: { $0.id == habitUUID }) else {
            // 习惯不存在，返回错误
            print("【Widget】找不到指定习惯，habitId: \(habitId)")
            return .result(dialog: "找不到指定习惯")
        }
        
        // 获取打卡前的状态
        let beforeCount = habitStore.getLogCountForDate(habitId: habitUUID, date: date)
        print("【Widget】打卡前习惯状态 - 名称: \(habit.name), 打卡次数: \(beforeCount)/\(habit.maxCheckInCount)")
        
        // 2. 执行打卡操作
        habitStore.logHabit(habitId: habitUUID, date: date)
        print("【Widget】已执行logHabit操作")
        
        // 调试：检查操作后的UserDefaults
        if let logsData = sharedDefaults.data(forKey: "habitLogs"),
           let decodedLogs = try? JSONDecoder().decode([HabitLog].self, from: logsData) {
            let habitLogs = decodedLogs.filter { $0.habitId == habitUUID }
            print("【Widget】操作后UserDefaults中该习惯的日志数量: \(habitLogs.count)")
            if let todayLog = habitLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: Date()) }) {
                print("【Widget】操作后UserDefaults中今日该习惯的打卡次数: \(todayLog.count)")
            } else {
                print("【Widget】操作后UserDefaults中未找到今日该习惯的打卡记录")
            }
        }
        
        // 3. 刷新所有Widget
        WidgetCenter.shared.reloadAllTimelines()
        print("【Widget】已刷新Widget")
        
        // 4. 返回成功信息，根据习惯类型和结果提供不同反馈
        let afterCount = habitStore.getLogCountForDate(habitId: habitUUID, date: date)
        print("【Widget】打卡后习惯状态 - 打卡次数: \(afterCount)/\(habit.maxCheckInCount)")
        
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
