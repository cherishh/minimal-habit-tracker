import SwiftUI

struct HabitDetailView: View {
    let habit: Habit
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.colorScheme) var colorScheme
    @State private var showingSettings = false
    
    // 获取当前年
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // 年份选择器
                YearPicker(selectedYear: $selectedYear)
                    .padding()
                
                // GitHub风格热力图
                GitHubStyleHeatmapView(
                    habit: habit,
                    selectedYear: selectedYear,
                    colorScheme: colorScheme
                )
                .padding()
                
                // 底部说明和操作栏
                HStack {
                    Text("点击格子记录完成习惯，可多次点击")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // 图例
                    HStack(spacing: 4) {
                        Text("少")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        ForEach(0..<5) { level in
                            let theme = ColorTheme.getTheme(for: habit.colorTheme)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(theme.color(for: level, isDarkMode: colorScheme == .dark))
                                .frame(width: 12, height: 12)
                        }
                        
                        Text("多")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                            .foregroundColor(.primary)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(habit.name)
        .sheet(isPresented: $showingSettings) {
            HabitSettingsView(habit: habit, isPresented: $showingSettings)
        }
    }
}

struct YearPicker: View {
    @Binding var selectedYear: Int
    
    var body: some View {
        HStack {
            Button(action: previousYear) {
                Image(systemName: "chevron.left")
            }
            
            Spacer()
            
            Text("\(selectedYear)年")
                .font(.headline)
            
            Spacer()
            
            Button(action: nextYear) {
                Image(systemName: "chevron.right")
            }
            
            Button(action: goToCurrentYear) {
                Text("今年")
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.leading, 10)
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

// 自定义PreferenceKey用于获取滚动位置
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct GitHubStyleHeatmapView: View {
    let habit: Habit
    let selectedYear: Int
    let colorScheme: ColorScheme
    @EnvironmentObject var habitStore: HabitStore
    
    // 添加放大镜相关状态
    @State private var isLongPressing = false {
        didSet {
            print("isLongPressing状态改变: \(oldValue) -> \(isLongPressing)")
        }
    }
    @State private var longPressLocation: CGPoint = .zero
    @State private var longPressDate: Date? = nil
    @State private var longPressedCellIndex: Int? = nil
    
    // 添加标记位置是否在热力图区域内
    @State private var isLocationInHeatmap: Bool = false
    
    // 记录成功的视觉反馈
    @State private var showSuccessFeedback = false
    @State private var successFeedbackDate: Date? = nil
    
    // 滚动位置控制 - 初始值设为0
    @State private var scrollPosition: CGFloat = 0
    
    // 对滚动位置进行监控的标志
    @State private var isScrollPositionInitialized = false
    
    // 星期标签 - 显示周一、三、五、日
    private let weekdayLabels = ["一", "", "三", "", "五", "", ""]
    // 月份标签
    private let monthLabels = ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"]
    
    // 放大镜配置
    private let magnifierRadius: CGFloat = 70
    private let magnificationFactor: CGFloat = 2.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 热力图主体
            HStack(alignment: .top, spacing: 8) {  // 恢复必要的间隙为4
                // 星期标签 - 使用精确定位
                VStack(alignment: .trailing) {
                    Spacer().frame(height: 24)  // 为月份标签留出空间
                    
                    VStack(spacing: cellSpacing) {
                        Text("一").font(.caption2).foregroundColor(.secondary).frame(height: cellWidth)
                        Text("").frame(height: cellWidth)  // 空行
                        Text("三").font(.caption2).foregroundColor(.secondary).frame(height: cellWidth)
                        Text("").frame(height: cellWidth)  // 空行
                        Text("五").font(.caption2).foregroundColor(.secondary).frame(height: cellWidth)
                        Text("").frame(height: cellWidth)  // 空行
                        Text("").font(.caption2).foregroundColor(.secondary).frame(height: cellWidth)
                    }
                }
                .frame(width: 15)  // 最小宽度
                .offset(y: 4)  // 微调下移1.5像素使其与格子完美对齐
                
                // 格子网格和月份标签
                ZStack {
                    GeometryReader { geometry in
                        // 滚动视图内容
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
                                        Text(monthLabels[month - 1])
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .position(x: CGFloat(exactPosition) * (cellWidth + cellSpacing) + cellWidth/2, y: 10)
                                    }
                                }
                                .padding(.bottom, 4)
                                
                                // 测试区域 - 调试用
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 20)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        print("顶部测试区域点击")
                                    }
                                    .onLongPressGesture(minimumDuration: 0.5) {
                                        print("顶部测试区域长按")
                                        isLongPressing = !isLongPressing // 切换长按状态用于测试
                                    }
                                
                                // 格子网格
                                LazyHGrid(rows: rows, spacing: cellSpacing) {
                                    ForEach(Array(daysInYear.enumerated()), id: \.element) { index, date in
                                        DayCellGitHub(
                                            date: date,
                                            habit: habit,
                                            colorScheme: colorScheme,
                                            showDate: isLongPressing,
                                            isCurrentSelected: longPressedCellIndex == index
                                        )
                                        .id(index)
                                    }
                                }
                            }
                            // 固定内容宽度以确保显示完整的一年
                            .frame(width: CGFloat(53) * (cellWidth + cellSpacing))
                            // 使用背景获取滚动位置
                            .background(
                                GeometryReader { innerGeometry in
                                    Color.clear.preference(
                                        key: ScrollOffsetPreferenceKey.self,
                                        value: geometry.frame(in: .global).minX - innerGeometry.frame(in: .global).minX
                                    )
                                }
                            )
                            // 不再使用offset，因为会干扰滚动计算
                        }
                        .id("heatmapScroll") // 给ScrollView一个固定ID，防止长按时重建视图
                        .disabled(isLongPressing) // 长按时禁用滚动
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            // 记录当前滚动位置
                            let oldValue = scrollPosition
                            scrollPosition = value
                            
