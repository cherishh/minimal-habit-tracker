import Foundation

struct Habit: Identifiable, Codable {
    var id = UUID()
    var name: String
    var emoji: String
    var colorTheme: ColorThemeName
    var habitType: HabitType
    var createdAt = Date()
    
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