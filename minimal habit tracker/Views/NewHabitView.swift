import SwiftUI

struct HabitFormView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var habitStore: HabitStore
    @State private var habitName: String
    @State private var selectedTheme: Habit.ColorThemeName
    @State private var selectedEmoji: String
    @State private var selectedBackgroundColor: String
    @State private var showEmojiPicker = false
    @State private var selectedType: Habit.HabitType
    @State private var currentStep: Int
    @State private var isEditMode: Bool
    @State private var originalHabit: Habit?
    @Environment(\.colorScheme) var colorScheme
    @State private var showingCopiedMessage = false
    @State private var showingDeleteConfirmation = false
    @State private var maxCheckInCount: Int
    @State private var showingMaxCountChangeAlert = false
    @State private var previousMaxCount: Int = 5
    @AppStorage("themeMode") private var themeMode: Int = 0 // 0: 自适应系统, 1: 明亮模式, 2: 暗黑模式

    
    // 新建习惯模式的初始化
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        // 常用emoji列表
        let commonEmojis = ["😀", "🎯", "💪", "🏃", "📚", "💤", "🍎", "💧", "🧘", "✍️", "🏋️", "🚴", "🧠", "🌱", "🚫", "💊"]
        // 随机选择一个emoji作为初始值
        self._selectedEmoji = State(initialValue: commonEmojis.randomElement() ?? "📝")
        
        // 从UserDefaults获取当前的主题模式
        let isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        // 根据主题模式选择默认背景色
        let defaultBackgroundColor = isDarkMode ? "#C0C0C0" : "#FDF5E7"
        self._selectedBackgroundColor = State(initialValue: defaultBackgroundColor)
        
        self._habitName = State(initialValue: "")
        self._selectedTheme = State(initialValue: .github)
        self._selectedType = State(initialValue: .checkbox)
        self._currentStep = State(initialValue: 1)
        self._isEditMode = State(initialValue: false)
        self._originalHabit = State(initialValue: nil)
        self._maxCheckInCount = State(initialValue: 5) // 默认为5次
    }
    
    // 编辑习惯模式的初始化
    init(isPresented: Binding<Bool>, habit: Habit) {
        self._isPresented = isPresented
        self._habitName = State(initialValue: habit.name)
        self._selectedEmoji = State(initialValue: habit.emoji)
        self._selectedTheme = State(initialValue: habit.colorTheme)
        self._selectedBackgroundColor = State(initialValue: habit.backgroundColor ?? "#FDF5E7")
        self._selectedType = State(initialValue: habit.habitType)
        self._currentStep = State(initialValue: 2) // 直接跳到第二步，不需要选择类型
        self._isEditMode = State(initialValue: true)
        self._originalHabit = State(initialValue: habit)
        self._maxCheckInCount = State(initialValue: habit.maxCheckInCount)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if currentStep == 1 && !isEditMode {
                    typeSelectionView
                } else {
                    habitDetailsView
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarItems(
                leading: Button(leadingButtonTitle) {
                    if currentStep == 1 || isEditMode {
                        isPresented = false
                    } else {
                        currentStep = 1
                    }
                },
                trailing: currentStep == 1 && !isEditMode ? nil : Button(trailingButtonTitle) {
                    saveHabit()
                }
                .disabled(habitName.isEmpty || selectedEmoji.isEmpty)
            )
            .sheet(isPresented: $showEmojiPicker) {
                EmojiPickerView(selectedEmoji: $selectedEmoji, selectedBackgroundColor: $selectedBackgroundColor)
            }
            // 删除习惯的确认对话框
            .alert("确认删除", isPresented: $showingDeleteConfirmation) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    if let habit = originalHabit {
                        // 从store中删除习惯
                        habitStore.removeHabit(habit)
                        // 发送通知，让详情页面返回到列表页
                        NotificationCenter.default.post(name: NSNotification.Name("HabitDeleted"), object: habit.id)
                        // 关闭编辑视图
                        isPresented = false
                    }
                }
            } message: {
                Text("确定要删除这个习惯吗？所有相关的打卡记录也将被删除。此操作无法撤销。")
            }
            // 修改打卡次数的确认对话框
            .alert("确认修改打卡次数", isPresented: $showingMaxCountChangeAlert) {
                Button("取消", role: .cancel) {
                    // 用户取消修改，恢复原来的值
                    maxCheckInCount = previousMaxCount
                }
                Button("确认") {
                    // 用户确认修改，保持当前设置的值
                }
            } message: {
                Text("修改打卡次数将影响所有已存在的记录。" + 
                     (previousMaxCount > maxCheckInCount ? "超过新上限的记录将被调整为新的上限值。" : "") +
                     "\n是否继续？")
            }
        }
        .preferredColorScheme(getPreferredColorScheme())
    }
    
    private var navigationTitle: String {
        if isEditMode {
            return "编辑习惯"
        } else {
            return currentStep == 1 ? "确定习惯类型" : "新建习惯"
        }
    }
    
    private var leadingButtonTitle: String {
        if isEditMode {
            return "取消"
        } else {
            return currentStep == 1 ? "取消" : "返回"
        }
    }
    
    private var trailingButtonTitle: String {
        return "保存"
    }
    
    private var typeSelectionView: some View {
        VStack(spacing: 20) {
            HabitTypeDemo()
                .padding(.top)
            
            Text("选择后不可更改")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            VStack(spacing: 20) {
                typeButton(type: .checkbox, title: "打卡", description: "完成一次打卡就记录为完成。如：每天吃早餐")
                typeButton(type: .count, title: "计数", description: "设置每日目标次数，可多次打卡。如：每天X杯喝水")
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func typeButton(type: Habit.HabitType, title: String, description: String) -> some View {
        Button(action: {
            selectedType = type
            currentStep = 2
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.headline)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var habitDetailsView: some View {
        Form {
            Section(header: Text("习惯名称")
                        .foregroundColor(colorScheme == .dark ? .primary.opacity(0.8) : .primary)) {
                TextField("例如: 每日锻炼", text: $habitName)
            }
            
            Section(header: Text("选择图标")
                        .foregroundColor(colorScheme == .dark ? .primary.opacity(0.8) : .primary)) {
                Button(action: {
                    showEmojiPicker = true
                }) {
                    HStack {
                        Text("Emoji")
                        
                        Spacer()
                        
                        Text(selectedEmoji)
                            .font(.title)
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: selectedBackgroundColor))
                            )
                    }
                }
            }
            
            Section(header: VStack(alignment: .leading, spacing: 3) {
                Text("颜色主题")
                    .foregroundColor(colorScheme == .dark ? .primary.opacity(0.8) : .primary)
                Text("👑 标记的为高级主题")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }) {
                ForEach(Habit.ColorThemeName.allCases, id: \.self) { themeName in
                    let theme = ColorTheme.getTheme(for: themeName)
                    let isPremiumTheme = isPremium(themeName) // 检查是否为高级主题
                    
                    Button(action: { selectedTheme = themeName }) {
                        HStack {
                            if isPremiumTheme {
                                Text("\(theme.name) 👑")
                            } else {
                                Text(theme.name)
                            }
                            
                            Spacer()
                            
                            // 主题预览
                            HStack(spacing: 2) {
                                ForEach(0..<HabitStore.maxCheckInCount+1) { level in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(theme.color(for: level, isDarkMode: colorScheme == .dark))
                                        .frame(width: 16, height: 16)
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
                if isEditMode {
                    HStack {
                        Text("习惯类型")
                        Spacer()
                        Text(selectedType == .checkbox ? "打卡" : "计数")
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("选择的类型: \(selectedType == .checkbox ? "打卡" : "计数")")
                            .font(.subheadline)
                    }
                }
                
                // 计数型习惯的最大打卡次数选择
                if selectedType == .count {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("打卡次数上限")
                            .font(.subheadline)
                        
                        Picker("打卡次数上限", selection: $maxCheckInCount) {
                            ForEach(1...10, id: \.self) { count in
                                Text("\(count)").tag(count)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 120)
                        .onChange(of: maxCheckInCount) { oldValue, newValue in
                            if isEditMode && originalHabit != nil {
                                // 保存旧值，用于后续比较
                                previousMaxCount = oldValue
                                // 显示确认对话框
                                showingMaxCountChangeAlert = true
                            }
                        }
                        
                        Text("设置每日打卡的最大次数")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }

            // 只在编辑模式下显示 UUID 信息，用于配置 Widget
            if isEditMode, let habit = originalHabit {
                Section(header: Text("Widget 配置信息")
                            .foregroundColor(colorScheme == .dark ? .primary.opacity(0.8) : .primary)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("习惯 ID")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Text(habit.id.uuidString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)  // 允许选择和复制文本
                            
                            Spacer()
                            
                            Button(action: {
                                UIPasteboard.general.string = habit.id.uuidString
                                showingCopiedMessage = true
                                
                                // 2秒后自动隐藏复制成功消息
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    showingCopiedMessage = false
                                }
                            }) {
                                Image("copy")
                                    .resizable()
                                    .renderingMode(.template)
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondary.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                        
                        if showingCopiedMessage {
                            Text("已复制到剪贴板")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                                .transition(.opacity)
                                .animation(.easeInOut, value: showingCopiedMessage)
                        }
                        
                        Text("配置 Widget 时需要输入此ID")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                }
                
            }

            // 删除按钮
            if isEditMode, let habit = originalHabit {
                Section {
                    Button(action: {
                        // 显示确认删除对话框
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Spacer()
                            Text("删除习惯")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    private func saveHabit() {
        let finalEmoji = selectedEmoji.isEmpty ? "📝" : String(selectedEmoji.prefix(1))
        
        if isEditMode && originalHabit != nil {
            // 编辑模式 - 更新现有习惯
            var updatedHabit = originalHabit!
            updatedHabit.name = habitName
            updatedHabit.emoji = finalEmoji
            updatedHabit.colorTheme = selectedTheme
            updatedHabit.backgroundColor = selectedBackgroundColor
            
            // 如果是计数型习惯，处理打卡次数的更新
            if updatedHabit.habitType == .count {
                // 记录旧的打卡次数
                let oldMaxCount = updatedHabit.maxCheckInCount
                updatedHabit.maxCheckInCount = maxCheckInCount
                
                // 如果打卡次数减少了，需要调整已有记录
                if oldMaxCount > maxCheckInCount {
                    habitStore.adjustLogCounts(habitId: updatedHabit.id, newMaxCount: maxCheckInCount)
                }
            }
            
            habitStore.updateHabit(updatedHabit)
        } else {
            // 新建模式 - 创建新习惯
            var newHabit = Habit(
                name: habitName,
                emoji: finalEmoji,
                colorTheme: selectedTheme,
                habitType: selectedType,
                backgroundColor: selectedBackgroundColor
            )
            
            // 如果是计数型习惯，设置用户选择的打卡次数上限
            if selectedType == .count {
                newHabit.maxCheckInCount = maxCheckInCount
            }
            
            habitStore.addHabit(newHabit)
        }
        
        isPresented = false
    }
    
    // 根据设置返回颜色模式
    private func getPreferredColorScheme() -> ColorScheme? {
        switch themeMode {
            case 1: return .light     // 明亮模式
            case 2: return .dark      // 暗黑模式
            default: return nil       // 自适应系统
        }
    }
    
    // 判断是否为高级主题
    private func isPremium(_ themeName: Habit.ColorThemeName) -> Bool {
        // 基础主题包括github, blueOcean, sunset
        return ![.github, .blueOcean, .sunset].contains(themeName)
    }
}

// 为了保持向后兼容性，我们保留原来的NewHabitView的名称，但它现在只是一个HabitFormView的包装器
struct NewHabitView: View {
    @Binding var isPresented: Bool
    @AppStorage("themeMode") private var themeMode: Int = 0 // 0: 自适应系统, 1: 明亮模式, 2: 暗黑模式
    
    var body: some View {
        HabitFormView(isPresented: $isPresented)
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
}

#Preview {
    NewHabitView(isPresented: .constant(true))
        .environmentObject(HabitStore())
}

#Preview("编辑模式") {
    HabitFormView(
        isPresented: .constant(true),
        habit: Habit(
            name: "读书",
            emoji: "📚",
            colorTheme: .github,
            habitType: .checkbox,
            backgroundColor: "#FF5733"
        )
    )
    .environmentObject(HabitStore())
}

// 习惯类型演示组件
struct HabitTypeDemo: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var checkboxProgress: CGFloat = 0
    @State private var countProgress: CGFloat = 0
    @State private var countTaps = 0
    @State private var maxCount = 3
    @State private var isAutoDemoRunning = false
    @State private var demoStage = 0
    @State private var demoLoopCount = 0 // 添加循环计数器
    
    // 获取Github主题（默认主题）
    private var github: ColorTheme {
        ColorTheme.getTheme(for: .github)
    }

    private var blueOcean: ColorTheme {
        ColorTheme.getTheme(for: .blueOcean)
    }
    
    var body: some View {
        HStack(spacing: 30) {
            // 打卡型演示
            VStack(spacing: 5) {
                Text("打卡")
                    .font(.headline)
                
                ZStack {
                    // 底色轨道
                    Circle()
                        .stroke(
                            github.color(for: 0, isDarkMode: colorScheme == .dark),
                            style: StrokeStyle(lineWidth: 10)
                        )
                        .frame(width: 64, height: 64)
                    
                    // 完成圆环
                    Circle()
                        .trim(from: 0, to: checkboxProgress)
                        .stroke(
                            checkboxProgress > 0 ? 
                                github.color(for: 5, isDarkMode: colorScheme == .dark) :
                                Color.clear,
                            style: StrokeStyle(
                                lineWidth: 10,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: checkboxProgress)
                    
                    // Emoji
                    Text("✅")
                        .font(.system(size: 30))
                }
                .frame(height: 80)
                .onTapGesture {
                    if !isAutoDemoRunning {
                        if checkboxProgress < 1.0 {
                            checkboxProgress = 1.0
                        } else {
                            checkboxProgress = 0
                        }
                    }
                }
                
                Text("打卡一次即完成")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 130, height: 140)
            
            // 计数型演示
            VStack(spacing: 5) {
                Text("计数")
                    .font(.headline)
                
                ZStack {
                    // 底色轨道
                    Circle()
                        .stroke(
                            blueOcean.color(for: 0, isDarkMode: colorScheme == .dark),
                            style: StrokeStyle(lineWidth: 10)
                        )
                        .frame(width: 64, height: 64)
                    
                    // 进度环
                    Circle()
                        .trim(from: 0, to: countProgress)
                        .stroke(
                            countProgress > 0 ? 
                                blueOcean.color(for: 5, isDarkMode: colorScheme == .dark) :
                                Color.clear,
                            style: StrokeStyle(
                                lineWidth: 10,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: countProgress)
                    
                    // Emoji和计数
                    VStack(spacing: 0) {
                        Text("🥤")
                            .font(.system(size: 30))
                        
                        Text("\(countTaps)/\(maxCount)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 80)
                .onTapGesture {
                    if !isAutoDemoRunning {
                        if countTaps < maxCount {
                            countTaps += 1
                            countProgress = CGFloat(countTaps) / CGFloat(maxCount)
                        } else {
                            // 重置
                            countTaps = 0
                            countProgress = 0
                        }
                    }
                }
                
                Text("多次打卡完成目标")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 130, height: 140)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemBackground).opacity(0.5))
        .cornerRadius(15)
        .onAppear {
            // 延迟1.5秒后开始自动演示
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                startAutoDemo()
            }
        }
    }
    
    // 开始自动演示
    private func startAutoDemo() {
        guard !isAutoDemoRunning else { return }
        
        // 检查是否已达到最大循环次数
        if demoLoopCount >= 2 {
            return // 如果已经演示了2次，则不再继续
        }
        
        isAutoDemoRunning = true
        demoStage = 1
        
        // 阶段1：点击打卡
        checkboxProgress = 1.0
        
        // 阶段2：等待1.5秒后开始计数演示
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            demoStage = 2
            performCountIncrement()
        }
    }
    
    // 执行计数增加的动画
    private func performCountIncrement() {
        guard isAutoDemoRunning && demoStage == 2 else { return }
        
        // 点击第一次
        countTaps = 1
        countProgress = CGFloat(countTaps) / CGFloat(maxCount)
        
        // 点击第二次
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            countTaps = 2
            countProgress = CGFloat(countTaps) / CGFloat(maxCount)
            
            // 点击第三次
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                countTaps = 3
                countProgress = CGFloat(countTaps) / CGFloat(maxCount)
                
                // 重置所有状态
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    demoStage = 3
                    resetDemo()
                }
            }
        }
    }
    
    // 重置演示
    private func resetDemo() {
        guard isAutoDemoRunning && demoStage == 3 else { return }
        
        // 重置所有状态
        checkboxProgress = 0
        countTaps = 0
        countProgress = 0
        
        // 增加循环计数
        demoLoopCount += 1
        
        // 演示完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            demoStage = 0
            isAutoDemoRunning = false
            
            // 如果未达到2次循环，2秒后重新开始自动演示
            if demoLoopCount < 2 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    startAutoDemo()
                }
            }
        }
    }
} 