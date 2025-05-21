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
    
    // 获取本地化的主题名称
    func localizedName() -> String {
        // 获取当前语言设置
        let language = HabitStore.shared.appLanguage
        
        // 手动定义翻译映射，避免引用其他文件中的类
        let translations: [String: [String: String]] = [
            "en": [
                "🤖 默认": "🤖 Default",
                "🌊 蓝色海洋": "🌊 Blue Ocean",
                "🌅 日落": "🌅 Sunset",
                "🟪 紫雨": "🟪 Purple Rain",
                "🏜 黄金国": "🏜 Golden Land",
                "🌿 芳草地": "🌿 Meadow",
                "🩵 清晨湖水": "🩵 Morning Lake",
                "🌹 玫瑰": "🌹 Rose",
                "🪨 青岩": "🪨 Cyan Rock",
                "🩶 黑白森 林": "🩶 Monochrome Forest",
                "🍬 糖果": "🍬 Candy"
            ],
            "ja": [
                "🤖 默认": "🤖 デフォルト",
                "🌊 蓝色海洋": "🌊 ブルーオーシャン",
                "🌅 日落": "🌅 サンセット",
                "🟪 紫雨": "🟪 パープルレイン",
                "🏜 黄金国": "🏜 ゴールデンランド",
                "🌿 芳草地": "🌿 メドウ", 
                "🩵 清晨湖水": "🩵 モーニングレイク",
                "🌹 玫瑰": "🌹 ローズ",
                "🪨 青岩": "🪨 シアンロック",
                "🩶 黑白森林": "🩶 モノクローム",
                "🍬 糖果": "🍬 キャンディ"
            ],
            "ru": [
                "🤖 默认": "🤖 По умолчанию",
                "🌊 蓝色海洋": "🌊 Синий океан",
                "🌅 日落": "🌅 Закат",
                "🟪 紫雨": "🟪 Фиолетовый дождь",
                "🏜 黄金国": "🏜 Золотая земля",
                "🌿 芳草地": "🌿 Луг", 
                "🩵 清晨湖水": "🩵 Утреннее озеро",
                "🌹 玫瑰": "🌹 Роза",
                "🪨 青岩": "🪨 Голубая скала",
                "🩶 黑白森林": "🩶 Монохромный лес",
                "🍬 糖果": "🍬 Конфеты"
            ],
            "de": [
                "🤖 默认": "🤖 Standard",
                "🌊 蓝色海洋": "🌊 Blauer Ozean",
                "🌅 日落": "🌅 Sonnenuntergang",
                "🟪 紫雨": "🟪 Violetter Regen",
                "🏜 黄金国": "🏜 Goldenes Land",
                "🌿 芳草地": "🌿 Wiese", 
                "🩵 清晨湖水": "🩵 Morgensee",
                "🌹 玫瑰": "🌹 Rose",
                "🪨 青岩": "🪨 Türkisfelsen",
                "🩶 黑白森林": "🩶 Monochrome Wald",
                "🍬 糖果": "🍬 Süßigkeiten"
            ],
            "fr": [
                "🤖 默认": "🤖 Par défaut",
                "🌊 蓝色海洋": "🌊 Océan bleu",
                "🌅 日落": "🌅 Coucher de soleil",
                "🟪 紫雨": "🟪 Pluie violette",
                "🏜 黄金国": "🏜 Pays doré",
                "🌿 芳草地": "🌿 Prairie", 
                "🩵 清晨湖水": "🩵 Lac du matin",
                "🌹 玫瑰": "🌹 Rose",
                "🪨 青岩": "🪨 Roche turquoise",
                "🩶 黑白森林": "🩶 Forêt monochrome",
                "🍬 糖果": "🍬 Bonbon"
            ],
            "es": [
                "🤖 默认": "🤖 Predeterminado",
                "🌊 蓝色海洋": "🌊 Océano azul",
                "🌅 日落": "🌅 Puesta de sol",
                "🟪 紫雨": "🟪 Lluvia púrpura",
                "🏜 黄金国": "🏜 Tierra dorada",
                "🌿 芳草地": "🌿 Pradera", 
                "🩵 清晨湖水": "🩵 Lago de la mañana",
                "🌹 玫瑰": "🌹 Rosa",
                "🪨 青岩": "🪨 Roca turquesa",
                "🩶 黑白森林": "🩶 Bosque monocromático",
                "🍬 糖果": "🍬 Caramelo"
            ]
        ]
        
        // 如果是空字符串（系统默认），则根据系统语言选择
        if language.isEmpty {
            let systemLanguage = Locale.preferredLanguages.first ?? "en"
            if systemLanguage.hasPrefix("zh") {
                // 如果系统是中文，返回原始中文字符串
                return name
            } else if systemLanguage.hasPrefix("ja") {
                // 如果系统是日语，使用日语翻译
                return translations["ja"]?[name] ?? name
            } else if systemLanguage.hasPrefix("ru") {
                // 如果系统是俄语，使用俄语翻译
                return translations["ru"]?[name] ?? name
            } else if systemLanguage.hasPrefix("es") {
                // 如果系统是西班牙语，使用西班牙语翻译
                return translations["es"]?[name] ?? name
            } else if systemLanguage.hasPrefix("de") {
                // 如果系统是德语，使用德语翻译
                return translations["de"]?[name] ?? name
            } else if systemLanguage.hasPrefix("fr") {
                // 如果系统是法语，使用法语翻译
                return translations["fr"]?[name] ?? name
            } else {
                // 默认使用英文
                return translations["en"]?[name] ?? name
            }
        }
        
        if language == "en" {
            // 如果是英文，查找翻译
            return translations["en"]?[name] ?? name
        } else if language == "zh-Hans" {
            // 如果是中文，返回原始中文字符串
            return name
        } else if language == "ja" {
            // 如果是日语，查找翻译
            return translations["ja"]?[name] ?? name
        } else if language == "ru" {
            // 如果是俄语，查找翻译
            return translations["ru"]?[name] ?? name
        } else if language == "es" {
            // 如果是西班牙语，查找翻译
            return translations["es"]?[name] ?? name
        } else if language == "de" {
            // 如果是德语，查找翻译
            return translations["de"]?[name] ?? name
        } else if language == "fr" {
            // 如果是法语，查找翻译
            return translations["fr"]?[name] ?? name
        }
        
        // 如果没有找到匹配的翻译，就返回原字符串
        return name
    }
    
    // 根据用户自定义打卡次数获取颜色
    func colorForCount(count: Int, maxCount: Int, isDarkMode: Bool) -> Color {
        // 如果未打卡，返回基础颜色
        if count == 0 {
            return isDarkMode ? darkColors[0] : lightColors[0]
        }
        
        // 如果打卡次数超过了最大值，使用最深的颜色
        if count >= maxCount {
            return isDarkMode ? darkColors[5] : lightColors[5]
        }
        
        // 根据打卡次数上限的不同策略处理
        if maxCount <= 5 {
            // 当打卡次数上限小于等于5时，颜色从较深的一端开始倒序选择
            // 计算对应的颜色索引：索引 = 6 - maxCount + (count - 1)
            let colorIndex = 6 - maxCount + (count - 1)
            return isDarkMode ? darkColors[colorIndex] : lightColors[colorIndex]
        } else {
            // 当打卡次数上限大于5时，颜色会重复使用
            if count <= (maxCount - 5) * 2 {
                // 前maxCount-5种颜色每种用两次
                let repeatedColorIndex = (count + 1) / 2
                return isDarkMode ? darkColors[repeatedColorIndex] : lightColors[repeatedColorIndex]
            } else {
                // 剩余次数使用剩下的颜色
                let remaining = count - (maxCount - 5) * 2
                let colorIndex = (maxCount - 5) + remaining
                return isDarkMode ? darkColors[colorIndex] : lightColors[colorIndex]
            }
        }
    }
}

