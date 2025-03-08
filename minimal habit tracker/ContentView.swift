//
//  ContentView.swift
//  minimal habit tracker
//
//  Created by 王仲玺 on 2025/3/6.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var languageManager: LanguageManager
    @State private var isAddingHabit = false
    @Environment(\.colorScheme) var colorScheme
    // hack entry
    @State private var selectedHabitId: UUID? = nil
    @State private var showingLanguageSettings = false
    
    var body: some View {
        NavigationView {
            VStack() {
                if habitStore.habits.isEmpty {
                    emptyStateView
                } else {
                    habitListView
                }
            }
            .navigationTitle("习惯追踪".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isAddingHabit = true }) {
                        Label("添加习惯".localized, systemImage: "plus")
                    }
                }
                
                // 仅在开发模式下显示语言切换按钮
                #if DEBUG
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingLanguageSettings = true }) {
                        Image(systemName: "globe")
                    }
                }
                #endif
            }
            .sheet(isPresented: $isAddingHabit) {
                NewHabitView(isPresented: $isAddingHabit)
            }
            // 语言设置面板
            .sheet(isPresented: $showingLanguageSettings) {
                LanguageSettingsView(isPresented: $showingLanguageSettings)
            }
            // hack entry start
            .onAppear {
                // 如果有习惯，自动选择第一个
                if !habitStore.habits.isEmpty && selectedHabitId == nil {
                    selectedHabitId = habitStore.habits.first?.id
                }
            }
            
            // 默认显示选中的习惯详情
            if let habitId = selectedHabitId, let habit = habitStore.habits.first(where: { $0.id == habitId }) {
                HabitDetailView(habit: habit)
            } else {
                Text(verbatim: "请选择或创建一个习惯")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            // hack entry end
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text(verbatim: "开始追踪您的习惯")
                .font(.title2)
                .fontWeight(.medium)
            
            Text(verbatim: "添加您想要培养的习惯，每天记录进度，形成可视化热力图。")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: { isAddingHabit = true }) {
                Text(verbatim: "添加第一个习惯")
                    .fontWeight(.medium)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
    }
    
    private var habitListView: some View {
        List {
            ForEach(habitStore.habits) { habit in
                // hack entry start
                // NavigationLink(destination: HabitDetailView(habit: habit)) {
                NavigationLink(
                    destination: HabitDetailView(habit: habit),
                    tag: habit.id,
                    selection: $selectedHabitId
                ) {
                    HabitRowView(habit: habit)
                }
                // hack entry end
            }
            .onDelete(perform: deleteHabit)
        }
    }
    
    private func deleteHabit(at offsets: IndexSet) {
        for index in offsets {
            habitStore.removeHabit(habitStore.habits[index])
        }
    }
}

struct HabitRowView: View {
    let habit: Habit
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Text(habit.name)
                .font(.headline)
            
            Spacer()
            
            // 显示最近的5天小型热力图
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { dayOffset in
                    let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!
                    let count = habitStore.getLogCountForDate(habitId: habit.id, date: date)
                    let theme = ColorTheme.getTheme(for: habit.colorTheme)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.color(for: min(count, 4), isDarkMode: colorScheme == .dark))
                        .frame(width: 12, height: 12)
                }
            }
        }
    }
}

// 语言设置视图
struct LanguageSettingsView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("选择语言 / Language")) {
                    Button(action: { 
                        languageManager.currentLanguage = "zh-Hans" 
                        isPresented = false
                        // 提示用户重启应用
                        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
                    }) {
                        HStack {
                            Text("中文")
                            Spacer()
                            if languageManager.isChinese {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: { 
                        languageManager.currentLanguage = "en" 
                        isPresented = false
                        // 提示用户重启应用
                        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
                    }) {
                        HStack {
                            Text("English")
                            Spacer()
                            if !languageManager.isChinese {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                Section(footer: Text("语言更改可能需要重启应用才能完全生效").font(.caption).foregroundColor(.secondary)) {
                    Button("关闭", role: .cancel) {
                        isPresented = false
                    }
                }
            }
            .navigationTitle("语言设置 / Language")
            .preferredColorScheme(colorScheme) // 保持与系统一致的主题
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HabitStore())
}
