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
        // 从 UserDefaults 加载习惯数据
        let habitStore = loadHabitStore()
        
        // 获取选择的习惯，如果没有选择或找不到，则使用第一个习惯
        let selectedHabit: Habit
        if !configuration.habitId.isEmpty,
           let habit = habitStore.habits.first(where: { $0.id.uuidString == configuration.habitId }) {
            selectedHabit = habit
        } else if !habitStore.habits.isEmpty {
            selectedHabit = habitStore.habits[0]
        } else {
            // 如果没有习惯，使用默认习惯
            selectedHabit = Habit(name: "读书", emoji: "📚", colorTheme: .github, habitType: .checkbox)
        }
        
        // 获取习惯的日志
        let logs = habitStore.habitLogs.filter { $0.habitId == selectedHabit.id }
        
        // 获取今天的打卡次数
        let todayCount = habitStore.getLogCountForDate(habitId: selectedHabit.id, date: Date())
        
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
        
        // 设置每小时更新一次
        let nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        
        return Timeline(entries: [entry], policy: .after(nextUpdateDate))
    }
    
    // 从 UserDefaults 加载习惯数据
    private func loadHabitStore() -> HabitStore {
        // 创建一个使用共享 UserDefaults 的自定义 HabitStore
        let habitStore = createSharedHabitStore()
        
        // 如果 habitStore 中没有数据，可能是因为 App Group 配置有问题
        if habitStore.habits.isEmpty {
            print("Widget 未能找到应用数据，返回示例数据")
        } else {
            print("Widget 成功加载了 \(habitStore.habits.count) 个习惯")
        }
        
        return habitStore
    }
    
    // 创建使用共享 UserDefaults 的 HabitStore
    private func createSharedHabitStore() -> HabitStore {
        let habitStore = HabitStore()
        
        // 尝试从共享 UserDefaults 加载数据
        let habitsKey = "habits"
        let habitLogsKey = "habitLogs"
        
        // 加载习惯数据
        if let habitsData = sharedDefaults.data(forKey: habitsKey),
           let decodedHabits = try? JSONDecoder().decode([Habit].self, from: habitsData) {
            habitStore.habits = decodedHabits
        }
        
        // 加载习惯日志数据
        if let logsData = sharedDefaults.data(forKey: habitLogsKey),
           let decodedLogs = try? JSONDecoder().decode([HabitLog].self, from: logsData) {
            habitStore.habitLogs = decodedLogs
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
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            switch family {
            case .systemMedium:
                // 使用水平分割的方式隔离交互区域
                HStack(spacing: 0) {
                    // 左侧区域：标题和热力图，点击时打开应用
                    VStack(spacing: 0) {
                        // 上部分：习惯名称和连续打卡天数
                        HStack {
                            Text(entry.habit.name)
                                .font(.headline)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 16)
                            
                            Spacer()
                            
                            // 连续打卡天数（如果有的话）
                            if let currentStreak = getStreak(habit: entry.habit, logs: entry.logs), currentStreak > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(getTheme(habit: entry.habit).color(for: 4, isDarkMode: colorScheme == .dark))
                                    
                                    Text("\(currentStreak)")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(getTheme(habit: entry.habit).color(for: 4, isDarkMode: colorScheme == .dark))
                                }
                                .padding(.trailing, 16)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color(colorScheme == .dark ? UIColor.secondarySystemBackground : UIColor.systemBackground))
                        
                        Spacer()
                        
                        // 热力图区域
                        HStack {
                            // 左侧：微型热力图
                            WidgetMiniHeatmapView(
                                habit: entry.habit,
                                logs: entry.logs,
                                colorScheme: colorScheme
                            )
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(colorScheme == .dark ? UIColor.tertiarySystemBackground : UIColor.secondarySystemBackground).opacity(0.3))
                            )
                            .padding(.leading, 12)
                            .padding(.bottom, 12)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color(colorScheme == .dark ? UIColor.secondarySystemBackground : UIColor.systemBackground))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    // 打开应用的链接
                    .widgetURL(URL(string: "easyhabit://widget/open?habitId=\(entry.habit.id.uuidString)"))
                    
                    // 右侧区域：使用 iOS 17 交互按钮
                    VStack {
                        Spacer()
                        
                        // 打卡按钮
                        CheckInButtonContainer(
                            habit: entry.habit,
                            todayCount: entry.todayCount,
                            colorScheme: colorScheme
                        )
                        .padding(.horizontal, 8)
                        
                        Spacer()
                    }
                    .frame(width: 120)
                    .background(Color(colorScheme == .dark ? UIColor.tertiarySystemBackground : UIColor.secondarySystemBackground).opacity(0.5))
                }
                .cornerRadius(8)
                
            default:
                Text("不支持的 Widget 大小")
            }
        }
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

// 独立的打卡按钮容器
struct CheckInButtonContainer: View {
    let habit: Habit
    let todayCount: Int
    let colorScheme: ColorScheme
    
