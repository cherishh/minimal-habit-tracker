# EasyHabit - 极简习惯追踪应用

EasyHabit是一个专注于简洁和实用性的习惯追踪应用，帮助用户通过视觉化的热力图追踪习惯的养成过程。应用支持iOS和iPadOS，并提供Widget功能，让用户可以直接在主屏幕上记录和查看习惯。

## 目录

- [应用架构概览](#应用架构概览)
- [数据模型](#数据模型)
- [主要视图和功能](#主要视图和功能)
- [数据持久化](#数据持久化)
- [主应用与Widget通信](#主应用与widget通信)
- [主要功能实现](#主要功能实现)
- [开发和扩展注意事项](#开发和扩展注意事项)

## 应用架构概览

应用采用SwiftUI框架开发，使用MVVM架构模式：

- **Models**: 定义数据结构和业务逻辑
- **Views**: 负责UI呈现和用户交互
- **ViewModel/Store**: 处理数据状态管理

应用分为两个主要部分：
1. **主应用**：习惯管理、详情查看和设置
2. **Widget**：提供在主屏幕上快速打卡和查看习惯状态的功能

### 目录结构

```
minimal habit tracker/
├── Models/                   # 数据模型
│   ├── Habit.swift           # 习惯模型
│   ├── HabitLog.swift        # 习惯记录模型
│   ├── ColorTheme.swift      # 颜色主题
│   └── HabitStore.swift      # 数据存储和管理
├── Views/                    # 视图组件
│   ├── NewHabitView.swift    # 创建新习惯界面
│   ├── HabitDetailView.swift # 习惯详情界面
│   └── EmojiPickerView.swift # Emoji选择器
├── ContentView.swift         # 主界面
└── minimal_habit_trackerApp.swift # 应用入口

mid-widget/                   # Widget扩展
├── mid_widget.swift          # Widget主要实现
├── mid_widgetBundle.swift    # Widget入口
└── Info.plist                # Widget配置
```

## 数据模型

### Habit

习惯的基本数据模型，包含以下属性：

```swift
struct Habit: Identifiable, Codable {
    var id = UUID()           // 唯一标识符
    var name: String          // 习惯名称
    var emoji: String         // 表情符号
    var colorTheme: ColorThemeName // 颜色主题
    var habitType: HabitType  // 习惯类型(checkbox/count)
    var createdAt = Date()    // 创建时间
    var backgroundColor: String? // 可选背景色
}
```

习惯支持两种类型：
- **Checkbox**：打卡/未打卡，点击一次完成，再次点击取消
- **Count**：计数器模式，最多支持4次递增，第5次重置为0

### HabitLog

记录用户的习惯打卡记录：

```swift
struct HabitLog: Identifiable, Codable {
    var id = UUID()
    var habitId: UUID         // 关联的习惯ID
    var date: Date            // 记录日期
    var count: Int            // 记录次数
    
    var level: Int {          // 热力图颜色级别(0-4)
        min(count, 4)
    }
}
```

### HabitStore

负责数据管理、持久化和同步的核心类：

```swift
class HabitStore: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var habitLogs: [HabitLog] = []
    
    // 其他方法和属性...
}
```

主要功能包括：
- 习惯CRUD操作
- 日志记录和查询
- 数据持久化
- 与Widget数据同步
- 提供统计信息（总打卡天数、连续天数等）

## 主要视图和功能

### ContentView

应用的主界面，包含：
- 自定义标题栏（应用名称、添加按钮、设置按钮）
- 习惯列表或空状态视图
- 侧滑删除功能
- 导航至详情页面的功能

主要组件：
- `HabitCardView`：展示单个习惯卡片，包含名称、热力图和打卡按钮
- `MiniHeatmapView`：微型热力图，展示习惯记录
- `SettingsView`：应用设置视图（主题切换等）

### HabitDetailView

习惯详情界面，展示更详细的习惯信息和打卡记录：
- GitHub风格年度热力图
- 月历视图
- 习惯统计信息（总打卡天数、连续天数）
- 编辑习惯入口

主要组件：
- `GitHubStyleHeatmapView`：年度热力图
- `MonthCalendarView`：月历视图
- `YearPicker`：年份选择器

### NewHabitView

创建或编辑习惯的界面：
- 习惯名称输入
- Emoji选择器
- 颜色主题选择
- 习惯类型选择

## 数据持久化

应用使用`UserDefaults`进行数据持久化，结合App Group功能实现主应用与Widget之间的数据共享：

```swift
// 共享UserDefaults实例
private let sharedDefaults = UserDefaults(suiteName: "group.com.xi.HabitTracker.minimal-habit-tracker") ?? UserDefaults.standard
```

### 保存数据流程

1. 将数据模型转换为JSON数据
2. 将JSON数据存储到共享UserDefaults
3. 更新时间戳用于数据同步
4. 刷新Widget以反映数据变化

```swift
func saveData() {
    // 获取shared UserDefaults
    let sharedDefaults = UserDefaults(suiteName: "group.com.xi.HabitTracker.minimal-habit-tracker") ?? UserDefaults.standard
    
    do {
        // 保存习惯列表
        let habitsData = try JSONEncoder().encode(habits)
        sharedDefaults.set(habitsData, forKey: habitsKey)
        
        // 保存习惯日志
        let habitLogsData = try JSONEncoder().encode(habitLogs)
        sharedDefaults.set(habitLogsData, forKey: habitLogsKey)
        
        // 更新时间戳，标记数据已更新
        let updateTimestampKey = "widgetDataUpdateTimestamp"
        lastWidgetUpdateTimestamp = Date().timeIntervalSince1970
        sharedDefaults.set(lastWidgetUpdateTimestamp, forKey: updateTimestampKey)
        
        // 确保数据变化通知发送给观察者
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
        
        // 刷新所有Widget
        refreshWidgets()
    } catch {
        print("保存数据失败: \(error)")
    }
}
```

### 加载数据流程

1. 从共享UserDefaults读取JSON数据
2. 解码为应用数据模型
3. 更新应用状态

```swift
private func loadData() {
    if let habitsData = sharedDefaults.data(forKey: habitsKey),
       let decodedHabits = try? JSONDecoder().decode([Habit].self, from: habitsData) {
        habits = decodedHabits
    }
    
    if let logsData = sharedDefaults.data(forKey: habitLogsKey),
       let decodedLogs = try? JSONDecoder().decode([HabitLog].self, from: logsData) {
        habitLogs = decodedLogs
    }
}
```

## 主应用与Widget通信

### 数据同步机制

主应用和Widget之间通过共享的UserDefaults和时间戳机制实现数据同步：

1. **时间戳标记**：
   - 每次数据变更，更新`widgetDataUpdateTimestamp`时间戳
   - 通过比较时间戳确定数据是否需要更新

2. **观察者模式**：
   - 监听`UserDefaults.didChangeNotification`通知
   - 监听应用生命周期事件（如进入前台）
   - 当检测到更新时，重新加载数据

```swift
private func checkForWidgetUpdates() {
    // 获取shared UserDefaults
    let sharedDefaults = UserDefaults(suiteName: "group.com.xi.HabitTracker.minimal-habit-tracker") ?? UserDefaults.standard
    
    // 检查Widget更新时间戳
    let updateTimestampKey = "widgetDataUpdateTimestamp"
    let currentTimestamp = sharedDefaults.double(forKey: updateTimestampKey)
    
    // 如果时间戳比上次记录的更新，则重新加载数据
    if currentTimestamp > lastWidgetUpdateTimestamp && currentTimestamp > 0 {
        lastWidgetUpdateTimestamp = currentTimestamp
        loadData()
        
        // 发出通知
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Notification.Name("WidgetDataSynced"),
                object: nil
            )
        }
    }
}
```

### Widget交互方式

Widget提供两种与用户交互的方式：

1. **URL Scheme交互**：
   - 点击Widget左侧区域打开应用并显示对应习惯
   - URL格式：`easyhabit://widget/open?habitId=xxx`

2. **AppIntent直接交互**（iOS 17+）：
   - 点击Widget右侧区域直接打卡，无需打开应用
   - 使用`Button(intent:)`和`.invalidatableContent()`实现

```swift
// iOS 17 新方式：使用 Button(intent:) 进行直接交互
Button(intent: CheckInHabitIntent(habitId: habit.id.uuidString)) {
    // 按钮内容...
}
.invalidatableContent()
```

### URL处理

主应用通过`onOpenURL`回调处理来自Widget的URL请求：

```swift
.onOpenURL { url in
    handleURL(url)
}
```

URL处理逻辑包括：
- 检查URL scheme是否匹配（`easyhabit`）
- 解析URL路径和参数
- 根据路径执行相应操作（打开详情页或执行打卡）
- 通过NotificationCenter发送通知更新UI

## 主要功能实现

### 习惯打卡

主应用中的打卡逻辑：

```swift
func logHabit(habitId: UUID, date: Date) {
    // 标准化日期（只保留年月日）
    let calendar = Calendar.current
    let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
    let normalizedDate = calendar.date(from: dateComponents)!
    
    // 查找对应的习惯
    guard let habit = habits.first(where: { $0.id == habitId }) else { return }
    
    if let existingLogIndex = habitLogs.firstIndex(where: { log in
        log.habitId == habitId && calendar.isDate(log.date, inSameDayAs: normalizedDate)
    }) {
        // 根据习惯类型更新现有记录
        let currentCount = habitLogs[existingLogIndex].count
        
        switch habit.habitType {
        case .checkbox:
            // 对于checkbox类型，第二次点击会取消记录
            if currentCount > 0 {
                habitLogs.remove(at: existingLogIndex)
            }
        case .count:
            // 对于count类型，第5次点击会清零记录
            if currentCount >= 4 {
                habitLogs.remove(at: existingLogIndex)
            } else {
                habitLogs[existingLogIndex].count += 1
            }
        }
    } else {
        // 创建新记录
        let initialCount = habit.habitType == .checkbox ? 4 : 1
        let newLog = HabitLog(habitId: habitId, date: normalizedDate, count: initialCount)
        habitLogs.append(newLog)
    }
    
    saveData()
    refreshWidgets()
}
```

Widget中的打卡逻辑（通过AppIntent）：

```swift
func perform() async throws -> some IntentResult {
    // 共享 UserDefaults - 和主应用使用相同的组标识
    let sharedDefaults = UserDefaults(suiteName: "group.com.xi.HabitTracker.minimal-habit-tracker") ?? UserDefaults.standard
    
    // 当前时间
    let now = Date()
    
    // 从 UserDefaults 加载日志数据
    let habitLogsKey = "habitLogs"
    var habitLogs: [HabitLog] = []
    
    if let logsData = sharedDefaults.data(forKey: habitLogsKey),
       let decodedLogs = try? JSONDecoder().decode([HabitLog].self, from: logsData) {
        habitLogs = decodedLogs
    }
    
    // 处理打卡逻辑...
    
    // 保存数据并更新时间戳...
    
    return .result()
}
```

### 热力图绘制

应用使用自定义视图实现GitHub风格的热力图：

```swift
struct GitHubStyleHeatmapView: View {
    let habit: Habit
    let selectedYear: Int
    let colorScheme: ColorScheme
    
    // 绘制热力图...
}
```

微型热力图用于列表视图中的简要展示：

```swift
struct MiniHeatmapView: View, Equatable {
    let habitId: UUID
    
    // 绘制微型热力图...
}
```

### 连续打卡计算

```swift
func getLongestStreak(habitId: UUID) -> Int {
    let filteredLogs = habitLogs.filter { $0.habitId == habitId }
    guard !filteredLogs.isEmpty else { return 0 }
    
    // 按日期排序
    let sortedDates = filteredLogs.map { $0.date }.sorted()
    
    let calendar = Calendar.current
    var currentStreak = 1
    var longestStreak = 1
    
    for i in 1..<sortedDates.count {
        let previousDate = sortedDates[i-1]
        let currentDate = sortedDates[i]
        
        // 检查是否为连续日期
        let dayDifference = calendar.dateComponents([.day], from: previousDate, to: currentDate).day ?? 0
        
        if dayDifference == 1 {
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
        } else if dayDifference > 1 {
            currentStreak = 1
        }
    }
    
    return longestStreak
}
```

## 开发和扩展注意事项

### 已知限制

1. **最大习惯数量**：当前限制为10个习惯
2. **交互限制**：Widget上的交互功能在iOS 16及以下版本通过URL Scheme实现，交互体验有限
3. **UI自定义**：目前支持的自定义选项相对简单，主要是颜色主题和Emoji

## 总结

EasyHabit应用提供了一个简洁、直观的习惯追踪体验，通过热力图可视化习惯养成过程，并通过Widget支持快速打卡。应用采用现代SwiftUI框架开发，使用App Group实现主应用与Widget的数据共享，支持最新的iOS 17 Widget交互特性。 

## 主应用与Widget通信

### 数据同步机制概述

EasyHabit的主应用和Widget之间通过三重机制实现可靠的数据同步：

1. **共享存储机制**：
   - App Group技术用于在主应用和Widget扩展之间共享UserDefaults
   - 共同的存储密钥确保数据访问一致性
   - 固定的数据结构序列化/反序列化过程

2. **时间戳变更追踪**：
   - 独特的时间戳追踪方法识别哪方进行了最新更改
   - 增量式更新避免不必要的数据刷新
   - 双向验证机制确保数据一致性

3. **多层通知系统**：
   - 使用多种通知机制实现数据变更的准确传播
   - 生命周期事件钩子确保状态更新
   - 交互反馈循环确保用户体验连贯性

### 详细数据流程

#### 主应用到Widget的数据流

当用户在主应用中进行操作（如添加习惯、记录打卡）时：

1. `HabitStore`中的相关方法更新内存中的数据模型
2. 调用`saveData()`方法将数据序列化并保存到共享UserDefaults
3. 同时更新`widgetDataUpdateTimestamp`时间戳
4. 调用`WidgetCenter.shared.reloadAllTimelines()`刷新所有Widget

具体代码流程：

```swift
// 用户在主应用中打卡
habitStore.logHabit(habitId: uuid, date: Date())

// 在HabitStore.logHabit()方法内部最终调用
func saveData() {
    do {
        // 序列化数据
        let habitsData = try JSONEncoder().encode(habits)
        let habitLogsData = try JSONEncoder().encode(habitLogs)
        
        // 保存到共享UserDefaults
        sharedDefaults.set(habitsData, forKey: habitsKey)
        sharedDefaults.set(habitLogsData, forKey: habitLogsKey)
        
        // 更新时间戳(关键步骤)
        let updateTimestampKey = "widgetDataUpdateTimestamp"
        lastWidgetUpdateTimestamp = Date().timeIntervalSince1970
        sharedDefaults.set(lastWidgetUpdateTimestamp, forKey: updateTimestampKey)
        
        // 发送SwiftUI状态更新通知
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
        
        // 刷新所有Widget
        refreshWidgets()
    } catch {
        print("保存数据失败: \(error)")
    }
}
```

#### Widget到主应用的数据流

当用户在Widget上进行打卡操作时：

1. **通过URL方式(iOS 16及以下)**：
   - Widget触发URL Scheme，主应用被打开
   - 主应用的`handleURL`方法解析URL并执行相应操作
   - 主应用发送通知更新界面

2. **通过AppIntent方式(iOS 17+)**：
   - 调用`CheckInHabitIntent.perform()`方法直接在Widget进程中执行
   - 将更新后的数据保存到共享UserDefaults
   - 更新`widgetDataUpdateTimestamp`时间戳
   - 主应用通过观察UserDefaults变化或下次进入前台时感知更新

URL处理的详细代码流程：

```swift
// 处理从Widget打开的URL
private func handleURL(_ url: URL) {
    // 确认URL Scheme
    guard url.scheme == "easyhabit" else { return }
    
    // 解析路径和参数
    if url.host == "widget" {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let habitIdItem = components.queryItems?.first(where: { $0.name == "habitId" }),
              let habitIdString = habitIdItem.value,
              let habitId = UUID(uuidString: habitIdString) else {
            return
        }
        
        // 根据路径执行不同操作
        if url.path == "/checkin" {
            // 执行打卡操作
            habitStore.logHabit(habitId: habitId, date: Date())
            
            // 发送各种通知更新界面
            NotificationCenter.default.post(
                name: Notification.Name("WidgetCheckInCompleted"), 
                object: habitId
            )
            
            NotificationCenter.default.post(
                name: Notification.Name("WidgetDataUpdated"), 
                object: nil
            )
            
            // 刷新Widget
            WidgetCenter.shared.reloadAllTimelines()
            
        } else if url.path == "/open" {
            // 打开习惯详情
            if let habit = habitStore.habits.first(where: { $0.id == habitId }) {
                // 通过通知触发导航
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToDetail"), 
                    object: habit
                )
            }
        }
    }
}
```

AppIntent的详细代码流程：

```swift
// iOS 17+ Widget中的AppIntent
func perform() async throws -> some IntentResult {
    // 获取共享UserDefaults
    let sharedDefaults = UserDefaults(suiteName: "group.com.xi.HabitTracker.minimal-habit-tracker") ?? UserDefaults.standard
    
    // 加载当前数据
    let habitLogsKey = "habitLogs"
    var habitLogs: [HabitLog] = []
    
    if let logsData = sharedDefaults.data(forKey: habitLogsKey),
       let decodedLogs = try? JSONDecoder().decode([HabitLog].self, from: logsData) {
        habitLogs = decodedLogs
    }
    
    // 解析habitId并创建/更新打卡记录
    if let uuid = UUID(uuidString: habitId) {
        let now = Date()
        let newLog = HabitLog(id: UUID(), habitId: uuid, date: now, count: 1)
        
        // 检查是否存在同一天的记录
        let calendar = Calendar.current
        let existingLog = habitLogs.first { 
            calendar.isDate($0.date, inSameDayAs: now) && $0.habitId == uuid 
        }
        
        if let existingLog = existingLog, let index = habitLogs.firstIndex(where: { $0.id == existingLog.id }) {
            habitLogs[index].count += 1  // 更新现有记录
        } else {
            habitLogs.append(newLog)     // 添加新记录
        }
        
        // 保存更新后的数据
        do {
            let encodedData = try JSONEncoder().encode(habitLogs)
            sharedDefaults.set(encodedData, forKey: habitLogsKey)
            
            // 关键步骤：更新时间戳，触发主应用的检测机制
            let updateTimestampKey = "widgetDataUpdateTimestamp"
            sharedDefaults.set(Date().timeIntervalSince1970, forKey: updateTimestampKey)
            
            // 刷新所有Widget，确保Widget也能反映最新状态
            WidgetCenter.shared.reloadAllTimelines()
            
            return .result()
        } catch {
            return .result() // 即使失败也返回结果，避免Widget崩溃
        }
    } else {
        return .result()
    }
}
```

### 主应用检测Widget更新机制

应用采用多重策略确保能够及时检测到Widget中的数据变更：

1. **启动时检查**：应用启动时会自动检查数据更新
2. **前台激活检查**：当应用从后台回到前台时触发检查
3. **UserDefaults变更监听**：持续监听UserDefaults变化

具体实现：

```swift
// 在HabitStore初始化时设置监听器
private func setupObservers() {
    // 监听应用进入前台事件
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(appWillEnterForeground),
        name: UIApplication.willEnterForegroundNotification,
        object: nil
    )
    
    // 监听UserDefaults变化事件
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(userDefaultsDidChange),
        name: UserDefaults.didChangeNotification,
        object: nil
    )
}

// 前台激活事件处理
@objc private func appWillEnterForeground() {
    checkForWidgetUpdates()
}

// UserDefaults变化事件处理
@objc private func userDefaultsDidChange(_ notification: Notification) {
    checkForWidgetUpdates()
}

// 检查Widget是否更新了数据
private func checkForWidgetUpdates() {
    // 获取当前时间戳
    let updateTimestampKey = "widgetDataUpdateTimestamp"
    let currentTimestamp = sharedDefaults.double(forKey: updateTimestampKey)
    
    // 比较时间戳，确定是否有更新
    if currentTimestamp > lastWidgetUpdateTimestamp && currentTimestamp > 0 {
        // 记录新的时间戳
        lastWidgetUpdateTimestamp = currentTimestamp
        
        // 重新加载数据
        loadData()
        
        // 通知界面刷新
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Notification.Name("WidgetDataSynced"),
                object: nil
            )
        }
    }
}
```

### 通信流程图

下面是完整的数据流程图，展示了主应用和Widget之间的通信方式：

```
主应用变更数据                           Widget变更数据
    │                                       │
    ▼                                       ▼
更新内存数据模型                     通过AppIntent实现直接更新
    │                                       │
    ▼                                       ▼
序列化并保存到                       序列化并保存到
共享UserDefaults                     共享UserDefaults
    │                                       │
    ▼                                       ▼
更新widgetDataUpdateTimestamp      更新widgetDataUpdateTimestamp
    │                                       │
    ▼                                       ▼
刷新所有Widget                       刷新所有Widget
    │                                       │
    │                                       │
    └───────────────┬───────────────────────┘
                    │
                    ▼
          主应用检测数据变更:
          1. 应用启动时
          2. 进入前台时
          3. UserDefaults变化时
                    │
                    ▼
             重新加载数据
                    │
                    ▼
           发送UI更新通知
```

### 特殊情况处理

该同步机制还对一些特殊情况进行了处理：

1. **并发修改**：时间戳机制确保最新的修改会被优先采用
2. **应用被杀死**：即使应用被完全关闭，下次启动时仍能准确反映数据状态
3. **断断续续的网络**：本地存储确保即使在离线状态下也能正常工作
4. **数据损坏**：每个操作都有适当的错误处理以提高鲁棒性

## 开发和扩展注意事项

### 项目特定的数据同步注意事项

1. **App Group配置**：
   - 必须确保App Group ID `group.com.xi.HabitTracker.minimal-habit-tracker` 在主应用和Widget扩展的entitlements文件中正确配置
   - 项目配置文件中Capabilities设置需要启用App Groups
   - 同一个App Group ID必须在Apple Developer Portal中注册并分配给应用

   ```xml
   <!-- minimal habit tracker.entitlements -->
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>com.apple.security.application-groups</key>
       <array>
           <string>group.com.xi.HabitTracker.minimal-habit-tracker</string>
       </array>
   </dict>
   </plist>
   ```

2. **数据key命名冲突**：
   - 目前使用的数据存储键（`habitsKey`和`habitLogsKey`）必须在应用和Widget间保持一致
   - 避免在`HabitStore`外部使用同名键存储数据，以防止冲突
   - 如需扩展，建议使用前缀或命名空间来避免重复

3. **Widget刷新策略**：
   - 当前Widget配置为每小时刷新一次（`context: .after(nextUpdateDate)`）
   - 考虑用户使用模式的频率，可能需要调整为更短的周期
   - 对于频繁的习惯记录，应考虑更积极的刷新策略
   
   ```swift
   // 当前的Widget刷新策略
   func timeline(for configuration: HabitSelectionIntent, in context: Context) async -> Timeline<HabitEntry> {
       let entry = await snapshot(for: configuration, in: context)
       
       // 每小时刷新一次
       let nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
       
       return Timeline(entries: [entry], policy: .after(nextUpdateDate))
   }
   ```

4. **时间戳检测灵敏度**：
   - 当前实现中可能存在多次通知触发的问题，建议添加防抖动机制
   - 考虑设置最小更新时间间隔（例如1秒）避免过于频繁的刷新
   - 在高频率操作的情况下可能导致性能问题

   ```swift
   // 建议改进的检测机制（添加防抖动）
   private var lastCheckTime: TimeInterval = 0
   
   private func checkForWidgetUpdates() {
       let now = Date().timeIntervalSince1970
       
       // 防抖动：至少间隔1秒才检查
       if now - lastCheckTime < 1.0 {
           return
       }
       
       lastCheckTime = now
       
       // 其余检查逻辑...
   }
   ```

### iOS 17特定功能的兼容性处理

1. **AppIntent向后兼容性**：
   - 当前项目使用iOS 17新的AppIntent API实现Widget交互
   - 为支持iOS 16及更早版本，保留了基于URL Scheme的备选方案
   - 需要维护这两套代码，确保所有功能都能在不同iOS版本下正常工作

2. **iOS版本检测**：
   - 在使用新API时应添加合适的版本检测，以避免在旧版本iOS上崩溃
   
   ```swift
   if #available(iOS 17.0, *) {
       // 使用AppIntent的新方法
       Button(intent: CheckInHabitIntent(habitId: habit.id.uuidString)) {
           // 按钮内容
       }
       .invalidatableContent()
   } else {
       // 回退到旧的URL Scheme方式
       Link(destination: URL(string: "easyhabit://widget/checkin?habitId=\(habit.id.uuidString)")!) {
           // 按钮内容
       }
   }
   ```

3. **测试策略**：
   - 对于这种有版本区分的功能，需要在多个iOS版本上进行测试
   - 确保iOS 16用户能够通过URL Scheme方式正常交互
   - 确保iOS 17用户能够享受到直接交互的便利性

### 项目架构扩展注意事项

1. **数据模型解耦**：
   - 当前`HabitStore`职责过多，建议拆分为更专注的组件：
     - `HabitDataStore`: 专注于数据存储和持久化
     - `HabitSyncService`: 专注于数据同步机制
     - `HabitAnalytics`: 专注于统计和分析功能
   - 这将使代码更易于维护和扩展


3. **复杂数据处理**：
   - 随着习惯和日志数量增长，内存中处理大量数据可能引起性能问题
   - 考虑实现分页加载或懒加载机制
   - 对于如`getLongestStreak`这样的计算密集型函数，考虑使用缓存
   
   ```swift
   // 缓存示例（添加到HabitStore）
   private var streakCache: [UUID: (timestamp: TimeInterval, value: Int)] = [:]
   
   func getLongestStreak(habitId: UUID) -> Int {
       // 检查缓存是否存在且未过期（5分钟内）
       let now = Date().timeIntervalSince1970
       if let cached = streakCache[habitId], 
          now - cached.timestamp < 300 { // 5分钟缓存
           return cached.value
       }
       
       // 计算新值...
       let result = calculateLongestStreak(habitId: habitId)
       
       // 更新缓存
       streakCache[habitId] = (timestamp: now, value: result)
       
       return result
   }
   ```

4. **项目目录结构重构**：
   - 随着项目复杂度增加，考虑更细致的目录结构：
   
   ```
   minimal habit tracker/
   ├── Models/
   │   ├── Data/                 # 数据模型定义
   │   ├── Services/             # 业务逻辑和服务
   │   └── Utils/                # 工具类和辅助函数
   ├── Views/
   │   ├── Main/                 # 主界面视图
   │   ├── Detail/               # 详情界面视图
   │   ├── Form/                 # 表单相关视图
   │   ├── Components/           # 可复用组件
   │   └── Modifiers/            # 自定义视图修饰符
   ├── Extensions/               # Swift扩展
   ├── Resources/                # 资源文件
   └── Configuration/            # 配置文件
   ```

### 实际开发中遇到的问题及解决方案

1. **Widget打卡后主应用状态未更新**：
   - 症状：在Widget上打卡后，主应用中的状态未能及时更新
   - 原因：检测机制不够灵敏，且未能在正确的时间触发UI更新
   - 解决方案：添加`UserDefaults.didChangeNotification`监听，并使用时间戳机制确保最新状态被加载
  
2. **复杂热力图渲染性能问题**：
   - 症状：热力图在大量数据时渲染缓慢，导致界面卡顿
   - 解决方案：实现了`Equatable`协议，并使用`.equatable()`修饰符避免不必要的重新渲染
   - 使用了更高效的绘制策略，将大量格子合并为较少的绘制操作

3. **Widget资源限制**：
   - 问题：Widget有严格的内存和CPU使用限制
   - 在Widget中避免复杂计算，尽可能将计算结果存储在共享存储中

4. **应用进入后台时数据保存不完整**：
   - 问题：当应用被迅速切换到后台时，保存操作可能未完成
   - 解决方案：在`applicationWillResignActive`中主动触发保存操作，并使用同步保存确保完成
   
   ```swift
   @objc private func applicationWillResignActive() {
       // 确保数据保存完成
       saveData()
       sharedDefaults.synchronize()
   }
   ```
