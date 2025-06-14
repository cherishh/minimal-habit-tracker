import SwiftUI
import Charts

/// 习惯详情页面，包含热力图和月历视图
struct HabitDetailView: View {
    let habitId: UUID
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismissAction
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingProAlert = false
    @State private var showingShareAlert = false
    @State private var selectedDate: Date = Date()
    
    // 获取当前年和月
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    
    // 通过计算属性获取最新的习惯数据
    private var habit: Habit {
        habitStore.habits.first(where: { $0.id == habitId }) ?? Habit(name: "未找到", emoji: "❓", colorTheme: .github, habitType: .checkbox)
    }
    
    @AppStorage("themeMode") private var themeMode: Int = 0 // 0: 自适应系统, 1: 明亮模式, 2: 暗黑模式
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 25) {
                // 年份选择器
                YearPicker(selectedYear: $selectedYear)
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                
                // GitHub风格热力图
                GitHubStyleHeatmapView(
                    habit: habit,
                    selectedYear: selectedYear,
                    colorScheme: colorScheme
                )
                .padding(.horizontal)
                .allowsHitTesting(true)
                
                // 热力图说明和操作栏
                heatmapLegendView
                
                Divider()
                    .padding(.horizontal)
                
                // 月历视图
                MonthCalendarView(
                    habit: habit, 
                    selectedYear: selectedYear,
                    selectedMonth: $selectedMonth
                )
                .padding(.horizontal)
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity)
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .navigationTitle("\(habit.emoji) \(habit.name)")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .enableSwipeBack()
        .toolbar {
            // 左侧返回按钮
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismissAction() }) {
                    Image("left")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .primaryWithOpacity(colorScheme: colorScheme)
                }
            }
            
            // 右侧操作按钮
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 8) {
                    // 分享按钮
                    Button(action: { 
                        showingShareAlert = true
                    }) {
                        Image("share")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .frame(width: 36, height: 36)
                            .background(Color(UIColor.systemGray5).opacity(0.6))
                            .cornerRadius(10)
                            .foregroundColor(.primary)
                    }
                    
                    // 编辑按钮(设置按钮)
                    Button(action: {
                        showingEditSheet = true
                    }) {
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
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            HabitFormView(isPresented: $showingEditSheet, habit: habit)
        }
        .alert("分享功能即将推出".localized(in: .habitDetail), isPresented: $showingShareAlert) {
            Button("好的".localized(in: .common), role: .cancel) { }
        } message: {
            Text("正在开发中，敬请期待".localized(in: .habitDetail))
        }
        .preferredColorScheme(getPreferredColorScheme())
        .onAppear {
            // 添加对习惯删除通知的监听
            NotificationCenter.default.addObserver(forName: NSNotification.Name("HabitDeleted"), object: nil, queue: .main) { notification in
                if let deletedHabitId = notification.object as? UUID, deletedHabitId == habitId {
                    // 如果删除的是当前正在查看的习惯，返回到列表页
                    dismissAction()
                }
            }
        }
        .onDisappear {
            // 移除通知监听
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("HabitDeleted"), object: nil)
        }
    }
    
    private var heatmapLegendView: some View {
        VStack(spacing: 10) {
            HStack {
                // 左侧显示统计数据
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("总计天数".localized(in: .habitDetail))
                            .font(.caption)
                            .foregroundColor(Color(hex: "#94a3b8"))
                        
                        Text("\(habitStore.getTotalLoggedDays(habitId: habit.id))" + "天".localized(in: .habitDetail))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(colorScheme == .dark ? Color(hex: "#e2e8f0") : Color(hex: "#334155"))
                    }
                    
                    HStack(spacing: 6) {
                        Text("最长连续".localized(in: .habitDetail))
                            .font(.caption)
                            .foregroundColor(Color(hex: "#94a3b8"))
                        
                        Text("\(habitStore.getLongestStreak(habitId: habit.id))" + "天".localized(in: .habitDetail))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(colorScheme == .dark ? Color(hex: "#e2e8f0") : Color(hex: "#334155"))
                    }
                    
                    HStack(spacing: 6) {
                        Text("本月打卡".localized(in: .habitDetail))
                            .font(.caption)
                            .foregroundColor(Color(hex: "#94a3b8"))
                        
                        Text("\(getMonthlyLoggedDays(year: selectedYear, month: selectedMonth))" + "天".localized(in: .habitDetail))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(colorScheme == .dark ? Color(hex: "#e2e8f0") : Color(hex: "#334155"))
                    }
                }
                
                Spacer()
                
                // 图例，仅在count类型时显示
                if habit.habitType == .count {
                    HStack(spacing: 4) {
                        Text("少".localized(in: .habitDetail))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        ForEach(1...min(habit.maxCheckInCount, 5), id: \.self) { level in
                            let theme = ColorTheme.getTheme(for: habit.colorTheme)
                            let colorLevel = habit.maxCheckInCount <= 5 ? 
                                (6 - habit.maxCheckInCount + (level - 1)) : // 小于等于5时的策略
                                (level <= habit.maxCheckInCount - 5 ? level : (habit.maxCheckInCount - 5) + level - (habit.maxCheckInCount - 5)) // 大于5时的策略
                            RoundedRectangle(cornerRadius: 2)
                                .fill(theme.color(for: colorLevel, isDarkMode: colorScheme == .dark))
                                .frame(width: 12, height: 12)
                        }
                        
                        Text("多".localized(in: .habitDetail))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    // 获取指定年月的打卡天数
    private func getMonthlyLoggedDays(year: Int, month: Int) -> Int {
        let calendar = Calendar.current
        var count = 0
        
        // 创建当前月份的范围
        let components = DateComponents(year: year, month: month)
        guard let firstDay = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDay) else {
            return 0
        }
        
        // 遍历当月每一天，检查是否打卡
        for day in range {
            let components = DateComponents(year: year, month: month, day: day)
            if let date = calendar.date(from: components) {
                if habitStore.getLogCountForDate(habitId: habit.id, date: date) > 0 {
                    count += 1
                }
            }
        }
        
        return count
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

// 月历视图
struct MonthCalendarView: View {
    let habit: Habit
    let selectedYear: Int
    @Binding var selectedMonth: Int
    @EnvironmentObject var habitStore: HabitStore
    @State private var dragOffset: CGFloat = 0
    @State private var isAnimating: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    // 一周的天数 - 从星期一开始
    private let daysOfWeek = ["一", "二", "三", "四", "五", "六", "日"]
    
    var body: some View {
        VStack(spacing: 15) {
            // 月份选择器
            HStack {
                
                Spacer()
                
                Text(getLocalizedMonthText(month: selectedMonth))
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .primary.opacity(0.8) : .primary)
                
                Spacer()

                Button(action: previousMonth) {
                    Image("left")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .frame(width: 30, height: 30)
                        .background(Color(UIColor.systemGray5).opacity(0.6))
                        .cornerRadius(8)
                        .primaryWithOpacity(colorScheme: colorScheme)
                }
                
                Button(action: nextMonth) {
                    Image("right")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .frame(width: 30, height: 30)
                        .background(Color(UIColor.systemGray5).opacity(0.6))
                        .cornerRadius(8)
                        .primaryWithOpacity(colorScheme: colorScheme)
                }
                
                Button(action: goToCurrentMonth) {
                    Image("locate")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .frame(width: 30, height: 30)
                        .background(Color(UIColor.systemGray5).opacity(0.6))
                        .cornerRadius(8)
                        .foregroundColor(.primary)
                }
                .padding(.leading, 10)
            }
            
            // 星期标题
            HStack {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day.localized(in: .habitDetail))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 日历网格 - 使用固定高度的ZStack
            ZStack(alignment: .top) {
                // 当前月
                calendarGrid(for: selectedMonth)
                    .offset(x: dragOffset)
                
                // 上个月（左侧）
                calendarGrid(for: previousMonthNumber())
                    .offset(x: dragOffset - UIScreen.main.bounds.width)
                
                // 下个月（右侧）
                calendarGrid(for: nextMonthNumber())
                    .offset(x: dragOffset + UIScreen.main.bounds.width)
            }
            .frame(height: 280) // 增加高度，确保能完整显示所有内容
            .padding(.top, 5) // 顶部增加一点内边距
            .clipped() // 防止超出部分显示
            .gesture(
                DragGesture(minimumDistance: 15) // 增加最小识别距离，减少误触
                    .onChanged { value in
                        // 只有在水平滑动且未在动画过程中才处理手势
                        // 判断水平滑动 - 水平位移大于垂直位移的1.5倍
                        let isHorizontalDrag = abs(value.translation.width) > abs(value.translation.height) * 1.5
                        
                        if isHorizontalDrag && !isAnimating {
                            dragOffset = value.translation.width
                        } else {
                            // 如果不是水平滑动或已经在动画中，则重置偏移
                            if dragOffset != 0 {
                                withAnimation(.spring()) {
                                    dragOffset = 0
                                }
                            }
                        }
                    }
                    .onEnded { value in
                        // 判断水平滑动 - 水平位移大于垂直位移的1.5倍
                        let isHorizontalDrag = abs(value.translation.width) > abs(value.translation.height) * 1.5
                        
                        // 只有在水平滑动时才处理月份切换
                        if isHorizontalDrag {
                            isAnimating = true
                            
                            // 确定滑动方向和距离是否足够切换月份
                            if value.translation.width > 50 {
                                // 向右滑动超过阈值 - 切换到上个月
                                withAnimation(.easeOut(duration: 0.15)) {
                                    dragOffset = UIScreen.main.bounds.width
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    previousMonth()
                                    dragOffset = 0
                                    isAnimating = false
                                }
                            } else if value.translation.width < -50 {
                                // 向左滑动超过阈值 - 切换到下个月
                                withAnimation(.easeOut(duration: 0.15)) {
                                    dragOffset = -UIScreen.main.bounds.width
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    nextMonth()
                                    dragOffset = 0
                                    isAnimating = false
                                }
                            } else {
                                // 不足以切换，回到当前月
                                withAnimation(.easeOut(duration: 0.15)) {
                                    dragOffset = 0
                                    isAnimating = false
                                }
                            }
                        } else {
                            // 非水平滑动时重置状态
                            if dragOffset != 0 {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    dragOffset = 0
                                }
                            }
                            isAnimating = false
                        }
                    }
            )
        }
    }
    
    // 获取当月总天数
    private func getDaysInCurrentMonth() -> Int {
        let calendar = Calendar.current
        let components = DateComponents(year: selectedYear, month: selectedMonth)
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 30
        }
        return range.count
    }
    
    // 提取日历网格为单独的视图
    private func calendarGrid(for month: Int) -> some View {
        let currentYear = selectedYear
        // 对于12月到1月跨年的情况，调整年份
        let adjustedYear = (selectedMonth == 12 && month == 1) ? currentYear + 1 :
                           (selectedMonth == 1 && month == 12) ? currentYear - 1 : currentYear
        
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
            ForEach(daysInMonth(for: month, year: adjustedYear).indices, id: \.self) { index in
                let day = daysInMonth(for: month, year: adjustedYear)[index]
                if day.day > 0 {
                    DayCell(date: day.date, habit: habit)
                } else {
                    Color.clear
                        .frame(height: 40)
                }
            }
        }
        .frame(minHeight: 230) // 确保最小高度足够
    }
    
    // 获取前一个月的月份数
    private func previousMonthNumber() -> Int {
        selectedMonth > 1 ? selectedMonth - 1 : 12
    }
    
    // 获取后一个月的月份数
    private func nextMonthNumber() -> Int {
        selectedMonth < 12 ? selectedMonth + 1 : 1
    }
    
    // 获取指定月份和年份的所有日期
    private func daysInMonth(for month: Int, year: Int) -> [(day: Int, date: Date)] {
        let calendar = Calendar.current
        
        // 创建指定年月的日期
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        
        guard let firstDayOfMonth = calendar.date(from: components) else {
            return []
        }
        
        // 计算这个月的第一天是星期几 (调整为周一为0)
        var firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        // 调整为周一为0，周日为6
        firstWeekday = (firstWeekday + 6) % 7
        
        // 这个月有多少天
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)?.count ?? 0
        
        var result: [(day: Int, date: Date)] = []
        
        // 添加前面的空白
        for _ in 0..<firstWeekday {
            result.append((0, Date()))
        }
        
        // 添加这个月的天数
        for day in 1...daysInMonth {
            components.day = day
            if let date = calendar.date(from: components) {
                result.append((day, date))
            }
        }
        
        // 如果行数不足6行，添加额外的空白单元格以保持一致的高度
        let totalCells = result.count
        let cellsInCompleteWeeks = (totalCells + 6) / 7 * 7 // 向上取整到完整的周
        if cellsInCompleteWeeks < 42 { // 6行 x 7列 = 42个单元格
            for _ in totalCells..<42 {
                result.append((0, Date()))
            }
        }
        
        return result
    }
    
    private func previousMonth() {
        if selectedMonth > 1 {
            selectedMonth -= 1
        } else {
            selectedMonth = 12
            // 可以选择是否自动减少年份
        }
    }
    
    private func nextMonth() {
        if selectedMonth < 12 {
            selectedMonth += 1
        } else {
            selectedMonth = 1
            // 可以选择是否自动增加年份
        }
    }
    
    // 移动到当前月
    private func goToCurrentMonth() {
        let currentMonth = Calendar.current.component(.month, from: Date())
        selectedMonth = currentMonth
    }
    
    // 获取本地化的月份文本
    private func getLocalizedMonthText(month: Int) -> String {
        return "\(month)月".localized(in: .habitDetail)
    }
}