                            // 打印滚动位置变化
                            if abs(oldValue - value) > 1 {
                                print("=============================================")
                                print("滚动位置更新: \(oldValue) -> \(value), 变化量: \(value - oldValue)")
                                
                                // 计算可见区域信息
                                let gridWidth = cellWidth + cellSpacing
                                let visibleStartColumn = Int(abs(scrollPosition) / gridWidth)
                                let visibleEndColumn = visibleStartColumn + Int(UIScreen.main.bounds.width / gridWidth)
                                print("可见区域起始列: \(visibleStartColumn), 结束列: \(visibleEndColumn)")
                            }
                        }
                        .onAppear {
                            // 初始化时确保滚动位置被正确设置
                            print("热力图视图出现，初始滚动位置: \(scrollPosition)")
                            
                            // 初始化滚动位置标志
                            isScrollPositionInitialized = true
                            
                            // 打印热力图的基本信息
                            print("热力图包含日期数量: \(daysInYear.count)")
                            print("热力图总列数: \(daysInYear.count / 7)")
                        }
                        .highPriorityGesture(
                            // 使用高优先级手势，确保长按能被识别
                            LongPressGesture(minimumDuration: 0.5)
                                .onEnded { _ in
                                    print("=============================================")
                                    print("高优先级长按手势触发")
                                    isLongPressing = true
                                    // 打印长按开始时的滚动位置，确保调试信息完整
                                    print("长按开始时的滚动位置: \(scrollPosition)")
                                    
                                    // 计算当前可见区域
                                    let gridWidth = cellWidth + cellSpacing
                                    let visibleStartColumn = Int(abs(scrollPosition) / gridWidth)
                                    let visibleEndColumn = visibleStartColumn + Int(UIScreen.main.bounds.width / gridWidth)
                                    print("可见区域: 起始列\(visibleStartColumn), 结束列\(visibleEndColumn)")
                                    print("热力图总日期数: \(daysInYear.count)")
                                }
                        )
                        .simultaneousGesture(
                            // 当处于长按状态时跟踪拖动
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if isLongPressing {
                                        print("=============================================")
                                        print("拖动中: 位置=\(value.location)")
                                        longPressLocation = value.location
                                        
                                        // 更新长按位置和日期
                                        let (inHeatmap, index) = updateLongPressedDate(at: value.location)
                                        isLocationInHeatmap = inHeatmap
                                        
                                        // 添加更多调试信息
                                        if let date = longPressDate {
                                            print("当前长按日期: \(formatDate(date)), 索引: \(index), 在热力图内: \(inHeatmap)")
                                            print("长按索引变化: \(String(describing: longPressedCellIndex))")
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    print("=============================================")
                                    print("拖动结束, 位置在热力图内: \(isLocationInHeatmap)")
                                    
                                    // 添加更多日志记录
                                    if let date = longPressDate {
                                        print("拖动结束时的日期: \(formatDate(date)), 在热力图内: \(isLocationInHeatmap)")
                                        print("最终长按索引: \(String(describing: longPressedCellIndex))")
                                        if let index = longPressedCellIndex, index >= 0 && index < daysInYear.count {
                                            print("索引对应的实际日期: \(formatDate(daysInYear[index]))")
                                        }
                                    }
                                    
                                    // 只有当手指在热力图区域内抬起时，才添加记录
                                    if isLocationInHeatmap, let date = longPressDate, !isFutureDate(date) {
                                        habitStore.logHabit(habitId: habit.id, date: date)
                                        print("长按记录习惯：\(formatDate(date))")
                                        
                                        // 显示成功反馈
                                        successFeedbackDate = date
                                        showSuccessFeedback = true
                                        
                                        // 1.5秒后自动隐藏
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            showSuccessFeedback = false
                                        }
                                    } else if !isLocationInHeatmap {
                                        print("手指在热力图外抬起，取消添加记录")
                                    } else if let date = longPressDate, isFutureDate(date) {
                                        print("未来日期，取消添加记录: \(formatDate(date))")
                                    }
                                    
                                    // 重置状态
                                    isLongPressing = false
                                    longPressDate = nil
                                    longPressedCellIndex = nil
                                    isLocationInHeatmap = false
                                }
                        )
                    }
                    
                    // 放大镜层 - 仅在长按时显示
                    if isLongPressing {
                        // 打印创建放大镜时的关键信息
                        let _ = print("=============================================")
                        let _ = print("创建放大镜视图 (MagnifierView创建):")
                        let _ = print("- 长按日期: \(longPressDate?.description ?? "nil")")
                        let _ = print("- 长按索引: \(longPressedCellIndex?.description ?? "nil")")
                        let _ = print("- 滚动位置: \(scrollPosition)")
                        let _ = print("- 长按位置: \(longPressLocation)")
                        
                        // 计算可见区域信息
                        let gridWidth = cellWidth + cellSpacing
                        let visibleStartColumn = Int(abs(scrollPosition) / gridWidth)
                        let visibleEndColumn = visibleStartColumn + Int(UIScreen.main.bounds.width / gridWidth)
                        let _ = print("- 当前可见区域: 起始列\(visibleStartColumn), 结束列\(visibleEndColumn)")
                        
                        // 放大镜视图
                        MagnifierView(
                            habit: habit,
                            colorScheme: colorScheme,
                            date: longPressDate,
                            cellSize: cellWidth,
                            cellSpacing: cellSpacing,
                            magnificationFactor: magnificationFactor,
                            allDates: daysInYear,
                            scrollPosition: scrollPosition,
                            cellIndex: longPressedCellIndex
                        )
                        .frame(width: magnifierRadius * 2, height: magnifierRadius * 2)
                        .position(magnifierPosition(for: longPressLocation))
                        .allowsHitTesting(false) // 防止放大镜阻挡手势
                    }
                    
                    // 成功反馈提示 - 仅在记录成功后短暂显示
                    if showSuccessFeedback, let date = successFeedbackDate {
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.green)
                            
                            Text("\(formatDate(date))\n记录成功!")
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(colorScheme == .dark ? .black : .white))
                                .opacity(0.9)
                                .shadow(radius: 5)
                        )
                        .transition(.scale.combined(with: .opacity))
                        .animation(.easeInOut, value: showSuccessFeedback)
                        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 4)
                    }
                }
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
    
    // 处理放大镜位置，避免超出屏幕
    private func magnifierPosition(for location: CGPoint) -> CGPoint {
        var position = location
        
        // 获取屏幕尺寸
        let screenWidth = UIScreen.main.bounds.width
        let screenCenter = screenWidth / 2
        
        // 放大镜直径
        let _ = magnifierRadius * 2 // 直接使用magnifierRadius * 2，不再存储为变量
        
        // 根据触摸位置决定放大镜显示在左侧还是右侧
        if location.x < screenCenter {
            // 触摸在左半屏，放大镜显示在右侧
            position.x = min(screenWidth - magnifierRadius, location.x + magnifierRadius + 20)
        } else {
            // 触摸在右半屏，放大镜显示在左侧
            position.x = max(magnifierRadius, location.x - magnifierRadius - 20)
        }
        
        // 纵向位置 - 放大镜与手指在同一水平线上
        position.y = max(magnifierRadius, min(location.y, UIScreen.main.bounds.height - magnifierRadius))
        
        return position
    }
    
    // 根据位置更新长按的日期
    private func updateLongPressedDate(at location: CGPoint) -> (Bool, Int) {
        // 计算网格位置参数
        let gridWidth = cellWidth + cellSpacing
        
        // 减去月份标签和测试区域的高度，以获得正确的Y坐标
        let adjustedY = max(0, location.y - 48) // 24是月份标签高度，20是测试区域高度，4是padding
        
        // ⚠️ 关键部分：计算在整个网格中的位置（考虑滚动）
        // scrollPosition可能是正值或负值，根据实际记录的值来处理
        let absoluteX = location.x - scrollPosition
        
        // 计算列和行索引
        let column = Int(absoluteX / gridWidth)
        let row = Int(adjustedY / gridWidth)
        
        print("=============================================")
        print("触摸位置计算详情 (updateLongPressedDate):")
        print("- 原始位置: \(location)")
        print("- 滚动位置: \(scrollPosition)")
        print("- 调整后X轴: \(absoluteX)")
        print("- 调整后Y轴: \(adjustedY)")
        print("- 单元格宽度 (含间距): \(gridWidth)")
        print("- 计算出的列: \(column), 行: \(row)")
        
        // 增加滚动偏移量的详细分析
        let gridColumnWidth = cellWidth + cellSpacing
        let visibleStartColumn = Int(abs(scrollPosition) / gridColumnWidth)
        let visibleEndColumn = visibleStartColumn + Int(UIScreen.main.bounds.width / gridColumnWidth) + 1
        print("- 可视区域起始列: \(visibleStartColumn)")
        print("- 可视区域结束列: \(visibleEndColumn)")
        print("- 点击的绝对列: \(column)")
        print("- 点击位置相对于可视区域起始列的偏移: \(column - visibleStartColumn)")
        
        // 检查是否在可视区域内的有效范围
        if row < 0 || row > 6 || column < 0 {
            print("位置超出范围: 行\(row), 列\(column)")
            return (false, -1)
        }
        
        // 计算索引 - 每列包含7行 (周一到周日)
        let index = row + column * 7
        
        // 检查索引是否有效
        if index >= 0 && index < daysInYear.count {
            // 找到有效日期
            longPressedCellIndex = index
            longPressDate = daysInYear[index]
            
            // 打印详细日期信息用于调试
            if let date = longPressDate {
                let calendar = Calendar.current
                let day = calendar.component(.day, from: date)
                let month = calendar.component(.month, from: date)
                let year = calendar.component(.year, from: date)
                print("识别到日期: \(year)年\(month)月\(day)日, 索引: \(index), 位置: 行\(row), 列\(column)")
                print("总日期数组长度: \(daysInYear.count), 计算公式: \(row) + \(column) * 7 = \(index)")
            }
            
            return (true, index)
        } else {
            print("索引无效: \(index), 超出数组大小: \(daysInYear.count)")
            return (false, -1)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
    
    private func isFutureDate(_ date: Date) -> Bool {
        date > Date()
    }
}

struct DayCellGitHub: View {
    let date: Date
    let habit: Habit
    let colorScheme: ColorScheme
    @EnvironmentObject var habitStore: HabitStore
    // 新增是否显示日期的标志
    let showDate: Bool
    // 是否为当前长按选中的格子
    let isCurrentSelected: Bool
    
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
        Button(action: { 
            // 只有当没有长按时才记录习惯
            print("格子点击: 日期=\(tooltipText), 长按状态=\(showDate)")
            if !showDate {
                logHabit() 
                print("记录习惯成功")
            } else {
                print("长按状态中，忽略点击")
            }
        }) {
            ZStack {
                // 背景颜色
                RoundedRectangle(cornerRadius: 2)
                    .fill(theme.color(for: logCount, isDarkMode: colorScheme == .dark))
                    .opacity(isCurrentYear ? 1.0 : 0.6)
                
                // 边框 - 今天或当前选中
                if isToday || isCurrentSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(isCurrentSelected ? Color.blue : Color.primary, lineWidth: isCurrentSelected ? 2 : 1)
                }
                
                // 日期数字显示
                // 每月1号始终显示
                if isFirstDayOfMonth {
                    Text("1")
                        .font(.system(size: 8))
                        .foregroundColor(textColor(for: logCount))
                        .opacity(0.8)
                }
                // 长按时显示其他日期
                else if showDate {
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.system(size: 6))
                        .foregroundColor(textColor(for: logCount))
                        .opacity(0.8)
                }
            }
            .frame(width: 12, height: 12)
            .help(tooltipText)
            // 如果是当前选中格子，应用缩放效果
            .scaleEffect(isCurrentSelected ? 1.2 : 1.0)
            .animation(.spring(), value: isCurrentSelected)
        }
        .disabled(isFutureDate)
    }
    
    private func textColor(for count: Int) -> Color {
        // 根据格子颜色深浅选择文本颜色
        if count > 2 {
            return .white
        } else {
            return colorScheme == .dark ? .white : .black
        }
    }
    
    private var tooltipText: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        
        return "\(dateFormatter.string(from: date)): \(logCount)次"
    }
    
    private func logHabit() {
        habitStore.logHabit(habitId: habit.id, date: date)
    }
}

