.onAppear {
            // 添加对习惯删除通知的监听
            NotificationCenter.default.addObserver(forName: NSNotification.Name("HabitDeleted"), object: nil, queue: .main) { notification in
                if let deletedHabitId = notification.object as? UUID, deletedHabitId == habitId {
                    // 如果删除的是当前正在查看的习惯，返回到列表页
                    dismissAction()
                }
            }
        }
.onDisappear {
    // 移除通知监听
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name("HabitDeleted"), object: nil)
}