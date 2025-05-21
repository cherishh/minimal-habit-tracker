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
            
            // 根据系统语言选择翻译
            switch true {
            case systemLanguage.hasPrefix("zh-Hans") || (systemLanguage.hasPrefix("zh") && !systemLanguage.hasPrefix("zh-Hant")):
                // 如果系统是简体中文，返回原始中文字符串
                return key
            case systemLanguage.hasPrefix("zh-Hant"):
                // 如果系统是繁体中文，使用繁体中文翻译
                return getTraditionalChineseTranslation(for: context, key: contextKey) ?? key
            case systemLanguage.hasPrefix("ja"):
                // 如果系统是日语，使用日语翻译
                return getJapaneseTranslation(for: context, key: contextKey) ?? key
            case systemLanguage.hasPrefix("ru"):
                // 如果系统是俄语，使用俄语翻译
                return getRussianTranslation(for: context, key: contextKey) ?? key
            case systemLanguage.hasPrefix("es"):
                // 如果系统是西班牙语，使用西班牙语翻译
                return getSpanishTranslation(for: context, key: contextKey) ?? key
            case systemLanguage.hasPrefix("de"):
                // 如果系统是德语，使用德语翻译
                return getGermanTranslation(for: context, key: contextKey) ?? key
            case systemLanguage.hasPrefix("fr"):
                // 如果系统是法语，使用法语翻译
                return getFrenchTranslation(for: context, key: contextKey) ?? key
            default:
                // 默认使用英文
                return getEnglishTranslation(for: context, key: contextKey) ?? key
            }
        }
        
        // 根据用户设置的语言选择翻译
        switch language {
        case "en":
            // 如果是英文，查找带前缀的翻译
            return getEnglishTranslation(for: context, key: contextKey) ?? key
        case "zh-Hans":
            // 如果是简体中文，返回原始中文字符串
            return key
        case "zh-Hant":
            // 如果是繁体中文，查找带前缀的翻译
            return getTraditionalChineseTranslation(for: context, key: contextKey) ?? key
        case "ja":
            // 如果是日语，查找带前缀的翻译
            return getJapaneseTranslation(for: context, key: contextKey) ?? key
        case "ru":
            // 如果是俄语，查找带前缀的翻译
            return getRussianTranslation(for: context, key: contextKey) ?? key
        case "es":
            // 如果是西班牙语，查找带前缀的翻译
            return getSpanishTranslation(for: context, key: contextKey) ?? key
        case "de":
            // 如果是德语，查找带前缀的翻译
            return getGermanTranslation(for: context, key: contextKey) ?? key
        case "fr":
            // 如果是法语，查找带前缀的翻译
            return getFrenchTranslation(for: context, key: contextKey) ?? key
        default:
            // 如果没有找到匹配的翻译，就返回原字符串
            return key
        }
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
    
    // 根据上下文和键获取俄语翻译
    private func getRussianTranslation(for context: PageType, key: String) -> String? {
        switch context {
        case .settings:
            return Russian.settingsTranslations[key]
        case .createHabit:
            return Russian.createHabitTranslations[key]
        case .habitDetail:
            return Russian.habitDetailTranslations[key]
        case .proFeatures:
            return Russian.proFeaturesTranslations[key]
        case .importExport:
            return Russian.importExportTranslations[key]
        case .common:
            return Russian.commonTranslations[key]
        case .contentView:
            return Russian.contentViewTranslations[key]
        case .payment:
            return Russian.paymentViewTranslations[key]
        case .emojiPicker:
            return Russian.emojiPickerTranslations[key]
        }
    }
    
    // 根据上下文和键获取西班牙语翻译
    private func getSpanishTranslation(for context: PageType, key: String) -> String? {
        switch context {
        case .settings:
            return Spanish.settingsTranslations[key]
        case .createHabit:
            return Spanish.createHabitTranslations[key]
        case .habitDetail:
            return Spanish.habitDetailTranslations[key]
        case .proFeatures:
            return Spanish.proFeaturesTranslations[key]
        case .importExport:
            return Spanish.importExportTranslations[key]
        case .common:
            return Spanish.commonTranslations[key]
        case .contentView:
            return Spanish.contentViewTranslations[key]
        case .payment:
            return Spanish.paymentViewTranslations[key]
        case .emojiPicker:
            return Spanish.emojiPickerTranslations[key]
        }
    }
    
    // 根据上下文和键获取德语翻译
    private func getGermanTranslation(for context: PageType, key: String) -> String? {
        switch context {
        case .settings:
            return German.settingsTranslations[key]
        case .createHabit:
            return German.createHabitTranslations[key]
        case .habitDetail:
            return German.habitDetailTranslations[key]
        case .proFeatures:
            return German.proFeaturesTranslations[key]
        case .importExport:
            return German.importExportTranslations[key]
        case .common:
            return German.commonTranslations[key]
        case .contentView:
            return German.contentViewTranslations[key]
        case .payment:
            return German.paymentViewTranslations[key]
        case .emojiPicker:
            return German.emojiPickerTranslations[key]
        }
    }
    
    // 根据上下文和键获取法语翻译
    private func getFrenchTranslation(for context: PageType, key: String) -> String? {
        switch context {
        case .settings:
            return French.settingsTranslations[key]
        case .createHabit:
            return French.createHabitTranslations[key]
        case .habitDetail:
            return French.habitDetailTranslations[key]
        case .proFeatures:
            return French.proFeaturesTranslations[key]
        case .importExport:
            return French.importExportTranslations[key]
        case .common:
            return French.commonTranslations[key]
        case .contentView:
            return French.contentViewTranslations[key]
        case .payment:
            return French.paymentViewTranslations[key]
        case .emojiPicker:
            return French.emojiPickerTranslations[key]
        }
    }
    
    // 添加一个新的方法来获取繁体中文翻译
    private func getTraditionalChineseTranslation(for context: PageType, key: String) -> String? {
        switch context {
        case .settings:
            return TraditionalChinese.settingsTranslations[key]
        case .createHabit:
            return TraditionalChinese.createHabitTranslations[key]
        case .habitDetail:
            return TraditionalChinese.habitDetailTranslations[key]
        case .proFeatures:
            return TraditionalChinese.proFeaturesTranslations[key]
        case .importExport:
            return TraditionalChinese.importExportTranslations[key]
        case .common:
            return TraditionalChinese.commonTranslations[key]
        case .contentView:
            return TraditionalChinese.contentViewTranslations[key]
        case .payment:
            return TraditionalChinese.paymentViewTranslations[key]
        case .emojiPicker:
            return TraditionalChinese.emojiPickerTranslations[key]
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
        if code.isEmpty {
            // 空字符串表示系统默认，返回对应翻译
            return "系统默认".localized(in: .settings)
        }
        
        switch code {
            case "zh-Hans": return "简体中文"
            case "zh-Hant": return "繁體中文"
            case "en": return "English"
            case "ja": return "日本語"
            case "ru": return "Русский"
            case "es": return "Español"
            case "de": return "Deutsch"
            case "fr": return "Français"
            default: return code
        }
    }
    
    // 支持的语言代码数组 - 添加新语言时扩展此数组
    static let supportedLanguages = ["", "zh-Hans", "zh-Hant", "en", "ja", "ru", "es", "de", "fr"]
} 