struct HabitSettingsView: View {
    let habit: Habit
    @Binding var isPresented: Bool
    @State private var editedName: String
    @State private var selectedTheme: Habit.ColorThemeName
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.colorScheme) var colorScheme
    
    init(habit: Habit, isPresented: Binding<Bool>) {
        self.habit = habit
        self._isPresented = isPresented
        self._editedName = State(initialValue: habit.name)
        self._selectedTheme = State(initialValue: habit.colorTheme)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("习惯名称")) {
                    TextField("习惯名称", text: $editedName)
                }
                
                Section(header: Text("颜色主题")) {
                    ForEach(Habit.ColorThemeName.allCases, id: \.self) { themeName in
                        let theme = ColorTheme.getTheme(for: themeName)
                        
                        Button(action: { selectedTheme = themeName }) {
                            HStack {
                                Text(theme.name)
                                
                                Spacer()
                                
                                // 主题预览
                                HStack(spacing: 2) {
                                    ForEach(0..<5) { level in
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(theme.color(for: level, isDarkMode: colorScheme == .dark))
                                            .frame(width: 20, height: 20)
                                    }
                                }
                                
                                if selectedTheme == themeName {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                        .padding(.leading, 5)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                Section {
                    Button(action: deleteHabit) {
                        Text("删除习惯")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("习惯设置")
            .navigationBarItems(
                leading: Button("取消") { isPresented = false },
                trailing: Button("保存") { saveChanges() }
                    .disabled(editedName.isEmpty)
            )
        }
    }
    
    private func saveChanges() {
        var updatedHabit = habit
        updatedHabit.name = editedName
        updatedHabit.colorTheme = selectedTheme
        habitStore.updateHabit(updatedHabit)
        isPresented = false
    }
    
    private func deleteHabit() {
        habitStore.removeHabit(habit)
        isPresented = false
    }
}

// 放大镜视图
struct MagnifierView: View {
    let habit: Habit
    let colorScheme: ColorScheme
    let date: Date?
    let cellSize: CGFloat
    let cellSpacing: CGFloat
    let magnificationFactor: CGFloat
    @EnvironmentObject var habitStore: HabitStore
    
    // 传入daysInYear数组，以便知道热力图的实际边界
    let allDates: [Date]
    
    // 滚动位置
    let scrollPosition: CGFloat
    
    // 添加长按格子的索引参数，直接使用外部计算好的索引
    let cellIndex: Int?
    
    var body: some View {
        ZStack {
            // 放大镜背景
            Circle()
                .fill(Color(colorScheme == .dark ? .black : .white).opacity(0.9))
                .shadow(color: Color.black.opacity(0.3), radius: 5)
            
            // 只有当有选中日期时显示内容
            if let selectedDate = date, let selectedIndex = cellIndex, selectedIndex >= 0 && selectedIndex < allDates.count {
                VStack(spacing: 5) {
                    // 抬起提示
                    Text("松开添加记录")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(colorScheme == .dark ? .black : .white).opacity(0.7))
                        .cornerRadius(4)
                        .padding(.bottom, 5)
                    
                    // 计算选中日期在网格中的行和列
                    let selectedRow = selectedIndex % 7 // 0-6，对应周一到周日
                    let selectedColumn = selectedIndex / 7 // 列数
                    
                    // 打印放大镜网格的计算信息
                    let _ = print("放大镜网格计算 - 选中行: \(selectedRow), 选中列: \(selectedColumn), 索引: \(selectedIndex)")
                    
                    // 增加日期验证
                    let dateFromIndex = allDates[selectedIndex]
                    let calendar = Calendar.current
                    let _ = print("索引\(selectedIndex)对应的实际日期: \(formatDate(dateFromIndex))")
                    let _ = print("传入的日期: \(formatDate(selectedDate))")
                    let _ = print("两者是否相同: \(calendar.isDate(dateFromIndex, inSameDayAs: selectedDate))")
                    
                    // 日期网格 - 创建3x3的日期网格
                    createMagnifierGrid(selectedIndex: selectedIndex, selectedRow: selectedRow, selectedColumn: selectedColumn)
                    
                    // 显示完整日期
                    Text(formatDate(selectedDate))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(colorScheme == .dark ? .black : .white).opacity(0.7))
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.top, 5)
                    
                    // 添加星期信息
                    Text(formatWeekday(selectedDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                .padding(5)
            } else {
                // 打印错误信息，帮助调试
                let _ = print("放大镜错误 - 无法显示内容: date=\(date?.description ?? "nil"), cellIndex=\(cellIndex?.description ?? "nil"), allDates.count=\(allDates.count)")
            }
        }
        .onAppear {
            print("=============================================")
            print("放大镜视图出现 (MagnifierView.onAppear):")
            print("- 日期: \(date?.description ?? "nil")")
            print("- 索引: \(cellIndex?.description ?? "nil")")
            print("- 滚动位置: \(scrollPosition)")
            print("- 日期数组大小: \(allDates.count)")
            
            if let selectedDate = date, let selectedIndex = cellIndex, selectedIndex >= 0 && selectedIndex < allDates.count {
                // 打印调试信息
                let calendar = Calendar.current
                let row = selectedIndex % 7
                let column = selectedIndex / 7
                let day = calendar.component(.day, from: selectedDate)
                let month = calendar.component(.month, from: selectedDate)
                let year = calendar.component(.year, from: selectedDate)
                print("放大镜显示: \(year)年\(month)月\(day)日, 位置: 行\(row)列\(column), 索引: \(selectedIndex), 滚动: \(scrollPosition)")
                
                // 计算可见范围的开始位置
                let cellWidth = cellSize + cellSpacing
                let visibleStartColumn = Int(abs(scrollPosition) / cellWidth)
                print("可视区域起始列: \(visibleStartColumn)")
                
                // 验证索引是否正确对应日期
                if let dateFromIndex = allDates.indices.contains(selectedIndex) ? allDates[selectedIndex] : nil {
                    print("通过索引\(selectedIndex)获取的日期: \(formatDate(dateFromIndex))")
                    print("是否与传入日期匹配: \(isSameDay(dateFromIndex, selectedDate))")
                }
            }
        }
    }
    
    // 创建放大镜内的网格
    private func createMagnifierGrid(selectedIndex: Int, selectedRow: Int, selectedColumn: Int) -> some View {
        let _ = print("=============================================")
        let _ = print("创建放大镜网格 (createMagnifierGrid):")
        let _ = print("- 选中行: \(selectedRow), 选中列: \(selectedColumn), 索引: \(selectedIndex)")
        
        return VStack(spacing: cellSpacing * magnificationFactor) {
            ForEach(-1...1, id: \.self) { rowOffset in
                HStack(spacing: cellSpacing * magnificationFactor) {
                    ForEach(-1...1, id: \.self) { colOffset in
                        // 计算当前位置的行和列
                        let currentRow = selectedRow + rowOffset
                        let currentColumn = selectedColumn + colOffset
                        
                        // 计算实际索引
                        if currentRow >= 0 && currentRow <= 6 && currentColumn >= 0 {
                            let currentIndex = currentRow + currentColumn * 7
                            
                            // 打印当前格子的计算信息
                            let cellDebugInfo = "格子[行偏移:\(rowOffset),列偏移:\(colOffset)] -> 行:\(currentRow),列:\(currentColumn),索引:\(currentIndex)"
                            let _ = print(cellDebugInfo)
                            
                            // 检查索引是否有效
                            if currentIndex >= 0 && currentIndex < allDates.count {
                                // 打印有效格子的日期信息
                                let date = allDates[currentIndex]
                                let calendar = Calendar.current
                                let day = calendar.component(.day, from: date)
                                let month = calendar.component(.month, from: date)
                                let year = calendar.component(.year, from: date)
                                let _ = print("   - 有效格子内容: \(year)年\(month)月\(day)日")
                                
                                createCell(
                                    date: allDates[currentIndex],
                                    isSelected: currentIndex == selectedIndex
                                )
                            } else {
                                let _ = print("   - 索引超出范围: \(currentIndex) >= \(allDates.count)")
                                EmptyCell()
                            }
                        } else {
                            let _ = print("   - 行列超出范围: 行\(currentRow),列\(currentColumn)")
                            EmptyCell()
                        }
                    }
                }
            }
        }
    }
    
    // 创建单个日期单元格
    private func createCell(date: Date, isSelected: Bool) -> some View {
        let count = habitStore.getLogCountForDate(habitId: habit.id, date: date)
        let day = Calendar.current.component(.day, from: date)
        
        return ZStack {
            // 背景
            RoundedRectangle(cornerRadius: 3)
                .fill(cellColor(for: count))
                .frame(width: cellSize * magnificationFactor, height: cellSize * magnificationFactor)
            
            // 日期数字
            Text("\(day)")
                .font(.system(size: 9 * magnificationFactor))
                .foregroundColor(count > 2 ? .white : (colorScheme == .dark ? .white : .black))
            
            // 选中标记
            if isSelected {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.blue, lineWidth: 1.5)
                    .frame(width: cellSize * magnificationFactor, height: cellSize * magnificationFactor)
            }
        }
    }
    
    // 空白单元格
    private func EmptyCell() -> some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: cellSize * magnificationFactor, height: cellSize * magnificationFactor)
    }
    
    // 判断两个日期是否为同一天
    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        return Calendar.current.isDate(date1, inSameDayAs: date2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
    
    private func formatWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEEE" // 完整星期名称
        return formatter.string(from: date)
    }
    
    private func cellColor(for count: Int) -> Color {
        let theme = ColorTheme.getTheme(for: habit.colorTheme)
        return theme.color(for: min(count, 4), isDarkMode: colorScheme == .dark)
    }
}

#Preview {
    NavigationView {
        HabitDetailView(habit: Habit(name: "读书", colorTheme: .github))
            .environmentObject(HabitStore())
    }
} 