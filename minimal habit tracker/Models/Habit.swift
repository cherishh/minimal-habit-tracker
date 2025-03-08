import Foundation

struct Habit: Identifiable, Codable {
    var id = UUID()
    var name: String
    var colorTheme: ColorThemeName
    var createdAt = Date()
    
    enum ColorThemeName: String, CaseIterable, Codable {
        case github = "GitHub"
        case blueOcean = "Blue Ocean"
        case sunset = "Sunset"
        case purpleRain = "Purple Rain"
    }
} 