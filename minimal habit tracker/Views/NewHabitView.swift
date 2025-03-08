import SwiftUI

struct NewHabitView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var habitStore: HabitStore
    @State private var habitName = ""
    @State private var selectedTheme: Habit.ColorThemeName = .github
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(verbatim: "习惯名称")) {
                    TextField("例如: 每日锻炼".localized, text: $habitName)
                }
                
                Section(header: Text(verbatim: "颜色主题")) {
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
            }
            .navigationTitle("新建习惯".localized)
            .navigationBarItems(
                leading: Button("取消".localized) { isPresented = false },
                trailing: Button("保存".localized) {
                    saveHabit()
                }
                .disabled(habitName.isEmpty)
            )
        }
    }
    
    private func saveHabit() {
        let newHabit = Habit(name: habitName, colorTheme: selectedTheme)
        habitStore.addHabit(newHabit)
        isPresented = false
    }
}

#Preview {
    NewHabitView(isPresented: .constant(true))
        .environmentObject(HabitStore())
} 