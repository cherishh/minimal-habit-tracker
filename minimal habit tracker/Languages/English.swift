import Foundation

struct English {
    // 设置页面翻译
    static let settingsTranslations: [String: String] = [
        "settings.设置": "Settings",
        "settings.完成": "Done",
        "settings.主题设置": "Theme",
        "settings.显示模式": "Display Mode",
        "settings.跟随系统": "System",
        "settings.明亮模式": "Light Mode",
        "settings.暗黑模式": "Dark Mode",
        "settings.数据管理": "Data Management",
        "settings.导入 & 导出": "Import & Export",
        "settings.关于": "About",
        "settings.应用版本": "App Version",
        "settings.用户协议": "Terms of Use",
        "settings.隐私政策": "Privacy Policy",
        "settings.为我们评分": "Rate Us",
        "settings.我抓到了🐞": "I Found a Bug",
        "settings.语言": "Language",
        "settings.中文": "Chinese",
        "settings.英文": "English",
        "settings.日语": "Japanese",
        "settings.系统默认": "System Default",
        "settings.Debug 模式": "Debug Mode"
    ]
    
    // 创建习惯页面翻译
    static let createHabitTranslations: [String: String] = [
        "create.创建新习惯": "Create New Habit",
        "create.习惯名称": "Habit Name",
        "create.图标": "Icon",
        "create.选择颜色主题": "Select Color Theme",
        "create.习惯类型": "Habit Type",
        "create.单次打卡": "Check Once",
        "create.多次打卡": "Multiple Checks",
        "create.确认": "Confirm",
        "create.请输入习惯名称": "Please enter habit name",
        "create.请选择图标": "Please select an icon",
        "create.每日打卡上限": "Daily Check-in Limit",
        "create.取消": "Cancel",
        "create.确定": "OK",
        "create.选择后不可更改": "Cannot be changed after selection",
        "create.打卡": "Check-in",
        "create.计数": "Count",
        "create.完成一次打卡就记录为完成。如：每天吃早餐": "Record as completed after one check-in. E.g.: Daily breakfast",
        "create.设置每日目标次数，可多次打卡。如：每天X杯喝水": "Set daily target count, allows multiple check-ins. E.g.: Daily water intake",
        "create.例如: 每日锻炼": "Example: Daily exercise",
        "create.选择图标": "Select Icon",
        "create.颜色主题": "Color Theme",
        "create.选择的类型: ": "Selected Type: ",
        "create.打卡次数上限": "Check-in Limit",
        "create.设置每日打卡的最大次数": "Set the maximum number of daily check-ins",
        "create.Widget 配置信息": "Widget Configuration",
        "create.习惯 ID": "Habit ID",
        "create.已复制到剪贴板": "Copied to clipboard",
        "create.配置 Widget 时需要输入此ID": "Enter this ID when configuring the Widget",
        "create.确认修改打卡次数": "Confirm Change to Check-in Limit",
        "create.修改打卡次数将影响所有已存在的记录。": "Changing the check-in limit will affect all existing records.",
        "create.超过新上限的记录将被调整为新的上限值。": "Records exceeding the new limit will be adjusted to the new maximum value.",
        "create.\n是否继续？": "\nContinue?",
        "create.编辑习惯": "Edit Habit",
        "create.确定习惯类型": "Choose Habit Type",
        "create.打卡一次即完成": "Complete with one check-in",
        "create.多次打卡完成目标": "Multiple check-ins to complete",
        "create.购买 PRO 版本解锁高级主题": "Purchase PRO version to unlock advanced themes"
    ]
    
