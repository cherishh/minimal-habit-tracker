# 设置 Widget 预览环境变量

在尝试预览 Widget 时，您可能会遇到以下错误：

> Please specify the widget kind in the scheme's Environment Variables using the key '_XCWidgetKind' to be one of: 'HabitWidget', 'SmartStackHabitWidget'

这是因为 Xcode 需要知道要预览哪一个特定的 Widget 类型。请按照以下步骤设置：

## 步骤 1: 编辑 Scheme 设置

1. 在 Xcode 顶部菜单中，点击您的 Widget 扩展名称（比如 `mid-widgetExtension`）旁边的 scheme 选择器
2. 选择 "Edit Scheme..."

## 步骤 2: 添加环境变量

1. 在弹出的窗口中，选择左侧的 "Run" 选项
2. 切换到 "Arguments" 标签页
3. 在 "Environment Variables" 部分，点击 "+" 按钮添加新变量：
   - 名称: `_XCWidgetKind`
   - 值: `HabitWidget` （或者 `SmartStackHabitWidget`，取决于您想预览哪个）

## 步骤 3: 运行 Widget 预览

1. 点击 "Close" 保存设置
2. 选择模拟器（如 iPhone 15）
3. 点击运行按钮（或按 Cmd+R）

## 切换预览不同的 Widget

如果您想预览不同的 Widget，只需回到 Scheme 设置，修改 `_XCWidgetKind` 的值即可：

- `HabitWidget` - 预览标准习惯 Widget
- `SmartStackHabitWidget` - 预览支持 Smart Stack 样式的习惯 Widget

## 注意事项

- 每次更改环境变量后，您需要重新运行应用
- 如果您同时进行了 App Group 设置，请确保正确配置了共享数据访问权限
- 预览中可能看不到实际数据，直到您在主应用中添加了一些习惯并进行了打卡 