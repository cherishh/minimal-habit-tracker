import SwiftUI

struct ColorTheme: Identifiable {
    var id: Habit.ColorThemeName
    var name: String
    var lightColors: [Color]
    var darkColors: [Color]
    
    // 获取特定强度级别的颜色
    func color(for level: Int, isDarkMode: Bool) -> Color {
        guard level >= 0 && level < 5 else { return isDarkMode ? darkColors[0] : lightColors[0] }
        return isDarkMode ? darkColors[level] : lightColors[level]
    }
}

extension ColorTheme {
    static let themes: [ColorTheme] = [
        ColorTheme(
            id: .github,
            name: "GitHub",
            lightColors: [Color(hex: "ebedf0"), Color(hex: "9be9a8"), Color(hex: "40c463"), Color(hex: "30a14e"), Color(hex: "216e39")],
            darkColors: [Color(hex: "2d333b"), Color(hex: "0e4429"), Color(hex: "006d32"), Color(hex: "26a641"), Color(hex: "39d353")]
        ),
        ColorTheme(
            id: .blueOcean,
            name: "Blue Ocean",
            lightColors: [Color(hex: "f1f5f9"), Color(hex: "bfdbfe"), Color(hex: "60a5fa"), Color(hex: "3b82f6"), Color(hex: "1d4ed8")],
            darkColors: [Color(hex: "1e293b"), Color(hex: "172554"), Color(hex: "1e40af"), Color(hex: "2563eb"), Color(hex: "3b82f6")]
        ),
        ColorTheme(
            id: .sunset,
            name: "Sunset",
            lightColors: [Color(hex: "f5f5f4"), Color(hex: "fed7aa"), Color(hex: "fb923c"), Color(hex: "f97316"), Color(hex: "c2410c")],
            darkColors: [Color(hex: "292524"), Color(hex: "431407"), Color(hex: "7c2d12"), Color(hex: "ea580c"), Color(hex: "f97316")]
        ),
        ColorTheme(
            id: .purpleRain,
            name: "Purple Rain",
            lightColors: [Color(hex: "f5f3ff"), Color(hex: "ddd6fe"), Color(hex: "a78bfa"), Color(hex: "8b5cf6"), Color(hex: "6d28d9")],
            darkColors: [Color(hex: "2e1065"), Color(hex: "4c1d95"), Color(hex: "6d28d9"), Color(hex: "8b5cf6"), Color(hex: "a78bfa")]
        )
    ]
    
    static func getTheme(for name: Habit.ColorThemeName) -> ColorTheme {
        themes.first { $0.id == name } ?? themes[0]
    }
}

// 用于颜色十六进制值转换
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 