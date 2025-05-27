import SwiftUI

// 用户协议视图
struct TermsOfUseView: View {
    @EnvironmentObject var habitStore: HabitStore
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("settings.terms.pageTitle".localized(in: .settings))
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom)
                
                Group {
                    Text("settings.terms.welcomeHeader".localized(in: .settings))
                        .font(.title2)
                        .bold()
                    
                    Text("settings.terms.welcomeBody".localized(in: .settings))
                    
                    Text("settings.terms.acceptanceHeader".localized(in: .settings))
                        .font(.headline)
                    Text("settings.terms.acceptanceBody".localized(in: .settings))
                    
                    Text("settings.terms.serviceDescriptionHeader".localized(in: .settings))
                        .font(.headline)
                    Text("settings.terms.serviceDescriptionBody".localized(in: .settings))
                    
                    Text("settings.terms.userBehaviorHeader".localized(in: .settings))
                        .font(.headline)
                    Text("settings.terms.userBehaviorBody".localized(in: .settings))
                    
                    Text("settings.terms.privacyProtectionHeader".localized(in: .settings))
                        .font(.headline)
                    Text("settings.terms.privacyProtectionBody".localized(in: .settings))
                    
                    Text("settings.terms.intellectualPropertyHeader".localized(in: .settings))
                        .font(.headline)
                    Text("settings.terms.intellectualPropertyBody".localized(in: .settings))
                }
                
                Group {
                    Text("settings.terms.disclaimerHeader".localized(in: .settings))
                        .font(.headline)
                    Text("settings.terms.disclaimerBody".localized(in: .settings))
                    
                    Text("settings.terms.agreementModificationsHeader".localized(in: .settings))
                        .font(.headline)
                    Text("settings.terms.agreementModificationsBody".localized(in: .settings))
                    
                    Text("settings.terms.contactUsHeader".localized(in: .settings))
                        .font(.headline)
                    Text("settings.terms.contactUsBody".localized(in: .settings))
                    
                    Text("\("settings.terms.lastUpdatedPrefix".localized(in: .settings))\("settings.terms.lastUpdatedDate".localized(in: .settings))")
                        .italic()
                        .padding(.top)
                }
            }
            .padding()
        }
        .navigationTitle("settings.用户协议".localized(in: .settings))
        .navigationBarTitleDisplayMode(.inline)
    }
} 