    // 习惯详情页面翻译
    static let habitDetailTranslations: [String: String] = [
        "detail.习惯详情": "Habit Details",
        "detail.统计": "Statistics",
        "detail.总打卡次数": "Total Check-ins",
        "detail.总天数": "Total Days",
        "detail.连续打卡": "Streak",
        "detail.最长连续": "Longest Streak",
        "detail.当前连续": "Current Streak",
        "detail.完成率": "Completion Rate",
        "detail.热力图": "Heatmap",
        "detail.编辑": "Edit",
        "detail.删除习惯": "Delete Habit",
        "detail.删除确认": "Delete Confirmation",
        "detail.您确定要删除这个习惯吗？此操作不可撤销，所有相关数据将被永久删除。": "Are you sure you want to delete this habit? This action cannot be undone, and all related data will be permanently deleted.",
        "detail.分享功能即将推出": "Share Feature Coming Soon",
        "detail.正在开发中，敬请期待": "Under development, stay tuned",
        "detail.总计天数": "Total Days",
        "detail.天": " days",
        "detail.本月打卡": "This Month",
        "detail.少": "Less",
        "detail.多": "More",
        "detail.月": " Month",
        "detail.一": "Mon",
        "detail.二": "Tue",
        "detail.三": "Wed",
        "detail.四": "Thu",
        "detail.五": "Fri",
        "detail.六": "Sat",
        "detail.日": "Sun",
        "detail.1月": "January",
        "detail.2月": "February",
        "detail.3月": "March",
        "detail.4月": "April",
        "detail.5月": "May",
        "detail.6月": "June",
        "detail.7月": "July",
        "detail.8月": "August",
        "detail.9月": "September",
        "detail.10月": "October",
        "detail.11月": "November",
        "detail.12月": "December",
        "detail.热图.一": "Mo",
        "detail.热图.二": "Tu",
        "detail.热图.三": "We",
        "detail.热图.四": "Th",
        "detail.热图.五": "Fr",
        "detail.热图.六": "Sa",
        "detail.热图.日": "Su",
        "detail.热图.1月": "Jan",
        "detail.热图.2月": "Feb",
        "detail.热图.3月": "Mar",
        "detail.热图.4月": "Apr",
        "detail.热图.5月": "May",
        "detail.热图.6月": "Jun",
        "detail.热图.7月": "Jul",
        "detail.热图.8月": "Aug",
        "detail.热图.9月": "Sep",
        "detail.热图.10月": "Oct",
        "detail.热图.11月": "Nov",
        "detail.热图.12月": "Dec"
    ]
    
    // Pro功能翻译
    static let proFeaturesTranslations: [String: String] = [
        "pro.解锁完整体验": "Unlock Full Experience",
        "pro.更多主题色": "More Themes",
        "pro.请升级到 Pro 版本以使用自定义颜色主题功能": "Please upgrade to Pro version to use custom color themes",
        "pro.自定义颜色主题功能即将推出，敬请期待": "Custom color themes coming soon",
        "pro.请升级到 Pro 版本以使用 iCloud 同步功能": "Please upgrade to Pro version to use iCloud sync",
        "pro.iCloud同步功能即将推出": "iCloud sync coming soon",
        "pro.请升级到 Pro 版本以使用数据分析功能": "Please upgrade to Pro version to use data analysis",
        "pro.数据分析与建议功能即将推出": "Data analysis and suggestions coming soon"
    ]
    
    // 导入导出功能翻译
    static let importExportTranslations: [String: String] = [
        "import.导入成功": "Import Successful",
        "import.导出成功": "Export Successful",
        "import.导入习惯数据": "Import Habit Data",
        "import.导出习惯数据": "Export Habit Data",
        "import.无法解析JSON数据": "Could not parse JSON data",
        "import.导入错误": "Import Error",
        "import.导入的数据不是有效的习惯数据格式": "The imported data is not a valid habit data format",
        
        // 导入导出视图新增翻译
        "import.选择要执行的操作": "Select an action to perform",
        "import.导出数据": "Export Data",
        "import.将您的所有习惯和打卡记录导出为标准CSV文件，可用于备份": "Export all your habits and check-in records as a standard CSV file for backup",
        "import.导入数据": "Import Data",
        "import.从CSV文件导入习惯和打卡记录，用于恢复备份或迁移数据": "Import habits and check-in records from a CSV file to restore backups or migrate data",
        "import.准备导出数据中...": "Preparing data for export...",
        "import.导入 & 导出": "Import & Export",
        "import.完成": "Done",
        "import.确定": "OK",
        "import.创建导出文件失败": "Failed to create export file",
        "import.正在准备数据，请稍后重试": "Preparing data, please try again later",
        "import.导入文件为空或格式不正确": "Import file is empty or incorrectly formatted",
        "import.CSV文件格式不正确，请确保包含正确的列标题": "CSV file format is incorrect, please ensure it contains the correct column headers",
        "import.CSV文件格式不正确，第": "CSV file format is incorrect, line ",
        "import.行数据不完整": " data incomplete",
        "import.无效的习惯ID格式": "Invalid habit ID format",
        "import.无效的日期格式": "Invalid date format",
        "import.无效的打卡次数": "Invalid check-in count",
        "import.无效的最大打卡次数": "Invalid maximum check-in count",
        "import.无效的习惯类型": "Invalid habit type",
        "import.无效的颜色主题": "Invalid color theme",
        "import.导入数据中有": "The imported data has ",
        "import.个习惯ID与现有习惯重复": " habit IDs that duplicate existing habits",
        "import.成功导入": "Successfully imported ",
        "import.个习惯和": " habits and ",
        "import.条打卡记录": " check-in records",
        "import.读取CSV文件失败": "Failed to read CSV file"
    ]
    
