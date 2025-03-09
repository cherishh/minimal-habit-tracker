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
    @State private var selectedHabit: Habit?
    @State private var navigateToDetail = false
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showingMaxHabitsAlert = false
    
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
                        
                        Button(action: {
                            if habitStore.canAddHabit() {
                                isAddingHabit = true
                            } else {
                                showingMaxHabitsAlert = true
                            }
                        }) {
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
            .alert(isPresented: $showingMaxHabitsAlert) {
                Alert(
                    title: Text("达到最大数量"),
                    message: Text("您最多只能创建4个习惯。如需添加更多，请升级为Pro版本。"),
                    dismissButton: .default(Text("我知道了"))
                )
            }
            .background(
                NavigationLink(
                    destination: selectedHabit.map { HabitDetailView(habit: $0) },
                    isActive: $navigateToDetail
                ) {
                    EmptyView()
                }
            )
            .onAppear {
                setupNotificationObserver()
            }
            .onDisappear {
                removeNotificationObserver()
            }
        }
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name("NavigateToDetail"), object: nil, queue: .main) { notification in
            if let habit = notification.object as? Habit {
                selectedHabit = habit
                navigateToDetail = true
            }
        }
    }
    
    private func removeNotificationObserver() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NavigateToDetail"), object: nil)
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
            
            Button(action: { 
                if habitStore.canAddHabit() {
                    isAddingHabit = true
                } else {
                    showingMaxHabitsAlert = true
                }
            }) {
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
                ZStack {
                    NavigationLink(destination: HabitDetailView(habit: habit)) {
                        EmptyView()
                    }
                    .opacity(0)
                    
                    HabitRowView(habit: habit)
                }
                .listRowInsets(EdgeInsets())
                .background(Color(UIColor.systemBackground))
            }
            .onDelete(perform: deleteHabit)
        }
        .listStyle(PlainListStyle())
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
    @State private var isAnimating = false
    @State private var todayCellAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Emoji图标
            Text(habit.emoji)
                .font(.title)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(habit.backgroundColor != nil ? Color(hex: habit.backgroundColor!) : Color.gray.opacity(0.1))
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
                        let isToday = Calendar.current.isDateInToday(date)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(theme.color(for: min(count, 4), isDarkMode: colorScheme == .dark))
                            .frame(width: 10, height: 10)
                            .overlay(
                                Group {
                                    if isToday && todayCellAnimating {
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                            .scaleEffect(todayCellAnimating ? 2 : 1)
                                            .opacity(todayCellAnimating ? 0 : 1)
                                            .animation(
                                                Animation.easeOut(duration: 1).repeatCount(1, autoreverses: false),
                                                value: todayCellAnimating
                                            )
                                    }
                                }
                            )
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // 整行点击时触发导航
                NotificationCenter.default.post(name: NSNotification.Name("NavigateToDetail"), object: habit)
            }
            
            Spacer()
            
            // 添加打卡按钮，使用ZStack实现动画效果
            Button(action: {
                // 触发动画
                isAnimating = true
                todayCellAnimating = true
                
                // 执行打卡操作
                habitStore.logHabit(habitId: habit.id, date: Date())
                
                // 动画完成后重置状态
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                    isAnimating = false
                    todayCellAnimating = false
                }
            }) {
                ZStack {
                    // 只在动画触发时显示波浪效果
                    if isAnimating {
                        Circle()
                            .stroke(Color.accentColor, lineWidth: 2)
                            .scaleEffect(isAnimating ? 2.5 : 1)
                            .opacity(isAnimating ? 0 : 1)
                            .animation(
                                Animation.easeOut(duration: 1).repeatCount(1, autoreverses: false),
                                value: isAnimating
                            )
                    }
                    
                    // 主按钮
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(isAnimating ? .white : .accentColor)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(isAnimating ? Color.accentColor : Color.accentColor.opacity(0.1))
                        )
                        .animation(.easeOut(duration: 0.3), value: isAnimating)
                }
                .frame(width: 44, height: 44)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
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