// 单日单元格
struct DayCell: View {
    let date: Date
    let habit: Habit
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.colorScheme) var colorScheme
    @State private var animatedCompletion: Double = 0
    @State private var isAnimating: Bool = false
    
    private var isFutureDate: Bool {
        date > Date()
    }
    
    var body: some View {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let count = habitStore.getLogCountForDate(habitId: habit.id, date: date)
        let theme = ColorTheme.getTheme(for: habit.colorTheme)
        let isToday = calendar.isDateInToday(date)
        let completionPercentage = Double(min(count, habit.maxCheckInCount)) / Double(habit.maxCheckInCount) // 完成进度百分比
        
        ZStack {
            // 今日背景 - 使用主题第二浅的颜色(level 1)但添加透明度
            Circle()
                .fill(isToday ? theme.color(for: 1, isDarkMode: colorScheme == .dark).opacity(0.5) : Color.clear)
                .frame(height: 40)
            
            // 只有已打卡日期才显示圆环
            if count > 0 || isAnimating {
                // 使用habit.habitType判断是否为checkbox类型
                if habit.habitType == .checkbox {
                    // checkbox类型显示完整圆环，但是有动画
                    Circle()
                        .trim(from: 0, to: isAnimating ? animatedCompletion : 1.0)
                        .stroke(
                            colorScheme == .dark 
                                ? theme.color(for: min(habit.maxCheckInCount, 4), isDarkMode: true)
                                : theme.color(for: min(habit.maxCheckInCount, 5), isDarkMode: false),
                            style: StrokeStyle(
                                lineWidth: 3.5,
                                lineCap: .round,    // 圆形线帽
                                lineJoin: .round    // 圆形连接
                            )
                        )
                        .frame(height: 37)
                        .rotationEffect(.degrees(-90)) // 从顶部开始
                } else {
                    // 轨道圆环（底色）- 使用最浅色
                    Circle()
                        .stroke(
                            theme.color(for: 0, isDarkMode: colorScheme == .dark),
                            style: StrokeStyle(lineWidth: 3.5)
                        )
                        .frame(height: 37)
                    
                    // count类型显示部分圆环
                    Circle()
                        .trim(from: 0, to: isAnimating ? animatedCompletion : completionPercentage)
                        .stroke(
                            colorScheme == .dark 
                                ? theme.color(for: min(habit.maxCheckInCount, 4), isDarkMode: true)
                                : theme.color(for: 5, isDarkMode: false),
                            style: StrokeStyle(
                                lineWidth: 3.5,
                                lineCap: .round,    // 圆形线帽
                                lineJoin: .round    // 圆形连接
                            )
                        )
                        .frame(height: 37)
                        .rotationEffect(.degrees(-90)) // 从顶部开始
                }
            }
            
            // 日期文字
            Text("\(day)")
                .foregroundColor(
                    isToday ? .primary : // 今日日期 - 始终使用主色
                    (isFutureDate ? .gray.opacity(0.2) : // 未来日期 - 最浅
                    (count == 0 ? .gray.opacity(0.8) : .primary)) // 过去未打卡 - 中等，已打卡 - 最深
                )
                .font(.system(size: 14))
        }
        .contentShape(Circle())
        .onTapGesture {
            if !isFutureDate {
                // 获取当前日期的计数
                let currentCount = habitStore.getLogCountForDate(habitId: habit.id, date: date)
                
                // 计算点击后的新计数
                var newCount = currentCount
                if habit.habitType == .checkbox {
                    // 对于checkbox，如果已有计数则变为0，否则变为自定义的最大值
                    newCount = (currentCount > 0) ? 0 : habit.maxCheckInCount
                } else {
                    // 对于count，计数加1，如果达到自定义的最大值则重置为0
                    newCount = (currentCount >= habit.maxCheckInCount) ? 0 : currentCount + 1
                }
                
                // 设置动画的起点和终点
                let startCompletion = Double(min(currentCount, habit.maxCheckInCount)) / Double(habit.maxCheckInCount)
                let targetCompletion = Double(min(newCount, habit.maxCheckInCount)) / Double(habit.maxCheckInCount)
                
                // 先执行实际的打卡操作
                habitStore.logHabit(habitId: habit.id, date: date)
                
                // 设置动画
                isAnimating = true
                animatedCompletion = startCompletion
                
                // 使用withAnimation创建流畅的动画效果
                withAnimation(.easeInOut(duration: 0.3)) {
                    if newCount == 0 {
                        // 如果是取消打卡，动画应该从当前位置返回到0
                        animatedCompletion = 0
                    } else {
                        // 否则动画应该前进到新位置
                        animatedCompletion = targetCompletion
                    }
                }
                
                // 重置动画状态
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isAnimating = false
                }
            }
        }
        .disabled(isFutureDate)
        // 确保在初始渲染时设置正确的animatedCompletion值
        .onAppear {
            animatedCompletion = completionPercentage
        }
        // 确保在count改变时更新animatedCompletion值
        .onChange(of: count) { oldValue, newValue in
            animatedCompletion = Double(min(newValue, habit.maxCheckInCount)) / Double(habit.maxCheckInCount)
        }
    }
}

