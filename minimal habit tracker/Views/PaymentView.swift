import SwiftUI

struct PaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedPlan: PaymentPlan = .monthly
    
    enum PaymentPlan {
        case monthly
        case annually
        case lifetime
    }
    
    // 根据语言返回不同的价格
    private func localizedPrice(for plan: PaymentPlan) -> (price: String, originalPrice: String?) {
        let language = habitStore.appLanguage.isEmpty ? 
                       (Locale.preferredLanguages.first?.hasPrefix("zh") == true ? "zh-Hans" : 
                        (Locale.preferredLanguages.first?.hasPrefix("ja") == true ? "ja" : "en")) : 
                       habitStore.appLanguage
        
        switch language {
        case "en":
            // 英文价格
            switch plan {
            case .monthly:
                return ("$1.99", nil)
            case .annually:
                return ("$11.99", nil)
            case .lifetime:
                return ("$29.99", "$59.99")
            }
        case "ja":
            // 日文价格
            switch plan {
            case .monthly:
                return ("¥250", nil)
            case .annually:
                return ("¥1500", nil)
            case .lifetime:
                return ("¥3000", "¥6000")
            }
        default:
            // 中文价格（默认）
            switch plan {
            case .monthly:
                return ("¥6.00", nil)
            case .annually:
                return ("¥36.00", nil)
            case .lifetime:
                return ("¥96.00", "¥196.00")
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 标题部分
                    VStack(spacing: 8) {
                        Text("EasyHabit")
                            .font(.system(size: 32, weight: .bold))
                        Text("PRO")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "eab308"))
                        Text("极简，专注，永远无广告".localized(in: .payment))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 30)
                    
                    // 支付选项
                    HStack(spacing: 16) {
                        // 月付选项
                        let monthlyPriceInfo = localizedPrice(for: .monthly)
                        PaymentOptionCard(
                            title: "月付".localized(in: .payment),
                            price: monthlyPriceInfo.price,
                            subtitle: "月付".localized(in: .payment),
                            originalPrice: monthlyPriceInfo.originalPrice,
                            isSelected: selectedPlan == .monthly,
                            action: {
                                selectedPlan = .monthly
                            }
                        )
                        
                        // 年付选项
                        let annuallyPriceInfo = localizedPrice(for: .annually)
                        PaymentOptionCard(
                            title: "年付".localized(in: .payment),
                            price: annuallyPriceInfo.price,
                            subtitle: "50%优惠".localized(in: .payment),
                            originalPrice: annuallyPriceInfo.originalPrice,
                            isSelected: selectedPlan == .annually,
                            action: {
                                selectedPlan = .annually
                            }
                        )
                        
                        // 永久选项
                        let lifetimePriceInfo = localizedPrice(for: .lifetime)
                        PaymentOptionCard(
                            title: "永久".localized(in: .payment),
                            price: lifetimePriceInfo.price,
                            subtitle: "限时优惠！".localized(in: .payment),
                            originalPrice: lifetimePriceInfo.originalPrice,
                            isSelected: selectedPlan == .lifetime,
                            action: {
                                selectedPlan = .lifetime
                            }
                        )
                    }
                    .padding(.horizontal)
                    
                    // 功能对比表
                    VStack(alignment: .leading, spacing: 16) {
                        Text("权益对比".localized(in: .payment))
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top)
                        
                        ComparisonRow(feature: "小组件支持".localized(in: .payment), standardEnabled: true, proEnabled: true)
                        ComparisonRow(feature: "基础统计".localized(in: .payment), standardEnabled: true, proEnabled: true)
                        ComparisonRow(feature: "分享习惯".localized(in: .payment), standardEnabled: true, proEnabled: true)
                        ComparisonRow(feature: "导入导出数据".localized(in: .payment), standardEnabled: true, proEnabled: true)
                        ComparisonRow(feature: "更多主题颜色".localized(in: .payment), standardEnabled: false, proEnabled: true)
                        ComparisonRow(feature: "无限习惯".localized(in: .payment), standardEnabled: false, proEnabled: true)
                        ComparisonRow(feature: "iCloud同步".localized(in: .payment), standardEnabled: false, proEnabled: true)
                        ComparisonRow(feature: "无广告".localized(in: .payment), standardEnabled: false, proEnabled: true)
                        // ComparisonRow(feature: "移除水印", standardEnabled: false, proEnabled: true)
                    }
                    .padding()
                    
                    // 继续按钮
                    Button(action: {
                        // TODO: 根据 selectedPlan 拉起对应的 App Store 支付
                        switch selectedPlan {
                        case .monthly:
                            let priceInfo = localizedPrice(for: .monthly)
                            print("Initiating monthly subscription purchase: \(priceInfo.price)")
                        case .annually:
                            let priceInfo = localizedPrice(for: .annually)
                            print("Initiating annual subscription purchase: \(priceInfo.price)")
                        case .lifetime:
                            let priceInfo = localizedPrice(for: .lifetime)
                            print("Initiating lifetime purchase: \(priceInfo.price)")
                        }
                        // 暂时保留这个逻辑用于测试
                        habitStore.upgradeToPro()
                        dismiss()
                    }) {
                        Text("继续".localized(in: .payment))
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.primary)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // 底部链接
                    HStack(spacing: 20) {
                        Button("隐私政策".localized(in: .settings)) {
                            // TODO: 显示隐私政策
                        }
                        Button("用户协议".localized(in: .settings)) {
                            // TODO: 显示用户协议
                        }
                        Button("恢复购买".localized(in: .payment)) {
                            // TODO: 恢复购买
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    // .padding(.top)
                }
            }
            .navigationBarItems(leading: Button("关闭".localized(in: .payment)) {
                dismiss()
            })
        }
    }
}

// 支付选项卡片
struct PaymentOptionCard: View {
    let title: String
    let price: String
    let subtitle: String
    let originalPrice: String?
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    init(title: String, price: String, subtitle: String, originalPrice: String? = nil, isSelected: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.price = price
        self.subtitle = subtitle
        self.originalPrice = originalPrice
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                Text(price)
                    .font(.title3)
                    .fontWeight(.bold)
                if let originalPrice = originalPrice {
                    Text(originalPrice)
                        .strikethrough()
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Text(subtitle)
                    .font(subtitle == "限时优惠！".localized(in: .payment) ? .caption2 : .caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .padding(.vertical, 11)
            .background(isSelected ? Color(hex: "eab308").opacity(0.1) : Color(UIColor.systemGray5).opacity(0.3))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? (colorScheme == .dark ? Color(hex: "eab308") : Color.primary) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 功能对比行
struct ComparisonRow: View {
    let feature: String
    let standardEnabled: Bool
    let proEnabled: Bool
    
    var body: some View {
        HStack {
            Text(feature)
                .font(.subheadline)
            Spacer()
            Text("标准版".localized(in: .payment))
                .font(.subheadline)
                .foregroundColor(.secondary)
            Image(systemName: standardEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(standardEnabled ? .green : .secondary)
            Text("PRO")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Image(systemName: proEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(proEnabled ? .green : .secondary)
        }
    }
}

#Preview {
    PaymentView()
        .environmentObject(HabitStore())
} 