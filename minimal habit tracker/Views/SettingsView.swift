import SwiftUI
import MessageUI
import StoreKit

// 添加设置页面
struct SettingsView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("themeMode") private var themeMode: Int = 0 // 0: 自适应系统, 1: 明亮模式, 2: 暗黑模式
    @State private var showingImportExport = false
    @State private var showingComingSoonAlert = false
    @State private var comingSoonMessage = ""
    @State private var showingProAlert = false
    @State private var showingAppVersionTapCount = 0
    @State private var showingMailView = false
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    @State private var showingMailCannotSendAlert = false
    @State private var showingPaymentView = false
    
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
                                
                                Text("解锁完整体验")
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
                
                AppearanceSection
                DataSection
                UpgradeSection
                AboutSection
                
                // Debug 按钮
                Section {
                    Toggle("Debug 模式", isOn: Binding(
                        get: { habitStore.debugMode },
                        set: { newValue in
                            habitStore.toggleDebugMode()
                        }
                    ))
                }
            }
            .navigationTitle("设置")
            .navigationBarItems(trailing: Button("完成") {
                isPresented = false
            })
            .sheet(isPresented: $showingImportExport) {
                ImportExportView()
            }
            .sheet(isPresented: $showingPaymentView) {
                PaymentView()
            }
            .alert(comingSoonMessage, isPresented: $showingComingSoonAlert) {
                Button("好的", role: .cancel) { }
            }
            .sheet(isPresented: $showingMailView) {
                if MFMailComposeViewController.canSendMail() {
                    MailView(result: $mailResult, recipient: "jasonlovescola@gmail.com", subject: "EasyHabit用户反馈", body: generateEmailBody())
                }
            }
            .alert(isPresented: $showingMailCannotSendAlert) {
                Alert(title: Text("无法发送邮件"), message: Text("您的设备未设置邮件账户或无法发送邮件。请手动发送邮件至jasonlovescola@gmail.com"), dismissButton: .default(Text("确定")))
            }
        }
        .preferredColorScheme(getPreferredColorScheme())
    }
    
    // 根据设置返回颜色模式
    private func getPreferredColorScheme() -> ColorScheme? {
        switch themeMode {
            case 1: return .light     // 明亮模式
            case 2: return .dark      // 暗黑模式
            default: return nil       // 自适应系统
        }
    }
    
    // 在SettingsView中添加生成邮件正文的函数
    private func generateEmailBody() -> String {
        let deviceInfo = """
        
        ----------
        设备信息:
        设备型号: \(UIDevice.current.model)
        系统版本: \(UIDevice.current.systemVersion)
        应用版本: \(appVersion) (\(buildNumber))
        习惯数量: \(habitStore.habits.count)
        ----------
        
        请在此处描述您的问题或建议:
        
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
                Text(text)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var AppearanceSection: some View {
        Section(header: Text("主题设置")) {
            Picker("显示模式", selection: $themeMode) {
                Text("跟随系统").tag(0)
                Text("明亮模式").tag(1)
                Text("暗黑模式").tag(2)
            }
        }
    }
    
    private var DataSection: some View {
        Section(header: Text("数据管理")) {
            Button("导入 & 导出") {
                showingImportExport = true
            }
            .foregroundColor(.primary)
        }
    }
    
    private var UpgradeSection: some View {
        Section(header: Text("高级功能")) {
            Button {
                if !habitStore.isPro && !habitStore.debugMode {
                    comingSoonMessage = "请升级到 Pro 版本以使用自定义颜色主题功能"
                } else {
                    comingSoonMessage = "自定义颜色主题功能即将推出，敬请期待"
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
        Section(header: Text("关于")) {
            Button {
                showingAppVersionTapCount += 1
                if showingAppVersionTapCount >= 7 {
                    habitStore.toggleDebugMode()
                    showingAppVersionTapCount = 0
                }
            } label: {
                HStack {
                    Text("应用版本")
                        .foregroundColor(.primary)
                    Spacer()
                    Text(habitStore.debugMode ? "\(appVersion) (\(buildNumber)) [调试模式]" : "\(appVersion) (\(buildNumber))")
                        .foregroundColor(.secondary)
                }
            }
            
            NavigationLink(destination: TermsOfUseView()) {
                Text("用户协议")
            }
            
            NavigationLink(destination: PrivacyPolicyView()) {
                Text("隐私政策")
            }
            
            Button(action: {
                // 打开App Store评分页面（使用模拟URL）
                if let url = URL(string: "https://apps.apple.com/app/id1234567890?action=write-review") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Text("为我们评分")
                    Spacer()
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            Button(action: {
                sendFeedbackEmail()
            }) {
                HStack {
                    Text("我抓到了🐞")
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