struct YearPicker: View {
    @Binding var selectedYear: Int
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Button(action: previousYear) {
                Image("left")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .primaryWithOpacity(colorScheme: colorScheme)
            }
            
            Spacer()
            
            Text(String(format: "%d", selectedYear))
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .primary.opacity(0.8) : .primary)
            
            Spacer()
            
            Button(action: nextYear) {
                Image("right")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .primaryWithOpacity(colorScheme: colorScheme)
            }
            
            // Button(action: goToCurrentYear) {
            //     Image("locate")
            //         .resizable()
            //         .renderingMode(.template)
            //         .scaledToFit()
            //         .frame(width: 16, height: 16)
            //         .frame(width: 32, height: 32)
            //         .background(Color(UIColor.systemGray5).opacity(0.6))
            //         .cornerRadius(8)
            //         .foregroundColor(.primary)
            // }
            // .padding(.leading, 10)
        }
    }
    
    private func previousYear() {
        selectedYear -= 1
    }
    
    private func nextYear() {
        selectedYear += 1
    }
    
    private func goToCurrentYear() {
        selectedYear = Calendar.current.component(.year, from: Date())
    }
}

struct GitHubStyleHeatmapView: View {
    let habit: Habit
    let selectedYear: Int
    let colorScheme: ColorScheme
    @EnvironmentObject var habitStore: HabitStore
    