    // 通用功能翻译
    static let commonTranslations: [String: String] = [
        "common.好的": "OK",
        "common.无法发送邮件": "Cannot Send Email",
        "common.您的设备未设置邮件账户或无法发送邮件。请手动发送邮件至jasonlovescola@gmail.com": "Your device has no mail account set up or cannot send mail. Please manually send an email to jasonlovescola@gmail.com",
        "common.设备信息": "Device Information",
        "common.设备型号": "Device Model",
        "common.系统版本": "System Version",
        "common.习惯数量": "Habit Count",
        "common.请在此处描述您的问题或建议": "Please describe your issue or suggestion here",
        "common.取消": "Cancel",
        "common.返回": "Back",
        "common.保存": "Save",
        "common.确定": "OK"
    ]
    
    // 主内容页面翻译
    static let contentViewTranslations: [String: String] = [
        "content.空空如也": "Empty",
        "content.👇开始记录追踪你的习惯": "👇Start tracking your habits",
        "content.达到最大数量": "Maximum Reached",
        "content.您最多只能创建 \(HabitStore.maxHabitCount) 个习惯。如需添加更多，请前往设置页面升级到Pro版本。": "You can create at most \(HabitStore.maxHabitCount) habits. To add more, please upgrade to Pro version in Settings.",
        "content.我知道了": "Got it",
        "content.确认删除": "Confirm Delete",
        "content.确定要删除这个习惯吗？所有相关的打卡记录也将被删除。此操作无法撤销。": "Are you sure you want to delete this habit? All related check-in records will also be deleted. This action cannot be undone.",
        "content.排序习惯": "Sort Habits"
    ]
    
    // 支付页面翻译
    static let paymentViewTranslations: [String: String] = [
        "payment.关闭": "Close",
        "payment.极简，专注，永远无广告": "Minimalism, Focus, Always Ad-Free",
        "payment.月付": "Monthly",
        "payment.年付": "Annually",
        "payment.永久": "Lifetime",
        "payment.限时优惠！": "Limited time offer!",
        "payment.权益对比": "Entitlements Comparison",
        "payment.继续": "Continue",
        "payment.小组件支持": "Widget Support",
        "payment.基础统计": "Basic Statistics",
        "payment.分享习惯": "Share Habit",
        "payment.导入导出数据": "Export/Import Data",
        "payment.更多主题颜色": "More Theme Colors",
        "payment.无限习惯": "Unlimited Habits",
        "payment.iCloud同步": "iCloud Sync",
        "payment.无广告": "Ads Free",
        "payment.标准版": "Standard",
        "payment.50%优惠": "50% OFF",
        "payment.恢复购买": "Restore subscription"
    ]
    
    // Emoji选择器翻译
    static let emojiPickerTranslations: [String: String] = [
        "emoji.最近使用": "Recently Used",
        "emoji.人物": "People",
        "emoji.自然": "Nature",
        "emoji.物品": "Objects",
        "emoji.地点": "Places",
        "emoji.符号": "Symbols",
        "emoji.Emoji": "Emoji",
        "emoji.Text": "Text",
        "emoji.输入文字": "Enter Text",
        "emoji.将取第一个字作为习惯图标。你也可以输入自定义的 emoji": "The first character will be used as the habit icon. You can also enter a custom emoji",
        "emoji.选择图标": "Select Icon"
    ]
} 