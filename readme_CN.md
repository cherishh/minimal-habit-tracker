# EasyHabit

[English](https://github.com/cherishh/minimal-habit-tracker/blob/main/readme.md)

**版本:** 0.1 

"EasyHabit" 是一款 iOS 平台的极简风格习惯追踪应用，旨在帮助用户以类似 GitHub contributions heatmap 的形式记录和培养日常习惯。应用核心在于简洁的界面和直观的操作，让用户能够轻松管理和追踪个人习惯的养成过程。

## 主要功能

* **习惯管理**:
    * 支持创建、编辑和删除习惯。
    * 每个习惯包含自定义名称、Emoji 图标和颜色主题。
    * 提供两种习惯类型：
        * **Checkbox (打卡型)**：一次点击即可记录完成，如“每日早餐”。
        * **Count (计数型)**：可设置每日目标次数，支持多次打卡，如“每日饮水X杯”。
    * 用户可以对习惯列表进行排序。
* **Widget (小组件) - 核心功能**:
    * 提供桌面小组件，可显示选定习惯的打卡状态和微型热力图。
    * 用户可以直接通过 Widget 进行打卡操作，无需打开主应用。
    * 支持添加多个习惯，互相之间可以上下滑动切换（利用 ios widget stack）。
* **可视化追踪**:
    * 主列表页通过卡片展示每个习惯，卡片内含微型热力图，显示近期的打卡情况。
    * 习惯详情页提供 GitHub 风格的年度热力图，以及月历视图，方便用户查看和操作特定日期的打卡记录。
* **数据统计**:
    * 详情页展示总打卡天数、最长连续打卡、当前连续打卡等统计信息。
    * 热力图和月历视图直观反映打卡频率和完成度。
* **用户界面与体验**:
    * 支持浅色模式 (Light Mode) 和深色模式 (Dark Mode)，并可跟随系统设置。
    * 提供多种预设颜色主题，用户可为不同习惯选择不同主题。
    * 界面设计注重简约和易用性，操作直观。
    * 支持包括中文、英文、日文、俄文、西班牙文、德文、法文在内的多语言界面。
* **数据管理**:
    * 用户数据存储在本地设备。
    * 支持将所有习惯和打卡记录导出为 CSV 文件进行备份。
    * 支持从 CSV 文件导入习惯和打卡记录，方便恢复数据或迁移。

## 技术实现

* **UI 框架**: SwiftUI。
* **状态管理**: `@EnvironmentObject` 和 `@StateObject` 用于管理应用核心数据 `HabitStore`。
* **数据持久化**:
    * 习惯数据和打卡记录通过 `Codable` 协议序列化后存储于 `UserDefaults`（通过 App Group 实现主应用与 Widget 共享）。
    * 用户设置（如主题模式、语言）也通过 `UserDefaults` (`@AppStorage`) 保存。
* **WidgetKit**: 用于实现 iOS桌面小组件功能，包含数据显示和交互。
* **AppIntents**: 用于处理 Widget 上的交互操作，如打卡。
* **本地化**: 通过自定义的 `LanguageManager` 和结构化的翻译文件实现多语言支持。

## 如何配置和运行

1.  **App Group 设置**:
    * 为了使主应用和 Widget 能够共享数据（通过 `UserDefaults`），需要在 Xcode 中为应用的 Target 和 Widget Extension Target 配置相同的 App Group。
    * 详细步骤请参照项目中的 `AppGroup_Setup.md` 文件。
    * App Group ID 为 `group.com.xi.HabitTracker.minimal-habit-tracker`。
2.  **构建与运行**:
    * 在 Xcode 中打开项目。
    * 确保已正确配置签名和 App Group。
    * 选择主应用 Target (`minimal habit tracker`) 或 Widget Extension Target (`mid-widgetExtension`)。
    * 选择一个模拟器或连接的物理设备。
    * 点击 "Build and Run" (播放按钮)。

## 目录结构简介

* `minimal habit tracker/`: 主应用程序代码。
    * `Models/`: 包含核心数据模型，如 `Habit.swift`, `HabitLog.swift`, `HabitStore.swift`, `ColorTheme.swift`。
    * `Views/`: 包含构成应用界面的 SwiftUI 视图，如 `ContentView.swift`, `HabitDetailView.swift`, `NewHabitView.swift`, `SettingsView.swift` 等。
    * `Languages/`: 包含多语言支持的相关文件，如 `LanguageManager.swift` 和各语言的翻译结构体。
    * `Assets.xcassets/`: 主应用的资源文件，如图标、图片。
* `mid-widget/`: Widget 扩展代码。
    * `mid_widget.swift`: Widget 的主要逻辑，包括 `Provider`, `Entry`, 视图 (`HabitWidgetEntryView`) 和打卡意图 (`CheckInHabitIntent`)。
    * `mid_widgetBundle.swift`: Widget Bundle 定义。
    * `Assets.xcassets/`: Widget 的资源文件。
* `AppGroup_Setup.md`: App Group 配置指南。
* `emojis.md`: 项目中可能用到的 Emoji 列表参考。
* `prd.md`: iCloud 同步功能的产品需求文档 (规划中)。
* `spec.md`: iCloud 同步功能的技术规格文档 (规划中)。

## todos
- [ ] invite buddy
- [ ] Pro 版本
- [ ] 数据云同步
- [ ] 热力图自动滚动到当前日期为最后一列
- [ ] 设置每天的提醒时间，提醒用户打卡
- [ ] 最长连续的计算优化（最多往前算 365 天可跨年）
- [ ] audio 
- [ ] 同步到 notion
- [ ] note 功能


## 贡献

如果您对改进此项目有任何建议或发现了 bug，欢迎通过提交 Issue 或 Pull Request 的方式参与贡献。

---

**开发者**: 图蜥



