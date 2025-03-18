//
//  ContentView.swift
//  minimal habit tracker
//
//  Created by 王仲玺 on 2025/3/6.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var habitStore: HabitStore
    @State private var isAddingHabit = false
    @State private var showingSettings = false
    @State private var selectedHabit: Habit?
    @State private var selectedHabitId: UUID?
    @State private var navigateToDetail = false
    @State private var showingSortSheet = false
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showingMaxHabitsAlert = false
    
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
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            if habitStore.canAddHabit() {
                                isAddingHabit = true
                            } else {
                                showingMaxHabitsAlert = true
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
                                .foregroundColor(.primary)
                        }
                        
                        Button(action: { showingSortSheet = true }) {
                            Image(systemName: "arrow.up.arrow.down")
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .frame(width: 36, height: 36)
                                .background(Color(UIColor.systemGray5).opacity(0.6))
                                .cornerRadius(10)
                                .foregroundColor(.primary)
                        }
                        .disabled(habitStore.habits.isEmpty)
                        
                        Button(action: { showingSettings = true }) {
                            Image("settings")
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .frame(width: 36, height: 36)
                                .background(Color(UIColor.systemGray5).opacity(0.6))
                                .cornerRadius(10)
                                .foregroundColor(.primary)
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
            .sheet(isPresented: $isAddingHabit) {
                NewHabitView(isPresented: $isAddingHabit)
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
                    message: Text("您最多只能创建4个习惯。如需添加更多，请升级为Pro版本。"),
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
            
            Text("添加第一个习惯")
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.bottom, 40)
            
            // 大一点的添加按钮
            Button(action: { 
                if habitStore.canAddHabit() {
                    isAddingHabit = true
                } else {
                    showingMaxHabitsAlert = true
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
                            habitStore.removeHabit(habit)
                        }
                    })
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
        }
        .background(lightBackgroundColor)
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
    
    // 获取习惯的主题颜色
    private var theme: ColorTheme {
        let habit = habitStore.habits.first(where: { $0.id == habitId }) ?? Habit(name: "未找到", emoji: "❓", colorTheme: .github, habitType: .checkbox)
        return ColorTheme.getTheme(for: habit.colorTheme)
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
                                .fill(theme.color(for: min(count, HabitStore.maxCheckInCount), isDarkMode: colorScheme == .dark))
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
        return min(count / CGFloat(HabitStore.maxCheckInCount), 1.0)
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
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                
                Spacer()
                
                // 连续打卡天数
                if currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundColor(theme.color(for: 5, isDarkMode: colorScheme == .dark))
                        
                        Text("\(currentStreak)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(theme.color(for: 5, isDarkMode: colorScheme == .dark))
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
                // 圆环
                if habit.habitType == .checkbox {
                    // Checkbox型习惯的圆环 - 先显示底色轨道
                    Circle()
                        .stroke(
                            theme.color(for: 1, isDarkMode: colorScheme == .dark).opacity(0.4),
                            style: StrokeStyle(lineWidth: 10)
                        )
                        .frame(width: 64, height: 64)
                    
                    // 完成圆环
                        Circle()
                        .trim(from: 0, to: isCompletedToday ? 1 : 0)
                        .stroke(
                            theme.color(for: 5, isDarkMode: colorScheme == .dark),
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
                            theme.color(for: 1, isDarkMode: colorScheme == .dark).opacity(0.4),
                            style: StrokeStyle(lineWidth: 10)
                        )
                        .frame(width: 64, height: 64)
                    
                    // 进度环
                            Circle()
                        .trim(from: 0, to: isAnimating ? animatedCompletion : countProgress)
                        .stroke(
                            theme.color(for: 5, isDarkMode: colorScheme == .dark),
                            style: StrokeStyle(
                                lineWidth: 10,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                }
                
                // Emoji
                Text(habit.emoji)
                    .font(.system(size: 28))
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
            // 对于checkbox，如果已有计数则变为0，否则变为5
            newCount = (currentCount > 0) ? 0 : HabitStore.maxCheckInCount
        } else {
            // 对于count，计数加1，如果达到5则重置为0
            newCount = (currentCount >= HabitStore.maxCheckInCount) ? 0 : currentCount + 1
        }
        
        // 设置动画的起点和终点
        let startCompletion = Double(min(currentCount, HabitStore.maxCheckInCount)) / Double(HabitStore.maxCheckInCount)
        let targetCompletion = Double(min(newCount, HabitStore.maxCheckInCount)) / Double(HabitStore.maxCheckInCount)
        
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
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("显示")) {
                    Toggle("暗黑模式", isOn: $isDarkMode)
                }
                
                Section(header: Text("关于")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: Text("关于页面内容").padding()) {
                        Text("关于习惯追踪")
                    }
                }
            }
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                isPresented = false
                    }
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

#Preview {
    ContentView()
        .environmentObject(HabitStore())
}
