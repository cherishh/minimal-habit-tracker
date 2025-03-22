//
//  ContentView.swift
//  minimal habit tracker
//
//  Created by 王仲玺 on 2025/3/6.
//

import SwiftUI
import WidgetKit
import StoreKit
import MessageUI

// 添加支持系统侧滑返回手势的扩展
extension View {
    func interactivePopGestureRecognizer(_ enabled: Bool) -> some View {
        self.modifier(InteractivePopGestureRecognizerModifier(enabled: enabled))
    }
}

struct InteractivePopGestureRecognizerModifier: ViewModifier {
    let enabled: Bool
    
    func body(content: Content) -> some View {
        content
            .background(InteractivePopGestureRecognizerHelper(enabled: enabled))
    }
}

struct InteractivePopGestureRecognizerHelper: UIViewControllerRepresentable {
    let enabled: Bool
    
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let navigationController = uiViewController.navigationController else { return }
        navigationController.interactivePopGestureRecognizer?.isEnabled = enabled
    }
}

struct ContentView: View {
    @EnvironmentObject var habitStore: HabitStore
    @State private var showingSettings = false
    @State private var showingAddHabit = false
    @State private var showDeleteConfirmation = false
    @State private var habitToDelete: Habit? = nil
    @Environment(\.colorScheme) var colorScheme
    @State private var showingSortSheet = false
    @State private var navigateToDetail = false
    @State private var selectedHabitId: UUID? = nil
    @State private var showingMaxHabitsAlert = false
    @AppStorage("themeMode") private var themeMode: Int = 0 // 0: 自适应系统, 1: 明亮模式, 2: 暗黑模式
    @State private var showingMailCannotSendAlert = false
    
    // 自定义更淡的背景色
    private var lightBackgroundColor: Color {
        colorScheme == .dark 
            ? Color(UIColor.systemBackground) 
            : Color(UIColor.systemGroupedBackground).opacity(0.4)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 自定义标题栏
                HStack {
                    Text("EasyHabit")
                        .font(.system(size: 32, weight: .regular, design: .rounded))
                        .padding(.leading)
                        .foregroundColor(colorScheme == .dark ? .primary.opacity(0.8) : .primary)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            if habitStore.canAddHabit() {
                                showingAddHabit = true
                            }
                        }) {
                            Image("plus")
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .frame(width: 36, height: 36)
                                .background(Color(UIColor.systemGray5).opacity(0.6))
                                .cornerRadius(10)
                                .foregroundColor(colorScheme == .dark ? .primary.opacity(0.8) : .primary)
                        }
                        
                        if !habitStore.habits.isEmpty {
                            Button(action: { showingSortSheet = true }) {
                                Image(systemName: "arrow.up.arrow.down")
                                    .resizable()
                                    .renderingMode(.template)
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                                    .frame(width: 36, height: 36)
                                    .background(Color(UIColor.systemGray5).opacity(0.6))
                                    .cornerRadius(10)
                                    .foregroundColor(colorScheme == .dark ? .primary.opacity(0.8) : .primary)
                            }
                        }
                        
