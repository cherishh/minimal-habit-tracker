import Foundation
import SwiftUI

// 快捷访问本地化字符串的扩展
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}

// 为Text视图添加本地化扩展
extension Text {
    init(verbatim key: String) {
        self.init(key.localized)
    }
}

// 月份和星期的本地化辅助
struct DateFormatHelper {
    // 获取本地化的月份名称
    static func localizedMonthName(_ month: Int) -> String {
        return "\(month)月".localized
    }
    
    // 获取本地化的星期名称
    static func localizedWeekday(_ weekday: String) -> String {
        return weekday.localized
    }
} 