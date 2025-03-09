import Foundation

struct Habit: Identifiable, Codable {
    var id = UUID()
    var name: String
    var emoji: String
    var colorTheme: ColorThemeName
    var habitType: HabitType
    var createdAt = Date()
    var backgroundColor: String? // 可选的背景色，十六进制格式
    
    enum ColorThemeName: String, CaseIterable, Codable {
        case github = "GitHub"
        case blueOcean = "Blue Ocean"
        case sunset = "Sunset"
        case purpleRain = "Purple Rain"
    }
    
    enum HabitType: String, Codable {
        case checkbox = "Checkbox"
        case count = "Count"
    }
} 