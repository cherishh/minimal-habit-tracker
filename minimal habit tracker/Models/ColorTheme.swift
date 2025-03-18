import SwiftUI

struct ColorTheme: Identifiable {
    var id: Habit.ColorThemeName
    var name: String
    var lightColors: [Color]
    var darkColors: [Color]
    
    // 获取特定强度级别的颜色
    func color(for level: Int, isDarkMode: Bool) -> Color {
        guard level >= 0 && level < HabitStore.maxCheckInCount+1 else { return isDarkMode ? darkColors[0] : lightColors[0] }
        return isDarkMode ? darkColors[level] : lightColors[level]
    }
}

extension ColorTheme {
    static let themes: [ColorTheme] = [
        ColorTheme(
            id: .github,
            name: "GitHub",
            lightColors: [
                Color(hex: "ebedf0"), // github
                Color(hex: "dcfce7"), // bg-green-100
                Color(hex: "9be9a8"), // github
                Color(hex: "40c463"), // github
                Color(hex: "30a14e"), // github
                Color(hex: "216e39")  // github
            ],
            darkColors: [
                Color(hex: "161b22"), // github
                Color(hex: "052e16"), // bg-green-950
                Color(hex: "0e4429"), // github
                Color(hex: "006d32"), // github
                Color(hex: "26a641"), // github
                Color(hex: "39d353")  // github
            ]
        ),
        ColorTheme(
            id: .blueOcean,
            name: "Blue Ocean",
            lightColors: [
                Color(hex: "f3f4f6"), // bg-gray-100
                Color(hex: "dbeafe"), // bg-blue-100
                Color(hex: "bfdbfe"), // bg-blue-200
                Color(hex: "93c5fd"), // bg-blue-300
                Color(hex: "3b82f6"), // bg-blue-500
                Color(hex: "1d4ed8")  // bg-blue-700
            ],
            darkColors: [
                Color(hex: "1e293b"), // custom
                Color(hex: "1e3a8a"), // bg-blue-900
                Color(hex: "1e40af"), // bg-blue-800
                Color(hex: "1d4ed8"), // bg-blue-700
                Color(hex: "2563eb"), // bg-blue-600
                Color(hex: "3b82f6")  // bg-blue-500
            ]
        ),
        ColorTheme(
            id: .sunset,
            name: "Sunset",
            lightColors: [
                Color(hex: "f5f5f4"), // custom
                Color(hex: "ffedd5"), // bg-orange-100
                Color(hex: "fed7aa"), // bg-orange-200
                Color(hex: "fdba74"), // bg-orange-300
                Color(hex: "f97316"), // bg-orange-500
                Color(hex: "c2410c")  // bg-orange-700
            ],
            darkColors: [
                Color(hex: "292524"), // custom
                Color(hex: "7c2d12"), // bg-orange-900
                Color(hex: "9a3412"), // bg-orange-800
                Color(hex: "c2410c"), // bg-orange-700
                Color(hex: "ea580c"), // bg-orange-600
                Color(hex: "f97316")  // bg-orange-500
            ]
        ),
        ColorTheme(
            id: .purpleRain,
            name: "Purple Rain",
            lightColors: [
                Color(hex: "e9e7f3"), // custom
                Color(hex: "f3e8ff"), // bg-purple-100
                Color(hex: "e9d5ff"), // bg-purple-200
                Color(hex: "d8b4fe"), // bg-purple-300
                Color(hex: "a855f7"), // bg-purple-500
                Color(hex: "7e22ce")  // bg-purple-700
            ],
            darkColors: [
                Color(hex: "2e1065"), // custom
                Color(hex: "581c87"), // bg-purple-900
                Color(hex: "6b21a8"), // bg-purple-800
                Color(hex: "7e22ce"), // bg-purple-700
                Color(hex: "9333ea"), // bg-purple-600
                Color(hex: "a855f7")  // bg-purple-500
            ]
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