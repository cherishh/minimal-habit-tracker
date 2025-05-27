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
        let finalKey: String
        let prefixWithDot = "\(context.prefix)."
        if key.hasPrefix(prefixWithDot) {
            finalKey = key
        } else {
            finalKey = "\(prefixWithDot)\(key)"
        }
        
        // 获取当前语言设置
        let language = HabitStore.shared.appLanguage
        
        // 如果是空字符串（系统默认），则根据系统语言选择
        if language.isEmpty {
            let systemLanguage = Locale.preferredLanguages.first ?? "en"
            
            // 根据系统语言选择翻译
            switch true {
            case systemLanguage.hasPrefix("zh-Hans") || (systemLanguage.hasPrefix("zh") && !systemLanguage.hasPrefix("zh-Hant")):
                // 如果系统是简体中文，返回原始中文字符串 (如果key本身就是中文，则直接返回，否则尝试从字典获取)
                if let translation = getSimplifiedChineseTranslation(for: context, key: finalKey) {
                    return translation
                } else {
                    // 尝试去除前缀查找，适用于 settings.用户协议 这种直接用中文做键的情况
                    if key.hasPrefix(prefixWithDot) {
                        let originalKey = String(key.dropFirst(prefixWithDot.count))
                        if let cnTranslation = getSimplifiedChineseTranslation(for: context, key: originalKey) {
                            return cnTranslation
                        } else if key == originalKey { // 如果key就是中文，且字典里没有，就返回key
                            return key
                        }
                    } else if key == finalKey { // 如果key就是中文，且字典里没有，就返回key
                       return key
                    }
                    // 默认返回key，对于 settings.terms.pageTitle 这种，如果简体中文缺失，会显示键名
                    return key 
                }
            case systemLanguage.hasPrefix("zh-Hant"):
                // 如果系统是繁体中文，使用繁体中文翻译
                return getTraditionalChineseTranslation(for: context, key: finalKey) ?? key
            case systemLanguage.hasPrefix("ja"):
                // 如果系统是日语，使用日语翻译
                return getJapaneseTranslation(for: context, key: finalKey) ?? key
            case systemLanguage.hasPrefix("ru"):
                // 如果系统是俄语，使用俄语翻译
                return getRussianTranslation(for: context, key: finalKey) ?? key
            case systemLanguage.hasPrefix("es"):
                // 如果系统是西班牙语，使用西班牙语翻译
                return getSpanishTranslation(for: context, key: finalKey) ?? key
            case systemLanguage.hasPrefix("de"):
                // 如果系统是德语，使用德语翻译
                return getGermanTranslation(for: context, key: finalKey) ?? key
            case systemLanguage.hasPrefix("fr"):
                // 如果系统是法语，使用法语翻译
                return getFrenchTranslation(for: context, key: finalKey) ?? key
            default:
                // 默认使用英文
                return getEnglishTranslation(for: context, key: finalKey) ?? key
            }
        }
        
        // 根据用户设置的语言选择翻译
        switch language {
        case "en":
            // 如果是英文，查找带前缀的翻译
            return getEnglishTranslation(for: context, key: finalKey) ?? key
        case "zh-Hans":
            // 如果是简体中文，返回原始中文字符串 (如果key本身就是中文，则直接返回，否则尝试从字典获取)
            if let translation = getSimplifiedChineseTranslation(for: context, key: finalKey) {
                return translation
            } else {
                 // 尝试去除前缀查找，适用于 settings.用户协议 这种直接用中文做键的情况
                if key.hasPrefix(prefixWithDot) {
                    let originalKey = String(key.dropFirst(prefixWithDot.count))
                    if let cnTranslation = getSimplifiedChineseTranslation(for: context, key: originalKey) {
                        return cnTranslation
                    }  else if key == originalKey { // 如果key就是中文，且字典里没有，就返回key
                       return key
                    }
                } else if key == finalKey { // 如果key就是中文，且字典里没有，就返回key
                    return key
                }
                // 默认返回key，对于 settings.terms.pageTitle 这种，如果简体中文缺失，会显示键名
                return key 
            }
        case "zh-Hant":
            // 如果是繁体中文，查找带前缀的翻译
            return getTraditionalChineseTranslation(for: context, key: finalKey) ?? key
        case "ja":
            // 如果是日语，查找带前缀的翻译
            return getJapaneseTranslation(for: context, key: finalKey) ?? key
        case "ru":
            // 如果是俄语，查找带前缀的翻译
            return getRussianTranslation(for: context, key: finalKey) ?? key
        case "es":
            // 如果是西班牙语，查找带前缀的翻译
            return getSpanishTranslation(for: context, key: finalKey) ?? key
        case "de":
            // 如果是德语，查找带前缀的翻译
            return getGermanTranslation(for: context, key: finalKey) ?? key
        case "fr":
            // 如果是法语，查找带前缀的翻译
            return getFrenchTranslation(for: context, key: finalKey) ?? key
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
    
    // 新增：根据上下文和键获取简体中文翻译
    private func getSimplifiedChineseTranslation(for context: PageType, key: String) -> String? {
        // 简体中文的翻译直接在各自的字典中，键名与内容一致，或者在特定的settingsTranslations中查找
        // 这里我们假设简体中文的键值对也可能存在于 settingsTranslations，就像其他语言一样
        // 如果没有，则直接返回 key （因为对于中文，key 本身就是期望的文本）
        // 对于 "settings.用户协议" 这样的键，其本身就是中文，应该被直接返回

        switch context {
        case .settings:
            // 对于 settings 页面，我们有 settingsTranslations
            // 检查 settingsTranslations 是否包含这个 key
            if let translated = Chinese.settingsTranslations[key] {
                return translated
            }
            // 如果 settingsTranslations 中没有，并且 key 本身就是 settings.开头的（比如 settings.用户协议）
            // 那么 originalKey 就是 "用户协议"
            let prefixWithDot = "\(context.prefix)."
            if key.hasPrefix(prefixWithDot) {
                 let originalKey = String(key.dropFirst(prefixWithDot.count))
                 // 如果原始的 key (不含prefix) 就是中文，那么应该返回它
                 // 检查一下 Chinese.settingsTranslations 是否有 originalKey (例如 "用户协议")
                 if let translatedOriginal = Chinese.settingsTranslations[originalKey] {
                     return translatedOriginal
                 }
                 // 如果原始的 key 无法在字典中找到，但它看起来就是实际的中文文本，则返回它
                 // 这是一个启发式的方法，假设不包含"."的非空字符串是目标文本
                 if !originalKey.contains(".") && !originalKey.isEmpty {
                     return originalKey
                 }
            }
            // 如果 key 不是 settings. 开头，并且在字典中找不到，那么它可能本身就是中文文本
             if !key.contains(".") && !key.isEmpty {
                return key
            }
            // 都没有命中，则返回nil，让调用处决定如何处理（比如返回 key 本身）
            return nil
        case .createHabit:
            return Chinese.createHabitTranslations[key] ?? key // 对于其他类型，如果找不到则返回key
        case .habitDetail:
            return Chinese.habitDetailTranslations[key] ?? key
        case .proFeatures:
            return Chinese.proFeaturesTranslations[key] ?? key
        case .importExport:
            return Chinese.importExportTranslations[key] ?? key
        case .common:
            return Chinese.commonTranslations[key] ?? key
        case .contentView:
            return Chinese.contentViewTranslations[key] ?? key
        case .payment:
            return Chinese.paymentViewTranslations[key] ?? key
        case .emojiPicker:
            return Chinese.emojiPickerTranslations[key] ?? key
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