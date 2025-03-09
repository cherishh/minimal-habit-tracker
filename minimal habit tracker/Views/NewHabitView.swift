import SwiftUI

struct NewHabitView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var habitStore: HabitStore
    @State private var habitName = ""
    @State private var selectedTheme: Habit.ColorThemeName = .github
    @State private var selectedEmoji = "📝"
    @State private var showEmojiKeyboard = false
    @State private var selectedType: Habit.HabitType = .checkbox
    @State private var currentStep = 1
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack {
                if currentStep == 1 {
                    typeSelectionView
                } else {
                    habitDetailsView
                }
            }
            .navigationTitle(currentStep == 1 ? "选择习惯类型" : "新建习惯")
            .navigationBarItems(
                leading: Button(currentStep == 1 ? "取消" : "返回") {
                    if currentStep == 1 {
                        isPresented = false
                    } else {
                        currentStep = 1
                    }
                },
                trailing: currentStep == 1 ? nil : Button("保存") {
                    saveHabit()
                }
                .disabled(habitName.isEmpty || selectedEmoji.isEmpty)
            )
        }
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
                HStack {
                    Text("Emoji")
                    
                    Spacer()
                    
                    TextField("点击选择emoji", text: $selectedEmoji)
                        .multilineTextAlignment(.trailing)
                        .font(.title)
                        .frame(width: 100)
                        .onTapGesture {
                            // 这里不需要执行任何代码，iOS会自动显示键盘
                            // 用户可以点击键盘上的emoji按钮切换到emoji键盘
                            showEmojiKeyboard = true
                        }
                }
                
                if !showEmojiKeyboard {
                    Text("提示：点击上方图标区域后，可切换到emoji键盘选择表情")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
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
                VStack(alignment: .leading, spacing: 5) {
                    Text("选择的类型: \(selectedType == .checkbox ? "打卡型" : "计数型")")
                        .font(.subheadline)
                    
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
        
        let newHabit = Habit(
            name: habitName,
            emoji: finalEmoji,
            colorTheme: selectedTheme,
            habitType: selectedType
        )
        habitStore.addHabit(newHabit)
        isPresented = false
    }
}

#Preview {
    NewHabitView(isPresented: .constant(true))
        .environmentObject(HabitStore())
} 