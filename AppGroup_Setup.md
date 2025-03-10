# 配置 App Group 以共享数据

为了让主应用和 Widget 之间能够共享数据，您需要在 Xcode 中配置 App Group。这是一项重要的设置，没有它 Widget 将无法访问主应用的数据。请按照以下步骤操作：

## 步骤 1: 添加 App Group 能力

1. 在 Xcode 中打开项目
2. 选择项目文件 > 选择主应用的 Target
3. 切换到 "Signing & Capabilities" 标签页
4. 点击 "+ Capability" 按钮
5. 搜索并添加 "App Groups" 能力

## 步骤 2: 创建 App Group

1. 在刚才添加的 App Groups 部分，点击 "+" 按钮
2. 输入 App Group 标识符: `group.com.xi.HabitTracker.minimal-habit-tracker`
   （注意: 根据您的应用 Bundle ID 可能需要调整此标识符）
3. 点击 "OK" 确认

## 步骤 3: 为 Widget 扩展添加相同的 App Group

1. 在项目导航器中，选择 Widget 扩展的 Target (`mid-widgetExtension`)
2. 同样切换到 "Signing & Capabilities" 标签页
3. 添加 "App Groups" 能力
4. 勾选与主应用相同的 App Group: `group.com.xi.HabitTracker.minimal-habit-tracker`

## 步骤 4: 重新构建和测试

1. 清理项目 (Xcode 菜单 > Product > Clean Build Folder)
2. 重新构建整个项目
3. 部署到设备或模拟器测试 Widget 是否能正确显示主应用的数据

## 注意事项

- App Group 标识符必须在两个 Target 之间保持完全一致
- 确保 Apple Developer 账户有创建 App Group 的权限
- 如果测试时没有看到数据同步，请尝试重启设备/模拟器
- 每次修改 App Group 配置后，都需要重新部署应用

## 调试技巧

如果 Widget 无法显示主应用数据，可能的原因包括:

1. App Group 配置不正确
2. 主应用还没有保存任何数据
3. Widget 和主应用使用了不同的数据键名

您可以检查 Xcode 控制台输出中的诊断信息，Widget 代码已添加日志来显示它是否成功加载了数据。 