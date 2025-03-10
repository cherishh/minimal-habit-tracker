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
    
    @Parameter(title: "习惯名称", default: "")
    var habitName: String
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
        switch family {
        case .systemMedium:
            HStack(spacing: 16) {
                // 左侧：微型热力图
                WidgetMiniHeatmapView(
                    habit: entry.habit,
                    logs: entry.logs,
                    colorScheme: colorScheme
                )
                .padding(.leading, 16)
                
                Spacer()
                
                // 右侧：打卡按钮
                WidgetCheckInButton(
                    habit: entry.habit,
                    todayCount: entry.todayCount,
                    colorScheme: colorScheme
                )
                .padding(.trailing, 16)
            }
            .padding(.vertical, 16)
            .widgetURL(URL(string: "easyhabit://widget/checkin?habitId=\(entry.habit.id.uuidString)"))
            
        default:
            Text("不支持的 Widget 大小")
        }
    }
}

// 微型热力图组件 - 专为 Widget 优化
struct WidgetMiniHeatmapView: View {
    let habit: Habit
    let logs: [HabitLog]
    let colorScheme: ColorScheme
    
    // 热力图大小配置
    private let cellSize: CGFloat = 6
    private let cellSpacing: CGFloat = 2
    
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
        
        VStack(alignment: .leading, spacing: 8) {
            // 习惯名称
            Text(habit.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            // 热力图
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
        }
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
        return min(count / 4.0, 1.0)
    }
    
    var body: some View {
        Link(destination: URL(string: "easyhabit://widget/checkin?habitId=\(habit.id.uuidString)")!) {
            ZStack {
                // 圆环
                if habit.habitType == .checkbox {
                    // Checkbox型习惯的圆环 - 先显示底色轨道
                    Circle()
                        .stroke(
                            theme.color(for: 1, isDarkMode: colorScheme == .dark).opacity(0.4),
                            style: StrokeStyle(lineWidth: 8)
                        )
                        .frame(width: 60, height: 60)
                    
                    // 完成圆环
                    Circle()
                        .trim(from: 0, to: isCompletedToday ? 1 : 0)
                        .stroke(
                            theme.color(for: 4, isDarkMode: colorScheme == .dark),
                            style: StrokeStyle(
                                lineWidth: 8,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                } else {
                    // Count型习惯的圆环 - 先显示底色轨道
                    Circle()
                        .stroke(
                            theme.color(for: 1, isDarkMode: colorScheme == .dark).opacity(0.4),
                            style: StrokeStyle(lineWidth: 8)
                        )
                        .frame(width: 60, height: 60)
                    
                    // 进度环
                    Circle()
                        .trim(from: 0, to: countProgress)
                        .stroke(
                            theme.color(for: 4, isDarkMode: colorScheme == .dark),
                            style: StrokeStyle(
                                lineWidth: 8,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                }
                
                // Emoji
                Text(habit.emoji)
                    .font(.system(size: 24))
            }
        }
    }
}

// 打卡操作的 Intent
struct CheckInHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "打卡习惯"
    
    @Parameter(title: "习惯ID")
    var habitId: String
    
    init() {}
    
    init(habitId: String) {
        self.habitId = habitId
    }
    
    func perform() async throws -> some IntentResult {
        // 从 UserDefaults 加载习惯数据
        let habitStore = HabitStore()
        
        // 查找对应的习惯
        if let uuid = UUID(uuidString: habitId),
           let _ = habitStore.habits.first(where: { $0.id == uuid }) {
            // 执行打卡操作
            habitStore.logHabit(habitId: uuid, date: Date())
            
            // 请求刷新所有 Widget
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        return .result()
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
        intent.habitName = habit.name
        
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
