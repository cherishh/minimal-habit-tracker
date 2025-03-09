# minimal habit tracker

以 github contributions heatmap 的形式为用户提供习惯追踪。

## 功能
1. 允许用户创建 habit。一旦创建 habit，则进入 heatmap 界面；
2. heatmap 上每一个 block 代表一个日期。用户可以点击 block，从而 log 这一天的习惯已经打卡完成。用户可以多次点击同一个 block，每点击一次，该 block 的颜色加深一点，总共有 4 档。也就是说，点击超过 4 次则颜色不再变化；
3. 用户可以切换light/dark mode；
4. 用户可以选择在 heatmap 上使用不同的 color theme。
5. 用户可以在桌面添加该 app 的 widget。这个 widget 显示当前 habit 的 heatmap。如果用户点击 widget，直接默认在当前 habit 上 log+1。【不需要】进入 app。
6. 如果用户有多个 habit，则应该像ios 自带的 smart stack widget 一样，用户可以上下滑动切换不同的 habit。

## todos
- [ ] fix 超过 4 次点击变白；
- [ ] 取消某日记录；