                        Button(action: { showingSettings = true }) {
                            Image("settings")
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .frame(width: 36, height: 36)
                                .background(Color(UIColor.systemGray5).opacity(0.6))
                                .cornerRadius(10)
                                .foregroundColor(colorScheme == .dark ? .primary.opacity(0.8) : .primary)
                        }
                    }
                    .padding(.trailing)
                }
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(lightBackgroundColor)
                
                if habitStore.habits.isEmpty {
                    emptyStateView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(lightBackgroundColor)
                } else {
                    habitListView
                }
            }
            .navigationBarHidden(true) // 隐藏系统的导航栏，使用自定义标题栏
            .sheet(isPresented: $showingAddHabit) {
                NewHabitView(isPresented: $showingAddHabit)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(isPresented: $showingSettings)
            }
            .sheet(isPresented: $showingSortSheet) {
                HabitSortView(isPresented: $showingSortSheet)
            }
            .alert(isPresented: $showingMaxHabitsAlert) {
                Alert(
                    title: Text("达到最大数量"),
                    message: Text("您最多只能创建 \(HabitStore.maxHabitCount) 个习惯。如需添加更多，请升级为Pro版本。"),
                    dismissButton: .default(Text("我知道了"))
                )
            }
            .navigationDestination(isPresented: $navigateToDetail) {
                if let habitId = selectedHabitId {
                    HabitDetailView(habitId: habitId)
                }
            }
            .onAppear {
                setupNotificationObserver()
            }
            .onDisappear {
                removeNotificationObserver()
            }
            .background(lightBackgroundColor)
        }
        .preferredColorScheme(getPreferredColorScheme())
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name("NavigateToDetail"), object: nil, queue: .main) { notification in
            if let habit = notification.object as? Habit {
                selectedHabitId = habit.id
                navigateToDetail = true
            }
        }
    }
    
    private func removeNotificationObserver() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NavigateToDetail"), object: nil)
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            
            // 简化后的文案
            Text("空空如也")
                .font(.system(size: 28, weight: .bold))
                .padding(.bottom, 4)
            
            Text("👇开始记录追踪你的习惯")
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.bottom, 40)
            
            // 大一点的添加按钮
            Button(action: { 
                if habitStore.canAddHabit() {
                    showingAddHabit = true
                }
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
                    .frame(width: 60, height: 60)
                    .background(Color(UIColor.systemGray5).opacity(0.6))
                    .cornerRadius(30)
            }
            
            Spacer()
        }
    }
    
    private var habitListView: some View {
        ScrollView {
            VStack(spacing: 16) {
            ForEach(habitStore.habits) { habit in
                    HabitCardView(habit: habit, onDelete: {
                        withAnimation {
                            // 设置要删除的习惯并显示确认对话框
                            habitToDelete = habit
                            showDeleteConfirmation = true
                        }
                    })
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .background(lightBackgroundColor)
        // 添加删除习惯的确认对话框
        .alert("确认删除", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let habit = habitToDelete {
                    withAnimation {
                        habitStore.removeHabit(habit)
                    }
                }
            }
        } message: {
            Text("确定要删除这个习惯吗？所有相关的打卡记录也将被删除。此操作无法撤销。")
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
}

// 微型热力图组件 - 显示过去100天的习惯记录
struct MiniHeatmapView: View {
    let habitId: UUID
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.colorScheme) var colorScheme
    
    // 热力图大小配置
    private let cellSize: CGFloat = 8
    private let cellSpacing: CGFloat = 3
    
    // 热力图日期配置
    private let daysToShow = 100 // 显示过去100天，而不是365天
    
    // 获取习惯对象
    private var habit: Habit {
        habitStore.habits.first(where: { $0.id == habitId }) ?? 
            Habit(name: "未找到", emoji: "❓", colorTheme: .github, habitType: .checkbox)
    }
    
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
    
    var body: some View {
        // 计算总共需要显示的列数
        let columnCount = dateGrid.isEmpty ? 0 : dateGrid[0].count
        
        // 移除滚动视图，直接显示内容
        VStack(alignment: .leading, spacing: cellSpacing) {
            // 每行代表星期几（0是周一，6是周日）
            ForEach(0..<7, id: \.self) { row in
                HStack(spacing: cellSpacing) {
                    // 每列代表一周
                    ForEach(0..<columnCount, id: \.self) { column in
                        // 获取该位置的日期
                        if let date = dateGrid[row][column] {
                            let count = habitStore.getLogCountForDate(habitId: habitId, date: date)
                            
                            // 单个格子
                            RoundedRectangle(cornerRadius: 1)
                                .fill(theme.colorForCount(count: count, maxCount: habit.maxCheckInCount, isDarkMode: colorScheme == .dark))
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
        .padding(.horizontal, 2) // 添加一点水平间距以确保边缘可见
        .opacity(0.85) // 整体添加0.85透明度，使热力图不那么刺眼
    }
}

// 单独的习惯卡片视图
struct HabitCardView: View {
    let habit: Habit
    let onDelete: () -> Void
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.colorScheme) var colorScheme
    @State private var isAnimating = false
    @State private var animatedCompletion: Double = 0
    @State private var offset: CGFloat = 0
    @State private var isSwiped = false
    
    // 移除本地状态变量，直接计算当前状态
    // 获取习惯对应的主题颜色
    private var theme: ColorTheme {
        ColorTheme.getTheme(for: habit.colorTheme)
    }
    
    // 判断今天是否已完成打卡 - 直接从 habitStore 获取
    private var isCompletedToday: Bool {
        habitStore.getLogCountForDate(habitId: habit.id, date: Date()) > 0
    }
    
    // 获取计数型习惯的进度百分比 (0-1) - 直接从 habitStore 获取
    private var countProgress: CGFloat {
        let count = CGFloat(habitStore.getLogCountForDate(habitId: habit.id, date: Date()))
        return min(count / CGFloat(habit.maxCheckInCount), 1.0)
    }
    
    // 获取连续打卡天数 - 直接从 habitStore 获取
    private var currentStreak: Int {
        let calendar = Calendar.current
        let today = Date()
        var dayCount = 0
        
        // 从今天开始向前查找连续打卡的天数
        for dayOffset in 0..<100 { // 最多查找100天
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            // 获取该日期的打卡记录
            let count = habitStore.getLogCountForDate(habitId: habit.id, date: date)
            
            // 如果这天有打卡记录，增加计数
            if count > 0 {
                dayCount += 1
            } else if dayOffset > 0 { // 遇到未打卡的日期且不是今天，结束计数
                break
            }
        }
        
        return dayCount
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // 删除按钮背景层
            HStack {
                Spacer()
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        offset = 0 // 先重置位置
                        isSwiped = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onDelete()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.85))
                .frame(width: 44, height: 44)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        
                        Image("trash")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundColor(.white)
                    }
                    .contentShape(Circle()) // 确保整个圆形区域可点击
                }
                .padding(.trailing, 24)
                .opacity(offset < 0 ? 1 : 0) // 当卡片滑动时显示按钮
                .frame(width: 60, height: 60) // 增加点击区域
            }
            
            // 卡片主体
            mainCardView
                .offset(x: offset)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { value in
                            // 只处理水平滑动，忽略垂直滑动
                            let horizontalDrag = abs(value.translation.width)
                            let verticalDrag = abs(value.translation.height)
                            
                            // 如果垂直滑动大于水平滑动，则不处理手势(让父ScrollView处理)
                            if verticalDrag > horizontalDrag {
                                return
                            }
                            
                            if value.translation.width < 0 {
                                offset = value.translation.width
                                if offset < -80 {
                                    offset = -80
                                }
                            } else if isSwiped {
                                offset = -80 + value.translation.width
                                if offset > 0 {
                                    offset = 0
                                }
                            }
                        }
                        .onEnded { value in
                            // 同样，只处理水平滑动
                            let horizontalDrag = abs(value.translation.width)
                            let verticalDrag = abs(value.translation.height)
                            
                            // 如果垂直滑动大于水平滑动，则不处理手势
                            if verticalDrag > horizontalDrag {
                                return
                            }
                            
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if value.translation.width < -20 || (isSwiped && value.translation.width < 20) {
                                    offset = -80
                                    isSwiped = true
                                } else {
                                    offset = 0
                                    isSwiped = false
                                }
                            }
                        }
                )
        }
        .allowsHitTesting(true)
        .frame(maxWidth: .infinity)
    }
    
    // 提取卡片主视图
    private var mainCardView: some View {
        VStack(spacing: 0) {
            // 上部分：习惯名称和连续打卡天数
            HStack {
                Text(habit.name)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .primary.opacity(0.8) : .primary)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                
                Spacer()
                
                // 连续打卡天数
                if currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundColor(colorScheme == .dark 
                                ? theme.color(for: 4, isDarkMode: true)
                                : theme.color(for: 5, isDarkMode: false))
                        
                        Text("\(currentStreak)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(colorScheme == .dark 
                                ? theme.color(for: 4, isDarkMode: true)
                                : theme.color(for: 5, isDarkMode: false))
                    }
                    .padding(.trailing, 16)
                }
            }
            .background(Color(colorScheme == .dark ? UIColor.secondarySystemBackground : UIColor.systemBackground))
            
            // 下部分：微型热力图和打卡按钮
            HStack(spacing: 16) {
                // 左侧：微型热力图使用equatable修饰符，避免不必要的重渲染
                // 注意加上.equatable()修饰符
                MiniHeatmapView(habitId: habit.id)
                    .equatable()
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(colorScheme == .dark ? UIColor.tertiarySystemBackground : UIColor.secondarySystemBackground).opacity(0.5))
                    )
                    .padding(.leading, 12)
                    .padding(.top, 0)
                    .padding(.bottom, 12)
                
                Spacer()
                
                // 右侧：Emoji和打卡按钮
                checkInButton
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
            }
            .background(Color(colorScheme == .dark ? UIColor.secondarySystemBackground : UIColor.systemBackground))
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
            .contentShape(Rectangle())
            .onTapGesture {
            if isSwiped {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    offset = 0
                    isSwiped = false
                }
            } else {
                NotificationCenter.default.post(name: NSNotification.Name("NavigateToDetail"), object: habit)
            }
        }
            }
            
    // Emoji打卡按钮
    private var checkInButton: some View {
            Button(action: {
            checkInHabit()
            }) {
                ZStack {
                let currentCount = habitStore.getLogCountForDate(habitId: habit.id, date: Date())
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
                            colorScheme == .dark 
                                ? theme.color(for: min(habit.maxCheckInCount, 4), isDarkMode: true)
                                : theme.color(for: min(habit.maxCheckInCount, 5), isDarkMode: false),
                            style: StrokeStyle(
                                lineWidth: 10,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: isCompletedToday)
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
                        .trim(from: 0, to: isAnimating ? animatedCompletion : countProgress)
                        .stroke(
                            colorScheme == .dark 
                                ? theme.color(for: min(habit.maxCheckInCount, 4), isDarkMode: true)
                                : theme.color(for: min(habit.maxCheckInCount, 5), isDarkMode: false),
                            style: StrokeStyle(
                                lineWidth: 10,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                }
                
                VStack(spacing: 0) {
                    // Emoji
                    Text(habit.emoji)
                        .font(.system(size: 28))

                    /* if habit.habitType == .count {
                        Text("\(currentCount)/\(habit.maxCheckInCount)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    } */
                }
            }
            }
            .buttonStyle(PlainButtonStyle())
        .frame(width: 70, height: 70)
    }
    
    // 打卡操作
    private func checkInHabit() {
        // 获取当前日期的计数
        let currentCount = habitStore.getLogCountForDate(habitId: habit.id, date: Date())
        
        // 计算点击后的新计数
        var newCount = currentCount
        if habit.habitType == .checkbox {
            newCount = (currentCount > 0) ? 0 : habit.maxCheckInCount
        } else {
            newCount = (currentCount >= habit.maxCheckInCount) ? 0 : currentCount + 1
        }
        
        // 设置动画的起点和终点
        let startCompletion = Double(min(currentCount, habit.maxCheckInCount)) / Double(habit.maxCheckInCount)
        let targetCompletion = Double(min(newCount, habit.maxCheckInCount)) / Double(habit.maxCheckInCount)
        
        // 设置动画
        isAnimating = true
        animatedCompletion = startCompletion
        
        // 使用withAnimation创建流畅的动画效果
        withAnimation(.easeInOut(duration: 0.5)) {
            if newCount == 0 {
                // 如果是取消打卡，动画应该从当前位置返回到0
                animatedCompletion = 0
            } else {
                // 否则动画应该前进到新位置
                animatedCompletion = targetCompletion
            }
        }
        
        // 执行实际的打卡操作
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            habitStore.logHabit(habitId: habit.id, date: Date())
            
            // 重置动画状态（在动画完成后）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isAnimating = false
            }
        }
    }
}

