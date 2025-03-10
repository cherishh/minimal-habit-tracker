# 设置 URL Scheme 以支持 Widget 交互

为了让 Widget 能够直接与应用交互，需要在 Xcode 项目中添加自定义 URL Scheme。请按照以下步骤操作：

1. 在 Xcode 中打开项目
2. 选择主应用的 target（minimal habit tracker）
3. 切换到 "Info" 标签页
4. 展开 "URL Types" 部分（如果没有，点击 "+" 按钮添加）
5. 添加一个新的 URL Type，设置以下内容：
   - Identifier: `com.xi.HabitTracker.minimal-habit-tracker`
   - URL Schemes: `easyhabit`
   - Role: `Editor`

完成这些设置后，系统将能够识别 `easyhabit://` 开头的 URL，并将其打开到我们的应用中。这样，当用户点击 Widget 上的打卡按钮时，应用将能够接收到请求并执行相应的操作。

## 测试 URL Scheme

设置完成后，可以通过以下方式测试 URL Scheme 是否正常工作：

1. 在 Safari 中输入 `easyhabit://widget/checkin?habitId=<习惯ID>`（将 `<习惯ID>` 替换为实际的习惯 ID）
2. 如果设置正确，系统应该会打开应用并执行打卡操作

## 注意事项

- 确保 URL Scheme 在系统中是唯一的，避免与其他应用冲突
- 在应用中正确处理 URL 参数，确保安全性和稳定性
- 如果应用已经安装在设备上，可能需要重新安装才能使新的 URL Scheme 生效 