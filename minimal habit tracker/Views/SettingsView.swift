import SwiftUI
import MessageUI
import StoreKit

// 添加设置页面
struct SettingsView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("themeMode") private var themeMode: Int = 0 // 0: 自适应系统, 1: 明亮模式, 2: 暗黑模式
    @State private var forceUpdate = false // 简单的状态触发器
    @State private var showingImportExport = false
    @State private var showingComingSoonAlert = false
    @State private var comingSoonMessage = ""
    @State private var showingProAlert = false
    @State private var showingAppVersionTapCount = 0
    @State private var showingMailView = false
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    @State private var showingMailCannotSendAlert = false
    @State private var showingPaymentView = false
    
    // 语言选择状态
    @State private var selectedLanguage: String = HabitStore.shared.appLanguage
    
    // 覆盖版本号（保持与项目文件一致）
    let appVersion = "0.1"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "未知构建号"
    
    // 这些开关不会实际保存设置，仅作为UI展示
    @State private var iCloudSync = false
    @State private var noteFeature = false
    @State private var detailedDataStats = false
    
    var body: some View {
        NavigationView {
            List {
                // Pro 升级卡片
                /*
                if !habitStore.isPro && !habitStore.debugMode {
                    Section {
                        Button(action: {
                            showingPaymentView = true
                        }) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("EasyHabit")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    Text("PRO")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(hex: "eab308"))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("解锁完整体验".localized(in: .proFeatures))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 16) {
                                    ProFeatureItem(icon: "paintpalette", text: "更多主题色")
                                    ProFeatureItem(icon: "infinity", text: "无限习惯")
                                    ProFeatureItem(icon: "icloud", text: "iCloud同步")
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                */
                
                AppearanceSection
                LanguageSection
                DataSection
                // UpgradeSection
                AboutSection
                
                // Debug 按钮
                // Section {
                //     Toggle("Debug 模式", isOn: Binding(
                //         get: { habitStore.debugMode },
                //         set: { newValue in
                //             habitStore.toggleDebugMode()
                //         }
                //     ))
                // }
            }
            .navigationTitle("设置".localized(in: .settings))
            .navigationBarItems(trailing: Button("完成".localized(in: .settings)) {
                isPresented = false
            })
            .sheet(isPresented: $showingImportExport) {
                ImportExportView()
            }
            .sheet(isPresented: $showingPaymentView) {
                PaymentView()
            }
            .alert(comingSoonMessage, isPresented: $showingComingSoonAlert) {
                Button("好的".localized(in: .common), role: .cancel) { }
            }
            .sheet(isPresented: $showingMailView) {
                if MFMailComposeViewController.canSendMail() {
                    MailView(result: $mailResult, recipient: "jasonlovescola@gmail.com", subject: "EasyHabit User Feedback", body: generateEmailBody())
                }
            }
            .alert(isPresented: $showingMailCannotSendAlert) {
                Alert(title: Text("无法发送邮件".localized(in: .common)), message: Text("您的设备未设置邮件账户或无法发送邮件。请手动发送邮件至jasonlovescola@gmail.com".localized(in: .common)), dismissButton: .default(Text("确定".localized(in: .common))))
            }
        }
        .id(forceUpdate) // 使用简单的状态变量
        .environment(\.colorScheme, getCurrentColorScheme())
        .onChange(of: themeMode) { _ in
            // 当主题模式变化时，切换状态触发视图更新
            forceUpdate.toggle()
        }
    }
    
    // 简化为一个方法，直接返回当前应该使用的颜色方案
    private func getCurrentColorScheme() -> ColorScheme {
        switch themeMode {
            case 1: return .light    // 明亮模式
            case 2: return .dark     // 暗黑模式
            default:                 // 跟随系统模式
                let isDark = UIScreen.main.traitCollection.userInterfaceStyle == .dark
                return isDark ? .dark : .light
        }
    }
    
    // 在SettingsView中添加生成邮件正文的函数
    private func generateEmailBody() -> String {
        let deviceInfo = """
        
        ----------
        \("设备信息".localized(in: .common)):
        \("设备型号".localized(in: .common)): \(UIDevice.current.model)
        \("系统版本".localized(in: .common)): \(UIDevice.current.systemVersion)
        \("应用版本".localized(in: .settings)): \(appVersion) (\(buildNumber))
        \("习惯数量".localized(in: .common)): \(habitStore.habits.count)
        ----------
        
        \("请在此处描述您的问题或建议".localized(in: .common)):
        
        """
        
        return deviceInfo
    }
    
    // 在SettingsView中添加邮件发送功能
    private func sendFeedbackEmail() {
        if MFMailComposeViewController.canSendMail() {
            showingMailView = true
        } else {
            showingMailCannotSendAlert = true
        }
    }

    // 添加 Pro 功能项组件
    private struct ProFeatureItem: View {
        let icon: String
        let text: String
        
        var body: some View {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                Text(text.localized(in: .proFeatures))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var AppearanceSection: some View {
        Section(header: Text("主题设置".localized(in: .settings))) {
            Picker("显示模式".localized(in: .settings), selection: $themeMode) {
                Text("跟随系统".localized(in: .settings)).tag(0)
                Text("明亮模式".localized(in: .settings)).tag(1)
                Text("暗黑模式".localized(in: .settings)).tag(2)
            }
        }
    }
    
    private var LanguageSection: some View {
        Section(header: Text("语言".localized(in: .settings))) {
            Picker("语言".localized(in: .settings), selection: $selectedLanguage) {
                Text(LanguageManager.shared.getLanguageName(for: "")).tag("")
                Text(LanguageManager.shared.getLanguageName(for: "en")).tag("en")
                Text(LanguageManager.shared.getLanguageName(for: "de")).tag("de")
                Text(LanguageManager.shared.getLanguageName(for: "es")).tag("es")
                Text(LanguageManager.shared.getLanguageName(for: "fr")).tag("fr")
                Text(LanguageManager.shared.getLanguageName(for: "ja")).tag("ja")
                Text(LanguageManager.shared.getLanguageName(for: "ru")).tag("ru")
                Text(LanguageManager.shared.getLanguageName(for: "zh-Hans")).tag("zh-Hans")
                Text(LanguageManager.shared.getLanguageName(for: "zh-Hant")).tag("zh-Hant")
            }
            .onChange(of: selectedLanguage) { newValue in
                // 不直接调用habitStore.setAppLanguage，而是先保存当前界面状态
                DispatchQueue.main.async {
                    // 异步修改语言设置
                    habitStore.appLanguage = newValue
                    // 发送通知但不关闭当前界面
                    NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
                    // 强制更新当前视图
                    forceUpdate.toggle()
                }
            }
        }
    }
    
    private var DataSection: some View {
        Section(header: Text("数据管理".localized(in: .settings))) {
            Button("导入 & 导出".localized(in: .settings)) {
                showingImportExport = true
            }
            .foregroundColor(.primary)
        }
    }
    
    private var UpgradeSection: some View {
        Section(header: Text("高级功能")) {
            Button {
                if !habitStore.isPro && !habitStore.debugMode {
                    comingSoonMessage = "请升级到 Pro 版本以使用自定义颜色主题功能".localized(in: .proFeatures)
                } else {
                    comingSoonMessage = "自定义颜色主题功能即将推出，敬请期待".localized(in: .proFeatures)
                }
                showingComingSoonAlert = true
            } label: {
                HStack {
                    Text("🎨 自定义颜色主题")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                }
            }

            // Toggle("iCloud同步", isOn: $iCloudSync)
            //     .onChange(of: iCloudSync) { newValue in
            //         iCloudSync = false
            //         if !habitStore.isPro && !habitStore.debugMode {
            //             comingSoonMessage = "请升级到 Pro 版本以使用 iCloud 同步功能"
            //         } else {
            //             comingSoonMessage = "iCloud同步功能即将推出"
            //         }
            //         showingComingSoonAlert = true
            //     }
            //     .disabled(!habitStore.isPro && !habitStore.debugMode)

            // Toggle("数据分析与建议", isOn: $detailedDataStats)
            //     .onChange(of: detailedDataStats) { newValue in
            //         detailedDataStats = false
            //         if !habitStore.isPro && !habitStore.debugMode {
            //             comingSoonMessage = "请升级到 Pro 版本以使用数据分析功能"
            //         } else {
            //             comingSoonMessage = "数据分析与建议功能即将推出"
            //         }
            //         showingComingSoonAlert = true
            //     }
            //     .disabled(!habitStore.isPro && !habitStore.debugMode)
        }
    }

    private var AboutSection: some View {
        Section(header: Text("关于".localized(in: .settings))) {
            Button {
                showingAppVersionTapCount += 1
                if showingAppVersionTapCount >= 7 {
                    habitStore.toggleDebugMode()
                    showingAppVersionTapCount = 0
                }
            } label: {
                HStack {
                    Text("应用版本".localized(in: .settings))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(habitStore.debugMode ? "\(appVersion) (\(buildNumber)) [调试模式]" : "\(appVersion) (\(buildNumber))")
                        .foregroundColor(.secondary)
                }
            }
            
            NavigationLink(destination: TermsOfUseView()) {
                Text("用户协议".localized(in: .settings))
            }
            
            NavigationLink(destination: PrivacyPolicyView()) {
                Text("隐私政策".localized(in: .settings))
            }
            
            Button(action: {
                // 打开App Store评分页面（使用模拟URL）
                if let url = URL(string: "https://apps.apple.com/app/id1234567890?action=write-review") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Text("为我们评分".localized(in: .settings))
                    Spacer()
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            Button(action: {
                sendFeedbackEmail()
            }) {
                HStack {
                    Text("我抓到了🐞".localized(in: .settings))
                    Spacer()
                    Image("square-arrow-out-up-right")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 20, height: 20)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
} 