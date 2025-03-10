# Widget 与主应用数据同步机制

## 同步挑战

在 iOS 应用开发中，Widget 和主应用之间的数据同步是一个常见挑战。虽然两者可以共享 UserDefaults 数据，但由于它们运行在不同的进程中，数据变化不会自动通知对方。

## 我们的解决方案

我们实现了一个全面的同步机制，确保数据在 Widget 和主应用之间双向同步：

### 1. 主应用 → Widget 同步

当主应用中的数据更改时：

```swift
// 在 HabitStore 中的数据修改方法中
private func refreshWidgets() {
    WidgetCenter.shared.reloadAllTimelines()
}
```

这会通知所有 Widget 刷新其时间线，从而获取最新数据。

### 2. Widget → 主应用同步

当 Widget 更新数据时，我们使用三层机制确保主应用能感知变化：

#### a. 通知中心通知

Widget 直接发送通知：

```swift
NotificationCenter.default.post(
    name: Notification.Name("WidgetDataUpdated"),
    object: nil,
    userInfo: ["habitId": habitId]
)
```

#### b. 时间戳标记

Widget 在 UserDefaults 中保存更新时间戳：

```swift
sharedDefaults.set(Date().timeIntervalSince1970, forKey: "lastWidgetUpdateTime")
```

#### c. 应用前台检查

当应用进入前台时，检查是否有 Widget 更新：

```swift
@objc private func appWillEnterForeground() {
    checkForWidgetUpdates()
}
```

## 数据流程图

```
[Widget 打卡] → [共享 UserDefaults] → [主应用 HabitStore]
                                    ↓
                               [UI 更新]
                               
[主应用打卡] → [共享 UserDefaults] → [Widget 刷新]
```

## 调试提示

如果同步仍有问题，可以检查：

1. 控制台日志中的以下消息：
   - "Widget 打卡操作已执行，正在请求刷新所有 Widget..."
   - "收到 Widget 数据更新通知，正在刷新数据..."
   - "检测到 Widget 数据更新，正在刷新数据..."

2. 确认 App Group 设置正确

3. 确认 ContentView 正确使用了 @EnvironmentObject 来访问 HabitStore

## 系统限制

请注意，iOS 对进程间通信有一些限制：

1. 如果主应用未运行，通知中心通知将无法送达
2. 如果主应用在后台，可能需要等到应用进入前台才能更新 UI
3. Widget 更新频率受系统限制 