    // 星期标签 - 显示周一、三、五、日
    private let weekdayLabels = ["一", "", "三", "", "五", "", "日"]
    // 月份标签
    private let monthLabels = ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 热力图主体
            HStack(alignment: .top, spacing: 8) {  // 恢复必要的间隙为4
                // 星期标签 - 使用精确定位
                VStack(alignment: .trailing) {
                    Spacer().frame(height: 24)  // 为月份标签留出空间
                    
                    VStack(spacing: cellSpacing) {
                        Text(formatHeatmapWeekday("一")).font(.caption2).foregroundColor(.secondary).frame(width: 18, height: cellWidth)
                        Text("").frame(height: cellWidth)  // 空行
                        Text(formatHeatmapWeekday("三")).font(.caption2).foregroundColor(.secondary).frame(width: 18, height: cellWidth)
                        Text("").frame(height: cellWidth)  // 空行
                        Text(formatHeatmapWeekday("五")).font(.caption2).foregroundColor(.secondary).frame(width: 18, height: cellWidth)
                        Text("").frame(height: cellWidth)  // 空行
                        Text(formatHeatmapWeekday("日")).font(.caption2).foregroundColor(.secondary).frame(width: 18, height: cellWidth)
                    }
                }
                .frame(width: 19)  // 最小宽度
                .offset(y: 4)  // 微调下移1.5像素使其与格子完美对齐
                
                // 格子网格和月份标签
                ScrollView(.horizontal, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 4) {
                        // 月份标签
                        ZStack(alignment: .topLeading) {
                            // 空白背景，用于填充空间
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: CGFloat(53) * (cellWidth + cellSpacing), height: 20)
                            
                            // 月份标签
                            ForEach(monthPositions, id: \.0) { month, exactPosition in
                                Text(formatHeatmapMonth(month))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .position(x: CGFloat(exactPosition) * (cellWidth + cellSpacing) + cellWidth/2 + 3, y: 10)
                            }
                        }
                        .padding(.bottom, 4)
                        
                        // 格子网格
                        LazyHGrid(rows: rows, spacing: cellSpacing) {
                            ForEach(daysInYear, id: \.self) { date in
                                DayCellGitHub(
                                    date: date,
                                    habit: habit,
                                    colorScheme: colorScheme
                                )
                            }
                        }
                    }
                    // 固定内容宽度以确保显示完整的一年
                    .frame(width: CGFloat(53) * (cellWidth + cellSpacing))
                }
                .simultaneousGesture(
                    // 添加手势修饰符，防止ScrollView的手势阻止整体页面的滚动
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in }
                )
            }
        }
    }
    
    // 配置
    private let cellWidth: CGFloat = 12
    private let cellSpacing: CGFloat = 3
    private var rows: [GridItem] {
        Array(repeating: GridItem(.fixed(cellWidth), spacing: cellSpacing), count: 7)
    }
    
    // 计算选定年份的所有日期 - 调整为周一开始
    private var daysInYear: [Date] {
        let calendar = Calendar.current
        let startDateComponents = DateComponents(year: selectedYear, month: 1, day: 1)
        guard let startDate = calendar.date(from: startDateComponents) else { return [] }
        
        // 计算起始日期需要补充的天数，使第一列为星期一
        var startWeekday = calendar.component(.weekday, from: startDate)
        // 转换为周一为1，周日为7的系统
        startWeekday = startWeekday == 1 ? 7 : startWeekday - 1
        let daysToAddAtStart = startWeekday - 1 // 1是星期一
        
        // 计算应该显示多少天（考虑前后填充）
        let endDateComponents = DateComponents(year: selectedYear, month: 12, day: 31)
        guard let endDate = calendar.date(from: endDateComponents) else { return [] }
        
        // 计算结束日期之后需要补充的天数，使最后一列完整
        var endWeekday = calendar.component(.weekday, from: endDate)
        // 转换为周一为1，周日为7的系统
        endWeekday = endWeekday == 1 ? 7 : endWeekday - 1
        let daysToAddAtEnd = 7 - endWeekday // 如果是周日则为0
        
        let totalDaysToShow = daysToAddAtStart + calendar.dateComponents([.day], from: startDate, to: endDate).day! + 1 + daysToAddAtEnd
        
        // 生成日期数组
        var days: [Date] = []
        for dayOffset in -daysToAddAtStart..<(totalDaysToShow - daysToAddAtStart) {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) {
                days.append(date)
            }
        }
        
        return days
    }
    
    // 计算每个月的标签位置 - 更精确的定位
    private var monthPositions: [(Int, Int)] {
        let calendar = Calendar.current
        var positions: [(Int, Int)] = []
        
        if daysInYear.isEmpty { return [] }
        
        for month in 1...12 {
            guard let date = calendar.date(from: DateComponents(year: selectedYear, month: month, day: 1)) else { continue }
            
            // 找到这个月在daysInYear数组中的索引
            if let index = daysInYear.firstIndex(where: { calendar.isDate($0, equalTo: date, toGranularity: .day) }) {
                // 直接使用索引计算列位置
                positions.append((month, index / 7))
            }
        }
        
        return positions
    }
    
    // 获取热力图月份的格式化字符串
    private func formatHeatmapMonth(_ month: Int) -> String {
        // 直接使用habitStore的语言设置而不是系统locale
        let language = HabitStore.shared.appLanguage
        
        // 如果设置为简体中文或系统默认但系统语言是简体中文
        if language == "zh-Hans" || (language.isEmpty && Locale.preferredLanguages.first?.hasPrefix("zh") == true 
            && !Locale.preferredLanguages.first!.hasPrefix("zh-Hant")) {
            // 直接返回简体中文月份
            return "\(month)月"
        }
        
        // 如果设置为英文或系统默认但系统语言是英文
        if language == "en" || (language.isEmpty && Locale.preferredLanguages.first?.hasPrefix("en") == true) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "MMM"
            if let date = Calendar.current.date(from: DateComponents(year: 2000, month: month, day: 1)) {
                return formatter.string(from: date)
            }
        }
        
        // 使用专门为热力图定义的本地化键
        return "热图.\(month)月".localized(in: .habitDetail)
    }
    
    // 获取热力图星期标签的格式化字符串
    private func formatHeatmapWeekday(_ weekday: String) -> String {
        // 直接使用habitStore的语言设置而不是系统locale
        let language = HabitStore.shared.appLanguage
        
        // 如果设置为简体中文或系统默认但系统语言是简体中文
        if language == "zh-Hans" || (language.isEmpty && Locale.preferredLanguages.first?.hasPrefix("zh") == true 
            && !Locale.preferredLanguages.first!.hasPrefix("zh-Hant")) {
            // 直接返回简体中文星期
            return weekday
        }
        
        // 如果设置为英文或系统默认但系统语言是英文
        if language == "en" || (language.isEmpty && Locale.preferredLanguages.first?.hasPrefix("en") == true) {
            switch weekday {
            case "一": return "Mo"
            case "三": return "We"
            case "五": return "Fr"
            case "日": return "Su"
            default: return weekday
            }
        }
        
        // 使用专门为热力图定义的本地化键
        return "热图.\(weekday)".localized(in: .habitDetail)
    }
}

