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
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        if let index = habitStore.habits.firstIndex(where: { $0.id == habit.id }) {
                            withAnimation {
                                habitStore.removeHabit(habit)
                            }
                        }
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                    .tint(.red)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct HabitRowView: View {
    let habit: Habit
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.colorScheme) var colorScheme
    @State private var isAnimating = false
    @State private var todayCellAnimating = false
    @State private var progressValue: CGFloat = 0
    
    // 获取当前习惯的今日完成情况
    private var todayCompletionStatus: Int {
        habitStore.getLogCountForDate(habitId: habit.id, date: Date())
    }
    
    // 判断今天是否已完成打卡
    private var isCompletedToday: Bool {
        todayCompletionStatus > 0
    }
    
    // 获取计数型习惯的进度百分比 (0-1)
    private var countProgress: CGFloat {
        let count = CGFloat(todayCompletionStatus)
        return min(count / 4.0, 1.0)
    }
    
    // 获取习惯对应的主题颜色
    private var theme: ColorTheme {
        ColorTheme.getTheme(for: habit.colorTheme)
    }
    
    var body: some View {
        // 卡片容器
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // 左侧：图标和名称
                HStack(spacing: 12) {
                    // Emoji图标
                    Text(habit.emoji)
                        .font(.system(size: 30))
                        .frame(width: 52, height: 52)
                        .background(
                            Circle()
                                .fill(habit.backgroundColor != nil ? Color(hex: habit.backgroundColor!) : Color.gray.opacity(0.1))
                        )
                    
                    // 习惯名称
                    Text(habit.name)
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                }
                .padding(.leading, 20)
                .padding(.vertical, 20)
                .frame(width: UIScreen.main.bounds.width * 0.45, alignment: .leading) // 限制左侧区域宽度
                
                Spacer()
                
                // 右侧区域：分成两部分
                VStack(alignment: .trailing, spacing: 16) {
                    // 上方：最近10天小型热力图
                    HStack(spacing: 5) {
                        ForEach(0..<10, id: \.self) { dayOffset in
                            let date = Calendar.current.date(byAdding: .day, value: -(9-dayOffset), to: Date())!
                            let count = habitStore.getLogCountForDate(habitId: habit.id, date: date)
                            let isToday = Calendar.current.isDateInToday(date)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(theme.color(for: min(count, 4), isDarkMode: colorScheme == .dark))
                                .frame(width: 14, height: 14)
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
                    .padding(.bottom, 4)
                    
                    // 下方：打卡按钮
                    Button(action: {
                        // 触发动画
                        isAnimating = true
                        todayCellAnimating = true
                        
                        if habit.habitType == .count {
                            // 计数模式：更新进度值
                            let currentCount = todayCompletionStatus
                            if currentCount < 4 {
                                withAnimation(.spring()) {
                                    progressValue = CGFloat(currentCount + 1) / 4.0
                                }
                            } else {
                                withAnimation(.spring()) {
                                    progressValue = 0
                                }
                            }
                        }
                        
                        // 执行打卡操作
                        habitStore.logHabit(habitId: habit.id, date: Date())
                        
                        // 动画完成后重置状态
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                            isAnimating = false
                            todayCellAnimating = false
                        }
                    }) {
                        if habit.habitType == .checkbox {
                            // Checkbox模式按钮 - 圆角矩形
                            Text(isCompletedToday ? "Done!" : "Check")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(isCompletedToday ? .white : theme.color(for: 4, isDarkMode: colorScheme == .dark))
                                .frame(width: 140)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(isCompletedToday 
                                            ? theme.color(for: 4, isDarkMode: colorScheme == .dark) 
                                            : theme.color(for: 0, isDarkMode: colorScheme == .dark))
                                )
                                .animation(.spring(), value: isCompletedToday)
                        } else {
                            // Count模式按钮 - 完整圆角效果
                            VStack(spacing: 0) {
                                // 顶部进度条区域
                                ZStack(alignment: .leading) {
                                    // 背景轨道
                                    Capsule()
                                        .fill(theme.color(for: 0, isDarkMode: colorScheme == .dark).opacity(0.3))
                                        .frame(width: 140, height: 4)
                                    
                                    // 进度条
                                    Capsule()
                                        .fill(theme.color(for: 4, isDarkMode: colorScheme == .dark))
                                        .frame(width: 140 * countProgress, height: 4)
                                        .animation(.spring(), value: countProgress)
                                }
                                .padding(.bottom, 4)
                                
                                // 按钮主体
                                Text(todayCompletionStatus >= 4 ? "Done!" : "Check")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(isCompletedToday ? .white : theme.color(for: 4, isDarkMode: colorScheme == .dark))
                                    .frame(width: 140)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(isCompletedToday 
                                                ? theme.color(for: min(todayCompletionStatus, 4), isDarkMode: colorScheme == .dark) 
                                                : theme.color(for: 0, isDarkMode: colorScheme == .dark))
                                    )
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.trailing, 20)
                .padding(.vertical, 20)
            }
        }
        .background(Color(colorScheme == .dark ? UIColor.secondarySystemBackground : UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .onTapGesture {
            // 卡片点击时触发导航
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToDetail"), object: habit)
        }
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
