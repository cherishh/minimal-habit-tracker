import SwiftUI

struct HabitSettingsView: View {
    let habit: Habit
    @Binding var isPresented: Bool
    @State private var habitName: String
    @State private var emoji: String
    @State private var showEmojiKeyboard = false
    @State private var colorTheme: Habit.ColorThemeName
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.colorScheme) var colorScheme
    
    init(habit: Habit, isPresented: Binding<Bool>) {
        self.habit = habit
        self._isPresented = isPresented
        self._habitName = State(initialValue: habit.name)
        self._emoji = State(initialValue: habit.emoji)
        self._colorTheme = State(initialValue: habit.colorTheme)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("习惯名称")) {
                    TextField("习惯名称", text: $habitName)
                }
                
                Section(header: Text("选择图标")) {
                    HStack {
                        Text("Emoji")
                        
                        Spacer()
                        
                        TextField("点击选择emoji", text: $emoji)
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
                        
                        Button(action: { colorTheme = themeName }) {
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
                                
                                if colorTheme == themeName {
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
                    HStack {
                        Text("习惯类型")
                        Spacer()
                        Text(habit.habitType == .checkbox ? "打卡型" : "计数型")
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        if habit.habitType == .checkbox {
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
            .navigationTitle("修改习惯")
            .navigationBarItems(
                leading: Button("取消") { isPresented = false },
                trailing: Button("保存") {
                    saveHabit()
                }
                .disabled(habitName.isEmpty || emoji.isEmpty)
            )
        }
    }
    
    private func saveHabit() {
        let finalEmoji = emoji.isEmpty ? "📝" : String(emoji.prefix(1))
        
        var updatedHabit = habit
        updatedHabit.name = habitName
        updatedHabit.emoji = finalEmoji
        updatedHabit.colorTheme = colorTheme
        
        habitStore.updateHabit(updatedHabit)
        isPresented = false
    }
} 