struct DayCellGitHub: View {
    let date: Date
    let habit: Habit
    let colorScheme: ColorScheme
    @EnvironmentObject var habitStore: HabitStore
    
    private var isCurrentYear: Bool {
        Calendar.current.component(.year, from: date) == Calendar.current.component(.year, from: Date())
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var isFutureDate: Bool {
        date > Date()
    }
    
    private var isFirstDayOfMonth: Bool {
        Calendar.current.component(.day, from: date) == 1
    }
    
    private var logCount: Int {
        habitStore.getLogCountForDate(habitId: habit.id, date: date)
    }
    
    private var theme: ColorTheme {
        ColorTheme.getTheme(for: habit.colorTheme)
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(theme.colorForCount(count: logCount, maxCount: habit.maxCheckInCount, isDarkMode: colorScheme == .dark))
                .opacity(isCurrentYear ? 1.0 : 0.6)
            
            if isToday {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.primary, lineWidth: 1)
            }
            
            // 在每月1号的格子中显示数字"1"
            if isFirstDayOfMonth {
                Text("1")
                    .font(.system(size: 8))
                    .foregroundColor(logCount > 2 ? .white : (colorScheme == .dark ? .white : .black))
                    .opacity(0.8)
            }
        }
        .frame(width: 12, height: 12)
        .contentShape(Rectangle())
        .help(tooltipText)
        .disabled(true)
    }
    
    private var tooltipText: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        
        return "\(dateFormatter.string(from: date)): \(logCount)次"
    }
}

#Preview {
    NavigationView {
        HabitDetailView(habitId: UUID())
        .environmentObject(HabitStore())
    }
} 