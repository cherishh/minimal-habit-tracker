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
    
    // 背景色列表
    let backgroundColors: [String] = [
        "#FF5733", "#33FF57", "#5733FF", "#FF33A1", "#3399FF", 
        "#FFD700", "#00BFFF", "#32CD32", "#FF6347", "#8A2BE2", 
        "#FF1493", "#7FFF00", "#DC143C", "#FFD700", "#40E0D0", 
        "#FF8C00", "#4682B4", "#8B0000", "#B8860B", "#2E8B57", 
        "#A52A2A", "#C71585", "#228B22", "#D2691E", "#F0E68C", 
        "#FF4500", "#708090", "#B0C4DE", "#9370DB", "#C0C0C0", 
        "#FF6347", "#32CD32", "#90EE90", "#FF7F50", "#98FB98", 
        "#B22222", "#D3D3D3", "#FFD700", "#FF00FF", "#663399",
        "#FDF5E7"
    ]
    
    // 新建习惯模式的初始化
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        // 常用emoji列表
        let commonEmojis = ["😀", "🎯", "💪", "🏃", "📚", "💤", "🍎", "💧", "🧘", "✍️", "🏋️", "🚴", "🧠", "🌱", "🚫", "💊"]
        // 随机选择一个emoji作为初始值
        self._selectedEmoji = State(initialValue: commonEmojis.randomElement() ?? "📝")
        // 随机选择一个背景色
        self._selectedBackgroundColor = State(initialValue: backgroundColors.randomElement() ?? "#FDF5E7")
        self._habitName = State(initialValue: "")
        self._selectedTheme = State(initialValue: .github)
        self._selectedType = State(initialValue: .checkbox)
        self._currentStep = State(initialValue: 1)
        self._isEditMode = State(initialValue: false)
        self._originalHabit = State(initialValue: nil)
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
                EmojiPickerView(selectedEmoji: $selectedEmoji, backgroundColor: selectedBackgroundColor)
            }
        }
    }
    
    private var navigationTitle: String {
        if isEditMode {
            return "编辑习惯"
        } else {
            return currentStep == 1 ? "选择习惯类型" : "新建习惯"
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
            Text("选择习惯类型")
                .font(.headline)
                .padding(.top)
            
            Text("选择后不可更改")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            VStack(spacing: 20) {
                typeButton(type: .checkbox, title: "打卡型", description: "完成一次打卡就记录为完成")
                
                typeButton(type: .count, title: "计数型", description: "可重复打卡，打卡次数越多颜色越深")
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
            Section(header: Text("习惯名称")) {
                TextField("例如: 每日锻炼", text: $habitName)
            }
            
            Section(header: Text("选择图标")) {
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
            
            Section(header: Text("背景颜色")) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(backgroundColors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(color == selectedBackgroundColor ? Color.primary : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    selectedBackgroundColor = color
                                }
                        }
                    }
                    .padding(.vertical, 5)
                }
                .padding(.horizontal, -15)
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
                if isEditMode {
                    HStack {
                        Text("习惯类型")
                        Spacer()
                        Text(selectedType == .checkbox ? "打卡型" : "计数型")
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("选择的类型: \(selectedType == .checkbox ? "打卡型" : "计数型")")
                            .font(.subheadline)
                    }
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    if selectedType == .checkbox {
                        Text("点击一次记录完成，再次点击取消")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("可多次点击增加计数，颜色会逐渐加深")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
            
            habitStore.updateHabit(updatedHabit)
        } else {
            // 新建模式 - 创建新习惯
            let newHabit = Habit(
                name: habitName,
                emoji: finalEmoji,
                colorTheme: selectedTheme,
                habitType: selectedType,
                backgroundColor: selectedBackgroundColor
            )
            habitStore.addHabit(newHabit)
        }
        
        isPresented = false
    }
}

// 为了保持向后兼容性，我们保留原来的NewHabitView的名称，但它现在只是一个HabitFormView的包装器
struct NewHabitView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        HabitFormView(isPresented: $isPresented)
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