//
//  ContentView.swift
//  minimal habit tracker
//
//  Created by 图蜥 on 2025/3/6.
//

import SwiftUI
import WidgetKit
import StoreKit
import MessageUI

struct ContentView: View {
    @EnvironmentObject var habitStore: HabitStore
    @State private var showingSettings = false
    @State private var showingAddHabit = false
    @State private var showDeleteConfirmation = false
    @State private var habitToDelete: Habit? = nil
    @Environment(\.colorScheme) var colorScheme
    @State private var showingSortSheet = false
    @State private var navigateToDetail = false
    @State private var selectedHabitId: UUID? = nil
    @State private var showingMaxHabitsAlert = false
    @AppStorage("themeMode") private var themeMode: Int = 0 // 0: 自适应系统, 1: 明亮模式, 2: 暗黑模式
    @State private var showingMailCannotSendAlert = false
    
    // 用于触发界面刷新的状态变量
    @State private var languageUpdateTrigger = false
    
    // 松鼠图片翻转状态
    @State private var isSquirrelFlipped = false
    
    // 自定义更淡的背景色
    private var lightBackgroundColor: Color {
        colorScheme == .dark 
            ? Color(UIColor.systemBackground) 
            : Color(UIColor.systemGroupedBackground).opacity(0.4)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                lightBackgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 自定义标题栏
                    HStack {
                        Text("EasyHabit")
                            .font(.system(size: 32, weight: .regular, design: .rounded))
                            .padding(.leading)
                                .foregroundColor(colorScheme == .dark ? .primary.opacity(0.8) : .primary)
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Button(action: {
                                if habitStore.canAddHabit() {
                                        showingAddHabit = true
                                } else {
                                    showingMaxHabitsAlert = true
                                }
                            }) {
                                Image("plus")
                                    .resizable()
                                    .renderingMode(.template)
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                                    .frame(width: 36, height: 36)
                                    .background(Color(UIColor.systemGray5).opacity(0.6))
                                    .cornerRadius(10)
                                        .foregroundColor(colorScheme == .dark ? .primary.opacity(0.8) : .primary)
                            }
                            
                            if !habitStore.habits.isEmpty {
                                Button(action: { showingSortSheet = true }) {
                                    Image(systemName: "arrow.up.arrow.down")
                                        .resizable()
                                        .renderingMode(.template)
                                        .scaledToFit()
                                        .frame(width: 18, height: 18)
                                        .frame(width: 36, height: 36)
                                        .background(Color(UIColor.systemGray5).opacity(0.6))
                                        .cornerRadius(10)
                                        .foregroundColor(colorScheme == .dark ? .primary.opacity(0.8) : .primary)
                                }
                            }
                            
                            Button(action: { showingSettings = true }) {
                                Image("settings")
                                    .resizable()
                                    .renderingMode(.template)
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                                    .frame(width: 36, height: 36)
                                    .background(Color(UIColor.systemGray5).opacity(0.6))
                                    .cornerRadius(10)
                                        .foregroundColor(colorScheme == .dark ? .primary.opacity(0.8) : .primary)
                            }
                        }
                        .padding(.trailing)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    
                    if habitStore.habits.isEmpty {
                        emptyStateView
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        habitListView
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToDetail) {
                if let habitId = selectedHabitId {
                    HabitDetailView(habitId: habitId)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddHabit) {
                NewHabitView(isPresented: $showingAddHabit)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(isPresented: $showingSettings)
            }
            .sheet(isPresented: $showingSortSheet) {
                HabitSortView(isPresented: $showingSortSheet)
            }
            .alert(isPresented: $showingMaxHabitsAlert) {
                Alert(
                    title: Text("达到最大数量".localized(in: .contentView)),
                    message: Text("最多追踪 \(HabitStore.maxHabitCount) 个习惯。这是为了帮你更好地坚持每一个:)".localized(in: .contentView)),
                    dismissButton: .default(Text("我知道了".localized(in: .contentView)))
                )
            }
            .onAppear {
                setupNotificationObserver()
            }
            .onDisappear {
                removeNotificationObserver()
            }
            .id(languageUpdateTrigger) // 通过ID变化强制刷新视图
        }
        .preferredColorScheme(getPreferredColorScheme())
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
            // 语言变化时触发视图刷新
            languageUpdateTrigger.toggle()
        }
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name("NavigateToDetail"), object: nil, queue: .main) { notification in
            if let habit = notification.object as? Habit {
                selectedHabitId = habit.id
                navigateToDetail = true
            }
        }
    }
    
    private func removeNotificationObserver() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NavigateToDetail"), object: nil)
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            
            // 简化后的文案
            Image("squirrel")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .scaleEffect(x: isSquirrelFlipped ? -1 : 1, y: 1) // 水平翻转
                .onTapGesture {
                    // 点击时翻转松鼠图片
                    isSquirrelFlipped.toggle()
                }
                .padding(.bottom, 20)
            
            Text("👇开始记录追踪你的习惯".localized(in: .contentView))
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.bottom, 40)
            
            // 大一点的添加按钮
            Button(action: { 
                if habitStore.canAddHabit() {
                    showingAddHabit = true
                }
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
                    .frame(width: 60, height: 60)
                    .background(Color(UIColor.systemGray5).opacity(0.6))
                    .cornerRadius(30)
            }
            
            Spacer()
        }
    }
    
    private var habitListView: some View {
        ScrollView {
            VStack(spacing: 16) {
            ForEach(habitStore.habits) { habit in
                    HabitCardView(habit: habit, onDelete: {
                        withAnimation {
                            // 设置要删除的习惯并显示确认对话框
                            habitToDelete = habit
                            showDeleteConfirmation = true
                        }
                    })
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .background(lightBackgroundColor)
        // 添加删除习惯的确认对话框
        .alert("确认删除".localized(in: .contentView), isPresented: $showDeleteConfirmation) {
            Button("取消".localized(in: .common), role: .cancel) { }
            Button("删除".localized(in: .common), role: .destructive) {
                if let habit = habitToDelete {
                    withAnimation {
                        habitStore.removeHabit(habit)
                    }
                }
            }
        } message: {
            Text("确定要删除这个习惯吗？所有相关的打卡记录也将被删除。此操作无法撤销。".localized(in: .contentView))
        }
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
    ContentView()
        .environmentObject(HabitStore())
}

