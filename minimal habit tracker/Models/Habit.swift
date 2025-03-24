import Foundation

struct Habit: Identifiable, Codable {
    var id = UUID()
    var name: String
    var emoji: String
    var colorTheme: ColorThemeName
    var habitType: HabitType
    var createdAt = Date()
    var backgroundColor: String? // 可选的背景色，十六进制格式
    var maxCheckInCount: Int = 5 // 用户自定义的打卡次数上限，默认为5次
    
    enum ColorThemeName: String, CaseIterable, Codable {
        case github = "GitHub"
        case blueOcean = "Blue Ocean"
        case sunset = "Sunset"
        
        // 高级主题
        // case starNight = "Star Night"
        case purpleRain = "Purple Rain"
        case desert = "Desert"
        case forestGreen = "Forest Green"
        case morningLake = "Morning Lake"
        case rose = "Rose"
        case cyanRock = "Cyan Rock"
        case naturalGray = "Natural Gray"
        case candy = "Candy"
        // case rainbow = "Rainbow"
    }
    
    enum HabitType: String, Codable {
        case checkbox = "Checkbox"
        case count = "Count"
    }
} 