// 为MiniHeatmapView添加Equatable实现，减少不必要的重新渲染
extension MiniHeatmapView: Equatable {
    static func == (lhs: MiniHeatmapView, rhs: MiniHeatmapView) -> Bool {
        // 只有当habitId变化时，视图才需要重新渲染
        lhs.habitId == rhs.habitId
    }
}

// 添加设置页面
struct SettingsView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("themeMode") private var themeMode: Int = 0 // 0: 自适应系统, 1: 明亮模式, 2: 暗黑模式
    @State private var showingImportExport = false
    @State private var showingComingSoonAlert = false
    @State private var comingSoonMessage = ""
    @State private var showingProAlert = false
    @State private var showingCustomThemePrompt = false
    @State private var showingResetAlert = false
    @State private var showingAppVersionTapCount = 0
    @State private var showingMailView = false
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    @State private var showingMailCannotSendAlert = false
    
    // 覆盖版本号（保持与项目文件一致）
    let appVersion = "0.1"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "未知构建号"
    
    // 这些开关不会实际保存设置，仅作为UI展示
    @State private var iCloudSync = false
    @State private var unlimitedHabits = false
    @State private var noteFeature = false
    
    var body: some View {
        NavigationView {
            List {
                UpgradeSection
                AppearanceSection
                DataSection
                AboutSection
            }
            .navigationTitle("设置")
            .navigationBarItems(trailing: Button("完成") {
                isPresented = false
            })
            .sheet(isPresented: $showingImportExport) {
                ImportExportView()
            }
            .alert(comingSoonMessage, isPresented: $showingComingSoonAlert) {
                Button("好的", role: .cancel) { }
            }
            .sheet(isPresented: $showingMailView) {
                if MFMailComposeViewController.canSendMail() {
                    MailView(result: $mailResult, recipient: "jasonlovescola@gmail.com", subject: "EasyHabit用户反馈", body: generateEmailBody())
                }
            }
            .alert(isPresented: $showingMailCannotSendAlert) {
                Alert(title: Text("无法发送邮件"), message: Text("您的设备未设置邮件账户或无法发送邮件。请手动发送邮件至jasonlovescola@gmail.com"), dismissButton: .default(Text("确定")))
            }
        }
        .preferredColorScheme(getPreferredColorScheme())
    }
    
    // 根据设置返回颜色模式
    private func getPreferredColorScheme() -> ColorScheme? {
        switch themeMode {
            case 1: return .light     // 明亮模式
            case 2: return .dark      // 暗黑模式
            default: return nil       // 自适应系统
        }
    }
    
    // 在SettingsView中添加生成邮件正文的函数
    private func generateEmailBody() -> String {
        let deviceInfo = """
        
        ----------
        设备信息:
        设备型号: \(UIDevice.current.model)
        系统版本: \(UIDevice.current.systemVersion)
        应用版本: \(appVersion) (\(buildNumber))
        当前主题: \(themeMode == 0 ? "跟随系统" : (themeMode == 1 ? "明亮模式" : "暗黑模式"))
        习惯数量: \(habitStore.habits.count)
        ----------
        
        请在此处描述您的问题或建议:
        
        """
        
        return deviceInfo
    }
    
    // 在SettingsView中添加邮件发送功能
    private func sendFeedbackEmail() {
        if MFMailComposeViewController.canSendMail() {
            showingMailView = true
        } else {
            showingMailCannotSendAlert = true
        }
    }

    private var AppearanceSection: some View {
        Section(header: Text("主题设置")) {
            Picker("显示模式", selection: $themeMode) {
                Text("跟随系统").tag(0)
                Text("明亮模式").tag(1)
                Text("暗黑模式").tag(2)
            }
        }
    }
    
    private var DataSection: some View {
        Section(header: Text("数据管理")) {
            Button("导入 & 导出") {
                showingImportExport = true
            }
            .foregroundColor(.primary)
        }
    }
    
    private var UpgradeSection: some View {
        Section(header: Text("高级功能")) {
            NavigationLink {
                AdvancedThemeListView()
            } label: {
                HStack {
                    Text("高级颜色主题 & 自定义颜色")
                    Spacer()
                }
            }

            Toggle("iCloud 云同步", isOn: $iCloudSync)
                .onChange(of: iCloudSync) { newValue in
                    // 恢复到原始状态
                    iCloudSync = false
                    comingSoonMessage = "iCloud云同步功能即将推出"
                    showingComingSoonAlert = true
                }
            
            Toggle("无限习惯数量", isOn: $unlimitedHabits)
                .onChange(of: unlimitedHabits) { newValue in
                    // 恢复到原始状态
                    unlimitedHabits = false
                    comingSoonMessage = "无限习惯数量功能即将推出"
                    showingComingSoonAlert = true
                }
                
            Toggle("打卡笔记功能", isOn: $noteFeature)
                .onChange(of: noteFeature) { newValue in
                    // 恢复到原始状态
                    noteFeature = false
                    comingSoonMessage = "打卡笔记功能即将推出"
                    showingComingSoonAlert = true
                }
        }
    }

    private var AboutSection: some View {
        Section(header: Text("关于")) {
            Button {
                showingAppVersionTapCount += 1
                if showingAppVersionTapCount >= 7 {
                    habitStore.debugMode.toggle()
                    showingAppVersionTapCount = 0
                }
            } label: {
                HStack {
                    Text("应用版本")
                        .foregroundColor(.primary)
                    Spacer()
                    Text(habitStore.debugMode ? "\(appVersion) (\(buildNumber)) [调试模式]" : "\(appVersion) (\(buildNumber))")
                        .foregroundColor(.secondary)
                }
            }
            
            NavigationLink(destination: TermsOfUseView()) {
                Text("用户协议")
            }
            
            NavigationLink(destination: PrivacyPolicyView()) {
                Text("隐私政策")
            }
            
            Button(action: {
                // 打开App Store评分页面（使用模拟URL）
                if let url = URL(string: "https://apps.apple.com/app/id1234567890?action=write-review") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Text("为我们评分")
                    Spacer()
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            Button(action: {
                sendFeedbackEmail()
            }) {
                HStack {
                    Text("我抓到了🐞")
                    Spacer()
                    Image("square-arrow-out-up-right")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// 习惯排序视图
struct HabitSortView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var habitStore: HabitStore
    @State private var habits: [Habit] = []
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(habits) { habit in
                    HStack {
                        Text(habit.emoji)
                            .font(.title2)
                            .padding(.trailing, 8)
                        
                        Text(habit.name)
                            .font(.body)
                    }
                    .padding(.vertical, 8)
                }
                .onMove { from, to in
                    habits.move(fromOffsets: from, toOffset: to)
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("排序习惯")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveHabitOrder()
                        isPresented = false
                    }
                }
            }
            .onAppear {
                habits = habitStore.habits
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func saveHabitOrder() {
        // 保存新的习惯顺序到HabitStore
        habitStore.updateHabitOrder(habits)
    }
}

// 高级颜色主题列表视图
struct AdvancedThemeListView: View {
    @State private var showingUpgradeAlert = false
    @State private var showingComingSoonAlert = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // 高级主题列表（模拟数据）
    private let premiumThemes = [
        ("🌈 彩虹渐变", "彩虹主题"),
        ("🌌 星空", "深蓝星空"),
        ("🔥 火焰", "热情火焰"),
        ("🌊 海洋", "深海蓝调"),
        ("🌿 森林", "自然绿意"),
        ("🍑 蜜桃", "温暖粉色")
    ]
    
    // 为每个主题定义模拟颜色（从浅到深6个颜色）
    private func getThemeColors(for themeName: String) -> [Color] {
        switch themeName {
        case "🌈 彩虹渐变":
            return [Color(hex: "#F2F2F2"), Color(hex: "#FF9AA2"), Color(hex: "#FFDAC1"), Color(hex: "#E2F0CB"), Color(hex: "#B5EAD7"), Color(hex: "#C7CEEA")]
        case "🌌 星空":
            return [Color(hex: "#1A1B41"), Color(hex: "#2D3168"), Color(hex: "#4A4B8F"), Color(hex: "#8386B5"), Color(hex: "#A8AADB"), Color(hex: "#7884D4")]
        case "🔥 火焰":
            return [Color(hex: "#FFEFE0"), Color(hex: "#FEC196"), Color(hex: "#FD9460"), Color(hex: "#F36040"), Color(hex: "#D53867"), Color(hex: "#9E1946")]
        case "🌊 海洋":
            return [Color(hex: "#E8F7FF"), Color(hex: "#CCE9FB"), Color(hex: "#9DCCF7"), Color(hex: "#6BA7E0"), Color(hex: "#4682B4"), Color(hex: "#1C3C6D")]
        case "🌿 森林":
            return [Color(hex: "#E8F5E9"), Color(hex: "#C8E6C9"), Color(hex: "#A5D6A7"), Color(hex: "#81C784"), Color(hex: "#66BB6A"), Color(hex: "#2E7D32")]
        case "🍑 蜜桃":
            return [Color(hex: "#FFF0F0"), Color(hex: "#FFCCCC"), Color(hex: "#FFB3B3"), Color(hex: "#FF8080"), Color(hex: "#FF6666"), Color(hex: "#FF0000")]
        default:
            return [Color.gray.opacity(0.2), Color.gray.opacity(0.3), Color.gray.opacity(0.4), Color.gray.opacity(0.6), Color.gray.opacity(0.8), Color.gray]
        }
    }
    
    var body: some View {
        List {
            Section(header: Text("高级主题").font(.headline)) {
                ForEach(premiumThemes, id: \.0) { theme in
                    Button(action: {
                        showingUpgradeAlert = true
                    }) {
                        HStack {
                            Text(theme.0)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // 主题预览 - 类似于习惯创建时的样式
                            HStack(spacing: 2) {
                                ForEach(0..<6) { level in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(getThemeColors(for: theme.0)[level])
                                        .frame(width: 16, height: 16)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle()) // 确保整行可点击
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Section {
                Button(action: {
                    showingComingSoonAlert = true
                }) {
                    HStack {
                        Text("🎨 自定义颜色")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // 自定义颜色的预览 - 统一样式
                        HStack(spacing: 2) {
                            ForEach(0..<6) { i in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(hue: Double(i) / 6.0, saturation: 0.8, brightness: 0.8))
                                    .frame(width: 16, height: 16)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("高级主题")
        .alert("升级到Pro版本", isPresented: $showingUpgradeAlert) {
            Button("取消", role: .cancel) { }
            Button("升级") {
                // 这里可以添加导向升级页面的代码
                dismiss()
            }
        } message: {
            Text("高级主题仅适用于Pro版本用户。升级后即可解锁所有高级主题，并获得无限习惯数量、iCloud同步等更多功能。")
        }
        .alert("即将推出", isPresented: $showingComingSoonAlert) {
            Button("好的", role: .cancel) { }
        } message: {
            Text("自定义颜色主题功能即将推出，敬请期待！")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HabitStore())
}

// 添加邮件视图
struct MailView: UIViewControllerRepresentable {
    @Binding var result: Result<MFMailComposeResult, Error>?
    let recipient: String
    let subject: String
    let body: String
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let viewController = MFMailComposeViewController()
        viewController.mailComposeDelegate = context.coordinator
        viewController.setToRecipients([recipient])
        viewController.setSubject(subject)
        viewController.setMessageBody(body, isHTML: false)
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailView
        
        init(_ parent: MailView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            defer {
                controller.dismiss(animated: true)
            }
            
            if let error = error {
                parent.result = .failure(error)
                return
            }
            
            parent.result = .success(result)
        }
    }
}

// 用户协议视图
struct TermsOfUseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("用户协议")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom)
                
                Group {
                    Text("欢迎使用EasyHabit应用")
                        .font(.title2)
                        .bold()
                    
                    Text("本协议是您与EasyHabit（下称\"我们\"）之间关于您使用EasyHabit应用及相关服务的协议。在您开始使用EasyHabit应用之前，请您务必认真阅读并充分理解本协议的全部内容。")
                    
                    Text("1. 接受条款")
                        .font(.headline)
                    Text("通过使用EasyHabit应用，您确认您已满16周岁并同意受到本协议的约束。如您未满16周岁，应在监护人陪同下阅读本协议，并在监护人同意的前提下使用我们的服务。")
                    
                    Text("2. 服务描述")
                        .font(.headline)
                    Text("EasyHabit是一款帮助用户记录和培养习惯的应用。我们为用户提供习惯追踪、统计和分析功能，帮助用户更好地管理自己的日常习惯。")
                    
                    Text("3. 用户行为规范")
                        .font(.headline)
                    Text("您应遵守中华人民共和国相关法律法规，不得利用本应用从事违法活动。您应对使用本应用的行为负责，确保您提供和发布的内容合法、真实和准确，不侵犯任何第三方的合法权益。")
                    
                    Text("4. 隐私保护")
                        .font(.headline)
                    Text("我们重视用户的隐私保护，您在使用我们的服务时，我们可能收集和使用您的相关信息。我们将按照《EasyHabit隐私政策》收集、使用、存储和分享您的信息。")
                    
                    Text("5. 知识产权")
                        .font(.headline)
                    Text("EasyHabit应用及其所有内容，包括但不限于文本、图形、用户界面、徽标、图标、图像、音频和计算机代码，均受知识产权法保护，这些权利归我们或我们的许可方所有。")
                }
                
                Group {
                    Text("6. 免责声明")
                        .font(.headline)
                    Text("EasyHabit仅提供习惯追踪和管理工具，不对用户因使用本应用而产生的任何直接或间接损失负责。我们不保证服务一定能满足您的要求，也不保证服务不会中断。")
                    
                    Text("7. 协议修改")
                        .font(.headline)
                    Text("我们保留随时修改本协议的权利。对本协议的修改将通过在应用内或网站上发布通知的方式告知用户。若您在修改后继续使用EasyHabit，则视为您已接受修改后的协议。")
                    
                    Text("8. 联系我们")
                        .font(.headline)
                    Text("如您对本协议或EasyHabit应用有任何问题，请通过应用中的\"用户反馈\"功能与我们联系。")
                    
                    Text("本协议更新日期：2024年3月20日")
                        .italic()
                        .padding(.top)
                }
            }
            .padding()
        }
        .navigationTitle("用户协议")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// 隐私政策视图
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("隐私政策")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom)
                
                Group {
                    Text("EasyHabit隐私政策")
                        .font(.title2)
                        .bold()
                    
                    Text("本隐私政策旨在帮助您了解我们如何收集、使用、存储和共享您的个人信息，以及您享有的相关权利。在使用EasyHabit应用前，请您仔细阅读并了解本隐私政策的全部内容。")
                    
                    Text("1. 我们收集的信息")
                        .font(.headline)
                    Text("• 您提供的信息：当您使用EasyHabit应用时，您可能会创建习惯记录、设置提醒等，这些信息将被存储在您的设备上。\n• 设备信息：我们可能会收集您使用的设备型号、操作系统版本等基本信息，用于改进应用性能。\n• 应用使用数据：我们可能会收集您如何使用应用的信息，例如功能使用频率、应用崩溃记录等，用于优化用户体验。")
                    
                    Text("2. 信息的使用")
                        .font(.headline)
                    Text("我们使用收集的信息来：\n• 提供、维护和改进EasyHabit应用的功能和服务\n• 开发新功能和服务\n• 了解用户如何使用我们的应用，以改进用户体验\n• 向您发送有关应用更新或新功能的通知")
                    
                    Text("3. 信息的存储")
                        .font(.headline)
                    Text("我们采取以下措施保护您的信息安全：\n• 您的习惯数据主要存储在您的设备上\n• 如果您启用了云同步功能（高级版本），您的数据会加密存储在云服务上\n• 我们采取合理的技术措施保护您的数据不被未经授权的访问")
                }
                
                Group {
                    Text("4. 信息共享")
                        .font(.headline)
                    Text("除非有下列情况，我们不会与任何第三方分享您的个人信息：\n• 在法律要求下必须披露\n• 为了保护EasyHabit的合法权益\n• 获得您的明确同意")
                    
                    Text("5. 您的权利")
                        .font(.headline)
                    Text("您对自己的个人信息拥有以下权利：\n• 访问您的个人信息\n• 删除应用内所有数据\n• 导出您的数据\n• 随时停止使用我们的服务")
                    
                    Text("6. 儿童隐私")
                        .font(.headline)
                    Text("EasyHabit应用不面向16岁以下的儿童。如果您是父母或监护人，发现您的孩子未经您的同意向我们提供了个人信息，请通过应用内的\"用户反馈\"功能联系我们。")
                    
                    Text("7. 隐私政策更新")
                        .font(.headline)
                    Text("我们可能会不时更新本隐私政策。当我们进行重大更改时，我们会在应用内通知您。您继续使用应用将视为您接受修改后的隐私政策。")
                    
                    Text("8. 联系我们")
                        .font(.headline)
                    Text("如果您对本隐私政策有任何疑问，请通过应用中的\"用户反馈\"功能与我们联系。")
                    
                    Text("本隐私政策更新日期：2024年3月20日")
                        .italic()
                        .padding(.top)
                }
            }
            .padding()
        }
        .navigationTitle("隐私政策")
        .navigationBarTitleDisplayMode(.inline)
    }
}

