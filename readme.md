# minimal habit tracker
以 github contributions heatmap 的形式为用户提供习惯追踪。

## 功能描述
1. 应用有 2 个主要页面组成，分别是 list view 和 detail view。
2. 在 list view 中，用户可以通过简易卡片查看已经添加的 habit。卡片中包含 habit 的名称、emoji、最近 10 天的微型热力图、打卡按钮。点击卡片进入 detail view。用户也可以点击新建 icon 来新建 habit、左滑删除 habit、以及进入设置页面。
3. 创建 habit。habit 有两种类型，checkbox 和 count。确定类型后不可修改。用户选择类型后进入下一步，在下一步的创建中，用户选择 emoji、输入名称、选择颜色主题。checkbox 类型下，用户点击一次热力图对应的格子/打卡按钮即完成记录，默认使用用户选择的颜色主题中颜色最深的那个填充热力图；count 类型下，用户每点击一次，热力图颜色加深一点，最多有 4 档。创建成功后进入 detail view 界面。
4. detail view 中，大致分为上下两部分。上半部分为 heatmap。heatmap 上每一个 block 代表一个日期。用户可以点击 block，从而 log 这一天的习惯已经打卡完成。用户可以多次点击同一个 block，每点击一次，该 block 的颜色加深一点，总共有 4 档。对于 checkbox 类型，在已经 log 的格子上再次点击则取消这天的 log；对于 count 类型，点击第 5 次时也清空 log。下半部分为普通日历，显示当月日期，用户也可以点击日历上的日期从而 log 这一天的习惯已经打卡完成。点击某日期后，该日期画圈。已经打卡的日期同样显示为已画圈。此外用户可随时点击齿轮按钮修改 habit 的名称、emoji、颜色主题。
5. 用户可以切换light/dark mode；
    5.1. dark mode下有诸多细节优化。如 primary 在多数时候使用 opacity 0.8 降低对比度；列表页进度指示器/日历进度指示器填充色采用颜色等级 4 而不是 5。迷你热力图整体添加 0.8 透明度，使热力图不那么刺眼。widget 纯黑背景，等。
    5.2. 还可以进一步优化。有些地方文字依然是纯白刺眼；迷你热力图格子默认颜色可以统一成 gray。
6. 


## Next Step
允许用户导入导出数据。导出数据格式为 csv，内容为 habit 的名称、类型、颜色主题、emoji、日期、打卡次数。


## todos
- [ ] 支持数据导入导出
- [ ] 用户可以在桌面添加该 app 的 widget。这个 widget 显示当前 habit 的 heatmap。如果用户点击 widget，直接默认在当前 habit 上 log+1。【不需要】进入 app。
- [ ] 设置页扩展
    - [ ] light dark 切换
    - [ ] 热力图颜色自定义
    - [ ] coming soon
        - [ ] 自定义 color theme
        - [ ] 数据云同步
        - [ ] 无限 habits 数量
        - [ ] note 功能

- [ ] invite buddy
- [ ] 热力图自动滚动到当前日期为最后一列
- [ ] 设置每天的提醒时间，提醒用户打卡
- [ ] 最长连续的计算优化（最多往前算 365 天可跨年）
- [ ] audio 
- [ ] 同步到 notion
