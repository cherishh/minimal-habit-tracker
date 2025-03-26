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
                        Text("Minimalism, Focus, Always Ad-Free")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 30)
                    
                    // 支付选项
                    HStack(spacing: 16) {
                        // 月付选项
                        PaymentOptionCard(
                            title: "Monthly",
                            price: "¥6.00",
                            subtitle: "Monthly",
                            isSelected: selectedPlan == .monthly,
                            action: {
                                selectedPlan = .monthly
                            }
                        )
                        
                        // 年付选项
                        PaymentOptionCard(
                            title: "Annually",
                            price: "¥36.00",
                            subtitle: "50% OFF",
                            isSelected: selectedPlan == .annually,
                            action: {
                                selectedPlan = .annually
                            }
                        )
                        
                        // 永久选项
                        PaymentOptionCard(
                            title: "Lifetime",
                            price: "¥36.00",
                            subtitle: "Limited time offer!",
                            originalPrice: "¥96.00",
                            // originalPrice: "¥126.00",
                            isSelected: selectedPlan == .lifetime,
                            action: {
                                selectedPlan = .lifetime
                            }
                        )
                    }
                    .padding(.horizontal)
                    
                    // 功能对比表
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Entitlements Comparison")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top)
                        
                        ComparisonRow(feature: "Widget Support", standardEnabled: true, proEnabled: true)
                        ComparisonRow(feature: "Basic Statistics", standardEnabled: true, proEnabled: true)
                        ComparisonRow(feature: "Share Habit", standardEnabled: true, proEnabled: true)
                        ComparisonRow(feature: "Export/Import Data", standardEnabled: true, proEnabled: true)
                        ComparisonRow(feature: "More Theme Colors", standardEnabled: false, proEnabled: true)
                        ComparisonRow(feature: "Unlimited Habits", standardEnabled: false, proEnabled: true)
                        ComparisonRow(feature: "iCloud Sync", standardEnabled: false, proEnabled: true)
                        ComparisonRow(feature: "Ads Free", standardEnabled: false, proEnabled: true)
                        // ComparisonRow(feature: "Remove Watermark", standardEnabled: false, proEnabled: true)
                    }
                    .padding()
                    
                    // 继续按钮
                    Button(action: {
                        // TODO: 根据 selectedPlan 拉起对应的 App Store 支付
                        switch selectedPlan {
                        case .monthly:
                            print("Initiating monthly subscription purchase")
                        case .annually:
                            print("Initiating annual subscription purchase")
                        case .lifetime:
                            print("Initiating lifetime purchase")
                        }
                        // 暂时保留这个逻辑用于测试
                        habitStore.upgradeToPro()
                        dismiss()
                    }) {
                        Text("Continue")
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
                        Button("Privacy Policy") {
                            // TODO: 显示隐私政策
                        }
                        Button("User Agreement") {
                            // TODO: 显示用户协议
                        }
                        Button("Restore subscription") {
                            // TODO: 恢复购买
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    // .padding(.top)
                }
            }
            .navigationBarItems(leading: Button("Close") {
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
                    .font(subtitle == "Limited time offer!" ? .caption2 : .caption)
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
            Text("Standard")
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