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
                        Text("一").font(.caption2).foregroundColor(.secondary).frame(height: cellWidth)
                        Text("").frame(height: cellWidth)  // 空行
                        Text("三").font(.caption2).foregroundColor(.secondary).frame(height: cellWidth)
                        Text("").frame(height: cellWidth)  // 空行
                        Text("五").font(.caption2).foregroundColor(.secondary).frame(height: cellWidth)
                        Text("").frame(height: cellWidth)  // 空行
                        Text("日").font(.caption2).foregroundColor(.secondary).frame(height: cellWidth)
                    }
                }
                .frame(width: 15)  // 最小宽度
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
                                Text(monthLabels[month - 1])
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .position(x: CGFloat(exactPosition) * (cellWidth + cellSpacing) + cellWidth/2, y: 10)
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
        Button(action: { logHabit() }) {
            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(theme.color(for: logCount, isDarkMode: colorScheme == .dark))
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
            .help(tooltipText)
        }
        .disabled(isFutureDate)
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

#Preview {
    NavigationView {
        HabitDetailView(habit: Habit(name: "读书", colorTheme: .github))
            .environmentObject(HabitStore())
    }
} 