extension ColorTheme {
    static let themes: [ColorTheme] = [
        ColorTheme(
            id: .github,
            name: "🤖 默认",
            lightColors: [
                Color(hex: "ebedf0"), // github
                Color(hex: "bbf7d0"), // bg-green-200
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
            name: "🌊 蓝色海洋",
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
            name: "🌅 日落",
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
        
        // 高级主题
        // ColorTheme(
        //     id: .starNight,
        //     name: "🌌 星空",
        //     lightColors: [
        //         Color(hex: "f1f5f9"), // custom light
        //         Color(hex: "a3a3a3"), // lighter
        //         Color(hex: "8386B5"), // light
        //         Color(hex: "4A4B8F"), // medium
        //         Color(hex: "2D3168"), // dark
        //         Color(hex: "1A1B41")  // darkest
        //     ],
        //     darkColors: [
        //         Color(hex: "1A1B41"), // darkest
        //         Color(hex: "2D3168"), // dark
        //         Color(hex: "4A4B8F"), // medium
        //         Color(hex: "8386B5"), // light
        //         Color(hex: "A8AADB"), // lighter
        //         Color(hex: "a3a3a3")  // custom light
        //     ]
        // ),
        ColorTheme(
            id: .purpleRain,
            name: "🟪 紫雨",
            lightColors: [
                Color(hex: "f1f5f9"), // custom
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
        ),
        ColorTheme(
            id: .desert,
            name: "🏜 黄金国",
            lightColors: [
                Color(hex: "f5f5dc"), // lightest
                Color(hex: "fef08a"), // lighter
                Color(hex: "facc15"), // medium
                Color(hex: "ca8a04"), // dark
                Color(hex: "854d0e"), // darker
                Color(hex: "422006")  // darkest
            ],
            darkColors: [
                Color(hex: "261a0f"), // darkest
                Color(hex: "854d0e"), // darker
                Color(hex: "ca8a04"), // dark
                Color(hex: "facc15"), // medium
                Color(hex: "fef08a"), // lighter
                Color(hex: "fffbeb")  // lightest
            ]
        ),
        ColorTheme(
            id: .forestGreen,
            name: "🌿 芳草地",
            lightColors: [
                Color(hex: "E8F5E9"), // lightest
                Color(hex: "C8E6C9"), // lighter
                Color(hex: "A5D6A7"), // light
                Color(hex: "81C784"), // medium
                Color(hex: "66BB6A"), // dark
                Color(hex: "2E7D32")  // darkest
            ],
            darkColors: [
                Color(hex: "161b22"), // 
                Color(hex: "2E5E33"), // dark
                Color(hex: "438A4B"), // medium
                Color(hex: "58B563"), // light
                Color(hex: "70DE7A"), // lighter
                Color(hex: "A5F0A9")  // lightest
            ]
        ),
        ColorTheme(
            id: .morningLake,
            name: "🩵 清晨湖水",
            lightColors: [
                Color(hex: "e0f7fa"), // lightest
                Color(hex: "67e8f9"), // lighter
                Color(hex: "06b6d4"), // medium
                Color(hex: "0e7490"), // dark
                Color(hex: "164e63"), // darker
                Color(hex: "031e29")  // darkest
            ],
            darkColors: [
                Color(hex: "051e26"), // darkest
                Color(hex: "164e63"), // darker
                Color(hex: "0e7490"), // dark
                Color(hex: "06b6d4"), // medium
                Color(hex: "67e8f9"), // lighter
                Color(hex: "cffafe")  // lightest
            ]
        ),
        ColorTheme(
            id: .rose,
            name: "🌹 玫瑰",
            lightColors: [
                Color(hex: "fff0f3"), // lightest
                Color(hex: "fda4af"), // lighter
                Color(hex: "f43f5e"), // medium
                Color(hex: "be123c"), // dark
                Color(hex: "881337"), // darker
                Color(hex: "4c0519")  // darkest
            ],
            darkColors: [
                Color(hex: "26020B"), // darkest (corresponds to light's lightest)
                Color(hex: "590A16"), // darker (corresponds to light's lighter)
                Color(hex: "A11D3A"), // dark (corresponds to light's medium)
                Color(hex: "D33A5E"), // medium (corresponds to light's dark)
                Color(hex: "F2728D"), // light (corresponds to light's darker)
                Color(hex: "FFB4C2")  // lightest (corresponds to light's darkest)
            ]
        ),
        ColorTheme(
            id: .cyanRock,
            name: "🪨 青岩",
            lightColors: [
                Color(hex: "e0e0e0"), // lightest (底色 - 浅灰色，略带蓝)
                Color(hex: "b4c4d4"), // lighter (比底色略深)
                Color(hex: "90a0b0"), // medium (中等灰蓝色)
                Color(hex: "607080"), // dark (较深的灰蓝色)
                Color(hex: "405060"), // darker (更深的灰蓝色)
                Color(hex: "203040")  // darkest (非常深的灰蓝色)
            ],
            darkColors: [
                Color(hex: "0a1119"), // darkest (corresponds to light's lightest)
                Color(hex: "1E293B"), // darker (corresponds to light's lighter)
                Color(hex: "475569"), // dark (corresponds to light's medium)
                Color(hex: "94A3B8"), // medium (corresponds to light's dark)
                Color(hex: "C8E6FA"), // light (corresponds to light's darker - adjusted)
                Color(hex: "F0F9FF")  // lightest (corresponds to light's darkest - adjusted)
            ]
        ),
        ColorTheme(
            id: .naturalGray,
            name: "🩶 黑白森林",
            lightColors: [
                Color(hex: "fafafa"), // lightest
                Color(hex: "e5e5e5"), // lighter
                Color(hex: "a3a3a3"), // medium
                Color(hex: "525252"), // dark
                Color(hex: "27272a"), // darker
                Color(hex: "0a0a0a")  // darkest
            ],
            darkColors: [
                Color(hex: "0f0f0f"), // darkest
                Color(hex: "27272a"), // darker
                Color(hex: "525252"), // dark
                Color(hex: "a3a3a3"), // medium
                Color(hex: "e5e5e5"), // lighter
                Color(hex: "fafafa")  // lightest
            ]
        ),
        ColorTheme(
            id: .candy,
            name: "🍬 糖果",
            lightColors: [
                Color(hex: "F2F2F2"), // lightest (gray)
                Color(hex: "FF9AA2"), // lighter (pink)
                Color(hex: "FFDAC1"), // light (peach)
                Color(hex: "E2F0CB"), // medium (lime)
                Color(hex: "B5EAD7"), // dark (mint)
                Color(hex: "C7CEEA")  // darkest (lavender)
            ],
            darkColors: [
                Color(hex: "1E1E1E"), // darkest (深灰色背景)
                Color(hex: "FFB3C1"), // lighter (更柔和的粉色)
                Color(hex: "FFE0B2"), // light (更柔和的蜜桃色)
                Color(hex: "D1F0C7"), // medium (更柔和的浅绿)
                Color(hex: "A7E8D2"), // dark (更柔和的薄荷绿)
                Color(hex: "D1D9EE")  // lightest (更柔和的浅紫)
            ]
        ),
        // ColorTheme(
        //     id: .rainbow,
        //     name: "🌈 彩虹",
        //     lightColors: [
        //         Color(hex: "D3D3D3"), // lightest (中等浅灰色背景，更容易看清)
        //         Color(hex: "E53935"), // lighter (现代感的红色)
        //         Color(hex: "FB8C00"), // light (现代感的橙色)
        //         Color(hex: "FDD835"), // medium (现代感的黄色)
        //         Color(hex: "43A047"), // dark (现代感的绿色)
        //         Color(hex: "5E35B1")  // darkest (现代感的紫色)
        //     ],
        //     darkColors: [
        //         Color(hex: "121212"), // darkest (深灰色背景)
        //         Color(hex: "F06292"), // darker (霓虹粉色)
        //         Color(hex: "FFB300"), // dark (霓虹橙色)
        //         Color(hex: "FFEE58"), // medium (更柔和的霓虹黄色)
        //         Color(hex: "69F0AE"), // light (霓虹青绿色)
        //         Color(hex: "64B5F6")  // lighter (霓虹浅蓝色)
        //     ]
        // )
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
