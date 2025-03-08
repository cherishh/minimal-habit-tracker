import Foundation

struct HabitLog: Identifiable, Codable {
    var id = UUID()
    var habitId: UUID
    var date: Date
    var count: Int
    
    // 根据次数返回颜色级别(0-4)
    var level: Int {
        min(count, 4)
    }
} 