    var body: some View {
        // iOS 17 新方式：使用 Button(intent:) 进行直接交互
        Button(intent: CheckInHabitIntent(habitId: habit.id.uuidString)) {
            VStack {
                Text(habit.emoji)
                    .font(.system(size: 36))
                
                if todayCount > 0 {
                    Text("已完成")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("点击打卡")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        // 确保交互内容能触发刷新
        .invalidatableContent()
    }
}

// Widget 打卡按钮 - 现在只包含视觉部分，不包含交互逻辑 - 这个组件现在不再使用
struct WidgetCheckInButton: View {
    let habit: Habit
    let todayCount: Int
    let colorScheme: ColorScheme
    
    var body: some View {
        // 简化版本
        Text(habit.emoji)
            .font(.system(size: 36))
            .frame(width: 70, height: 70)
    }
}

// 微型热力图组件 - 专为 Widget 优化
struct WidgetMiniHeatmapView: View {
    let habit: Habit
    let logs: [HabitLog]
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
        
        // 移除标题，直接显示热力图
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
                                .fill(theme.color(for: min(count, 4), isDarkMode: colorScheme == .dark))
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
        .frame(width: 190) // 保持相同宽度，适应100天的数据
    }
}

// 打卡操作的 Intent
struct CheckInHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "打卡习惯"
    static var description = IntentDescription("记录习惯打卡")
    
    @Parameter(title: "习惯ID")
    var habitId: String
    
    init() {}
    
    init(habitId: String) {
        self.habitId = habitId
    }
    
    // 执行打卡操作
    func perform() async throws -> some IntentResult {
        // 共享 UserDefaults - 和主应用使用相同的组标识
        let sharedDefaults = UserDefaults(suiteName: "group.com.xi.HabitTracker.minimal-habit-tracker") ?? UserDefaults.standard
        
        // 当前时间
        let now = Date()
        
        // 从 UserDefaults 加载日志数据
        let habitLogsKey = "habitLogs"
        var habitLogs: [HabitLog] = []
        
        if let logsData = sharedDefaults.data(forKey: habitLogsKey),
           let decodedLogs = try? JSONDecoder().decode([HabitLog].self, from: logsData) {
            habitLogs = decodedLogs
        }
        
        // 解析 habitId 并创建日志
        if let uuid = UUID(uuidString: habitId) {
            // 创建新日志
            let newLog = HabitLog(id: UUID(), habitId: uuid, date: now, count: 1)
            
            // 查找同一天的日志
            let calendar = Calendar.current
            let sameDayLogs = habitLogs.filter { 
                calendar.isDate($0.date, inSameDayAs: now) && $0.habitId == uuid 
            }
            
            if let existingLog = sameDayLogs.first {
                // 今天已有日志，更新计数
                if let index = habitLogs.firstIndex(where: { $0.id == existingLog.id }) {
                    habitLogs[index].count += 1
                }
            } else {
                // 今天没有日志，添加新日志
                habitLogs.append(newLog)
            }
            
            // 保存更新后的日志数据
            do {
                let encodedData = try JSONEncoder().encode(habitLogs)
                
                // 保存到共享 UserDefaults
                sharedDefaults.set(encodedData, forKey: habitLogsKey)
                sharedDefaults.synchronize()
                
                // 关键步骤：写入特殊键值对，标记数据更新时间
                // 这将触发主应用的 UserDefaults 通知监听器
                let updateTimestampKey = "widgetDataUpdateTimestamp"
                sharedDefaults.set(Date().timeIntervalSince1970, forKey: updateTimestampKey)
                sharedDefaults.synchronize()
                
                // 刷新所有 Widget
                WidgetCenter.shared.reloadAllTimelines()
                
                return .result()
            } catch {
                return .result()
            }
        } else {
            return .result()
        }
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
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("习惯追踪")
        .description("显示习惯热力图和打卡按钮")
        .supportedFamilies([.systemMedium])
    }
}

// 支持 Smart Stack 样式上下滑动切换的 Widget
struct SmartStackHabitWidget: Widget {
    let kind: String = "SmartStackHabitWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: HabitSelectionIntent.self,
            provider: Provider()
        ) { entry in
            HabitWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("习惯追踪 (Smart Stack)")
        .description("显示习惯热力图和打卡按钮，支持上下滑动切换不同习惯")
        .supportedFamilies([.systemMedium])
        .disfavoredLocations([.lockScreen], for: [.systemMedium])
        .contentMarginsDisabled()
    }
}

#if DEBUG
// 预览
struct HabitWidget_Previews: PreviewProvider {
    static var previews: some View {
        // 创建一个模拟的习惯和日志数据
        let habit = Habit(name: "读书", emoji: "📚", colorTheme: .github, habitType: .checkbox)
        let intent = HabitSelectionIntent()
        intent.habitId = habit.id.uuidString
        
        // 创建一个条目用于预览
        let entry = HabitEntry(
            date: Date(),
            habit: habit,
            logs: [],
            todayCount: 1,
            configuration: intent
        )
        
        // 返回预览视图
        return Group {
            HabitWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("习惯小组件")
        }
    }
}
#endif
