import SwiftUI

// 单独的习惯卡片视图
struct HabitCardView: View {
    let habit: Habit
    let onDelete: () -> Void
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.colorScheme) var colorScheme
    @State private var isAnimating = false
    @State private var animatedCompletion: Double = 0
    @State private var offset: CGFloat = 0
    @State private var isSwiped = false
    
    // 移除本地状态变量，直接计算当前状态
    // 获取习惯对应的主题颜色
    private var theme: ColorTheme {
        ColorTheme.getTheme(for: habit.colorTheme)
    }
    
    // 判断今天是否已完成打卡 - 直接从 habitStore 获取
    private var isCompletedToday: Bool {
        habitStore.getLogCountForDate(habitId: habit.id, date: Date()) > 0
    }
    
    // 获取计数型习惯的进度百分比 (0-1) - 直接从 habitStore 获取
    private var countProgress: CGFloat {
        let count = CGFloat(habitStore.getLogCountForDate(habitId: habit.id, date: Date()))
        return min(count / CGFloat(habit.maxCheckInCount), 1.0)
    }
    
    // 获取连续打卡天数 - 直接从 habitStore 获取
    private var currentStreak: Int {
        let calendar = Calendar.current
        let today = Date()
        var dayCount = 0
        
        // 从今天开始向前查找连续打卡的天数
        for dayOffset in 0..<100 { // 最多查找100天
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            // 获取该日期的打卡记录
            let count = habitStore.getLogCountForDate(habitId: habit.id, date: date)
            
            // 如果这天有打卡记录，增加计数
            if count > 0 {
                dayCount += 1
            } else if dayOffset > 0 { // 遇到未打卡的日期且不是今天，结束计数
                break
            }
        }
        
        return dayCount
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // 删除按钮背景层
            HStack {
                Spacer()
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        offset = 0 // 先重置位置
                        isSwiped = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onDelete()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.85))
                .frame(width: 44, height: 44)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        
                        Image("trash")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundColor(.white)
                    }
                    .contentShape(Circle()) // 确保整个圆形区域可点击
                }
                .padding(.trailing, 24)
                .opacity(offset < 0 ? 1 : 0) // 当卡片滑动时显示按钮
                .frame(width: 60, height: 60) // 增加点击区域
            }
            
            // 卡片主体
            mainCardView
                .offset(x: offset)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { value in
                            // 只处理水平滑动，忽略垂直滑动
                            let horizontalDrag = abs(value.translation.width)
                            let verticalDrag = abs(value.translation.height)
                            
                            // 如果垂直滑动大于水平滑动，则不处理手势(让父ScrollView处理)
                            if verticalDrag > horizontalDrag {
                                return
                            }
                            
                            if value.translation.width < 0 {
                                offset = value.translation.width
                                if offset < -80 {
                                    offset = -80
                                }
                            } else if isSwiped {
                                offset = -80 + value.translation.width
                                if offset > 0 {
                                    offset = 0
                                }
                            }
                        }
                        .onEnded { value in
                            // 同样，只处理水平滑动
                            let horizontalDrag = abs(value.translation.width)
                            let verticalDrag = abs(value.translation.height)
                            
                            // 如果垂直滑动大于水平滑动，则不处理手势
                            if verticalDrag > horizontalDrag {
                                return
                            }
                            
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if value.translation.width < -20 || (isSwiped && value.translation.width < 20) {
                                    offset = -80
                                    isSwiped = true
                                } else {
                                    offset = 0
                                    isSwiped = false
                                }
                            }
                        }
                )
        }
        .allowsHitTesting(true)
        .frame(maxWidth: .infinity)
    }
    
    // 提取卡片主视图
    private var mainCardView: some View {
        VStack(spacing: 0) {
            // 上部分：习惯名称和连续打卡天数
            HStack {
                Text(habit.name)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .primary.opacity(0.8) : .primary)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                
                Spacer()
                
                // 连续打卡天数
                if currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundColor(colorScheme == .dark 
                                ? theme.color(for: 4, isDarkMode: true)
                                : theme.color(for: 5, isDarkMode: false))
                        
                        Text("\(currentStreak)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(colorScheme == .dark 
                                ? theme.color(for: 4, isDarkMode: true)
                                : theme.color(for: 5, isDarkMode: false))
                    }
                    .padding(.trailing, 16)
                }
            }
            .background(Color(colorScheme == .dark ? UIColor.secondarySystemBackground : UIColor.systemBackground))
            
            // 下部分：微型热力图和打卡按钮
            HStack(spacing: 16) {
                // 左侧：微型热力图使用equatable修饰符，避免不必要的重渲染
                // 注意加上.equatable()修饰符
                MiniHeatmapView(habitId: habit.id)
                    .equatable()
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(colorScheme == .dark ? UIColor.tertiarySystemBackground : UIColor.secondarySystemBackground).opacity(0.5))
                    )
                    .padding(.leading, 12)
                    .padding(.top, 0)
                    .padding(.bottom, 12)
                
                Spacer()
                
                // 右侧：Emoji和打卡按钮
                checkInButton
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
            }
            .background(Color(colorScheme == .dark ? UIColor.secondarySystemBackground : UIColor.systemBackground))
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
            .contentShape(Rectangle())
            .onTapGesture {
                if isSwiped {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        offset = 0
                        isSwiped = false
                    }
                } else {
                    NotificationCenter.default.post(name: NSNotification.Name("NavigateToDetail"), object: habit)
                }
            }
    }
    
    // 打卡操作
    private func checkInHabit() {
        // 获取当前日期的计数
        let currentCount = habitStore.getLogCountForDate(habitId: habit.id, date: Date())
        
        // 计算点击后的新计数
        var newCount = currentCount
        if habit.habitType == .checkbox {
            newCount = (currentCount > 0) ? 0 : habit.maxCheckInCount
        } else {
            newCount = (currentCount >= habit.maxCheckInCount) ? 0 : currentCount + 1
        }
        
        // 设置动画的起点和终点
        let startCompletion = Double(min(currentCount, habit.maxCheckInCount)) / Double(habit.maxCheckInCount)
        let targetCompletion = Double(min(newCount, habit.maxCheckInCount)) / Double(habit.maxCheckInCount)
        
        // 先执行实际的打卡操作
        habitStore.logHabit(habitId: habit.id, date: Date())
        
        // 设置动画
        isAnimating = true
        animatedCompletion = startCompletion
        
        // 使用withAnimation创建流畅的动画效果
        withAnimation(.easeInOut(duration: 0.3)) {
            if newCount == 0 {
                // 如果是取消打卡，动画应该从当前位置返回到0
                animatedCompletion = 0
            } else {
                // 否则动画应该前进到新位置
                animatedCompletion = targetCompletion
            }
        }
        
        // 重置动画状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isAnimating = false
        }
    }
    
    // Emoji打卡按钮
    private var checkInButton: some View {
        Button(action: {
            checkInHabit()
        }) {
            ZStack {
                let currentCount = habitStore.getLogCountForDate(habitId: habit.id, date: Date())
                // 圆环
                if habit.habitType == .checkbox {
                    // Checkbox型习惯的圆环 - 先显示底色轨道
                    Circle()
                        .stroke(
                            colorScheme == .dark ?
                                theme.color(for: 1, isDarkMode: true).opacity(0.7) :
                                theme.color(for: 1, isDarkMode: false).opacity(0.4),
                            style: StrokeStyle(lineWidth: 10)
                        )
                        .frame(width: 64, height: 64)
                    
                    // 完成圆环
                    Circle()
                        .trim(from: 0, to: isCompletedToday ? 1 : 0)
                        .stroke(
                            colorScheme == .dark 
                                ? theme.color(for: min(habit.maxCheckInCount, 4), isDarkMode: true)
                                : theme.color(for: 5, isDarkMode: false),
                            style: StrokeStyle(
                                lineWidth: 10,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: isCompletedToday)
                } else {
                    // Count型习惯的圆环 - 先显示底色轨道
                    Circle()
                        .stroke(
                            colorScheme == .dark ?
                                theme.color(for: 1, isDarkMode: true).opacity(0.7) :
                                theme.color(for: 1, isDarkMode: false).opacity(0.4),
                            style: StrokeStyle(lineWidth: 10)
                        )
                        .frame(width: 64, height: 64)
                    
                    // 进度环
                    Circle()
                        .trim(from: 0, to: isAnimating ? animatedCompletion : countProgress)
                        .stroke(
                            colorScheme == .dark 
                                ? theme.color(for: min(habit.maxCheckInCount, 4), isDarkMode: true)
                                : theme.color(for: 5, isDarkMode: false),
                            style: StrokeStyle(
                                lineWidth: 10,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: isAnimating)
                        .animation(.easeInOut(duration: 0.3), value: animatedCompletion)
                }
                
                VStack(spacing: 0) {
                    // Emoji
                    Text(habit.emoji)
                        .font(.system(size: 28))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 70, height: 70)
    }
} 