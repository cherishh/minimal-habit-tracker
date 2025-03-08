import Foundation
import SwiftUI

// 此类仅用于测试目的，帮助开发人员测试不同语言
class LanguageManager: ObservableObject {
    @Published var currentLanguage: String {
        didSet {
            // 保存用户选择的语言
            UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
            
            // 打印调试信息
            print("语言已更改为: \(currentLanguage)")
        }
    }
    
    static let shared = LanguageManager()
    
    private init() {
        // 获取系统当前语言或用户保存的语言设置
        if let savedLanguages = UserDefaults.standard.object(forKey: "AppleLanguages") as? [String],
           let firstLanguage = savedLanguages.first {
            self.currentLanguage = firstLanguage
        } else if let preferredLanguage = Locale.preferredLanguages.first {
            self.currentLanguage = preferredLanguage
        } else {
            self.currentLanguage = "en"
        }
    }
    
    // 检测当前是否为中文环境
    var isChinese: Bool {
        return currentLanguage.starts(with: "zh")
    }
    
    // 根据系统语言选择合适的语言
    var systemLanguage: String {
        let preferredLanguages = Locale.preferredLanguages
        for language in preferredLanguages {
            if language.starts(with: "zh") {
                return "zh-Hans"
            }
            if language.starts(with: "en") {
                return "en"
            }
        }
        return "en" // 默认为英语
    }
} 