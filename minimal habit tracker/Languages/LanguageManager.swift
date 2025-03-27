import Foundation
import SwiftUI

// 本地化字符串扩展，仅提供基于上下文的本地化
extension String {
    // 所有本地化必须指定上下文
    func localized(in context: LanguageManager.PageType) -> String {
        return LanguageManager.shared.localizedString(for: self, in: context)
    }
}

class LanguageManager {
    static let shared = LanguageManager()
    
    private init() {}
    
    // 带上下文的本地化字符串查找
    func localizedString(for key: String, in context: PageType) -> String {
        // 为键添加上下文前缀
        let contextKey = "\(context.prefix).\(key)"
        
        // 获取当前语言设置
        let language = HabitStore.shared.appLanguage
        
        // 如果是空字符串（系统默认），则根据系统语言选择
        if language.isEmpty {
            let systemLanguage = Locale.preferredLanguages.first ?? "en"
            if systemLanguage.hasPrefix("zh") {
                // 如果系统是中文，返回原始中文字符串
                return key
            } else if systemLanguage.hasPrefix("ja") {
                // 如果系统是日语，使用日语翻译
                return getJapaneseTranslation(for: context, key: contextKey) ?? key
            } else {
                // 默认使用英文
                return getEnglishTranslation(for: context, key: contextKey) ?? key
            }
        }
        
        if language == "en" {
            // 如果是英文，查找带前缀的翻译
            return getEnglishTranslation(for: context, key: contextKey) ?? key
        } else if language == "zh-Hans" {
            // 如果是中文，返回原始中文字符串
            return key
        } else if language == "ja" {
            // 如果是日语，查找带前缀的翻译
            return getJapaneseTranslation(for: context, key: contextKey) ?? key
        }
        
        // 如果没有找到匹配的翻译，就返回原字符串
        return key
    }
    
    // 根据上下文和键获取英文翻译
    private func getEnglishTranslation(for context: PageType, key: String) -> String? {
        switch context {
        case .settings:
            return English.settingsTranslations[key]
        case .createHabit:
            return English.createHabitTranslations[key]
        case .habitDetail:
            return English.habitDetailTranslations[key]
        case .proFeatures:
            return English.proFeaturesTranslations[key]
        case .importExport:
            return English.importExportTranslations[key]
        case .common:
            return English.commonTranslations[key]
        case .contentView:
            return English.contentViewTranslations[key]
        case .payment:
            return English.paymentViewTranslations[key]
        case .emojiPicker:
            return English.emojiPickerTranslations[key]
        }
    }
    
    // 根据上下文和键获取日语翻译
    private func getJapaneseTranslation(for context: PageType, key: String) -> String? {
        switch context {
        case .settings:
            return Japanese.settingsTranslations[key]
        case .createHabit:
            return Japanese.createHabitTranslations[key]
        case .habitDetail:
            return Japanese.habitDetailTranslations[key]
        case .proFeatures:
            return Japanese.proFeaturesTranslations[key]
        case .importExport:
            return Japanese.importExportTranslations[key]
        case .common:
            return Japanese.commonTranslations[key]
        case .contentView:
            return Japanese.contentViewTranslations[key]
        case .payment:
            return Japanese.paymentViewTranslations[key]
        case .emojiPicker:
            return Japanese.emojiPickerTranslations[key]
        }
    }
    
    // 页面类型枚举
    enum PageType {
        case settings
        case createHabit
        case habitDetail
        case proFeatures
        case importExport
        case common
        case contentView
        case payment
        case emojiPicker
        
        // 为每个页面类型提供一个唯一的前缀
        var prefix: String {
            switch self {
            case .settings: return "settings"
            case .createHabit: return "create"
            case .habitDetail: return "detail"
            case .proFeatures: return "pro"
            case .importExport: return "import"
            case .common: return "common"
            case .contentView: return "content"
            case .payment: return "payment"
            case .emojiPicker: return "emoji"
            }
        }
    }
    
    // 获取指定语言代码对应的语言名称
    func getLanguageName(for code: String) -> String {
        switch code {
            case "zh-Hans": return "中文"
            case "en": return "英文"
            case "ja": return "日语"
            default: return "系统默认"
        }
    }
    
    // 支持的语言代码数组 - 添加新语言时扩展此数组
    static let supportedLanguages = ["", "zh-Hans", "en", "ja"]
} 