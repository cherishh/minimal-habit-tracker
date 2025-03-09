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
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationView {
            VStack() {
                if habitStore.habits.isEmpty {
                    emptyStateView
                } else {
                    habitListView
                }
            }
            .navigationTitle("习惯追踪")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gear")
                        }
                        
                        Button(action: { isAddingHabit = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $isAddingHabit) {
                NewHabitView(isPresented: $isAddingHabit)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(isPresented: $showingSettings)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("开始追踪您的习惯")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("添加您想要培养的习惯，每天记录进度，形成可视化热力图。")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: { isAddingHabit = true }) {
                Text("添加第一个习惯")
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
                NavigationLink(destination: HabitDetailView(habit: habit)) {
                    HabitRowView(habit: habit)
                }
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
        HStack(spacing: 12) {
            // Emoji图标
            Text(habit.emoji)
                .font(.title)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                
                // 显示最近的10天小型热力图
                HStack(spacing: 3) {
                    ForEach(0..<10, id: \.self) { dayOffset in
                        let date = Calendar.current.date(byAdding: .day, value: -(9-dayOffset), to: Date())!
                        let count = habitStore.getLogCountForDate(habitId: habit.id, date: date)
                        let theme = ColorTheme.getTheme(for: habit.colorTheme)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(theme.color(for: min(count, 4), isDarkMode: colorScheme == .dark))
                            .frame(width: 10, height: 10)
                    }
                }
            }
            
            Spacer()
            
            // 添加打卡按钮
            Button(action: {
                habitStore.logHabit(habitId: habit.id, date: Date())
            }) {
                Image(systemName: "checkmark.circle")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.accentColor.opacity(0.1))
                    )
            }
        }
        .padding(.vertical, 8)
    }
}

// 添加设置页面
struct SettingsView: View {
    @Binding var isPresented: Bool
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationView {
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
            .navigationBarItems(trailing: Button("完成") {
                isPresented = false
            })
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HabitStore())
}
