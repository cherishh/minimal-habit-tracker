import SwiftUI

// 隐私政策视图
struct PrivacyPolicyView: View {
    @EnvironmentObject var habitStore: HabitStore
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("settings.privacy.pageTitle".localized(in: .settings))
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom)
                
                Group {
                    Text("settings.privacy.policyHeader".localized(in: .settings))
                        .font(.title2)
                        .bold()
                    
                    Text("settings.privacy.policyBody".localized(in: .settings))
                    
                    Text("settings.privacy.infoWeCollectHeader".localized(in: .settings))
                        .font(.headline)
                    Text("settings.privacy.infoWeCollectBody".localized(in: .settings))
                    
                    Text("settings.privacy.useOfInfoHeader".localized(in: .settings))
                        .font(.headline)
                    Text("settings.privacy.useOfInfoBody".localized(in: .settings))
                    
                    Text("settings.privacy.storageOfInfoHeader".localized(in: .settings))
                        .font(.headline)
                    Text("settings.privacy.storageOfInfoBody".localized(in: .settings))
                }
                
                Group {
                    Text("settings.privacy.infoSharingHeader".localized(in: .settings))
                        .font(.headline)
                    Text("settings.privacy.infoSharingBody".localized(in: .settings))
                    
                    Text("settings.privacy.yourRightsHeader".localized(in: .settings))
                        .font(.headline)
                    Text("settings.privacy.yourRightsBody".localized(in: .settings))
                    
                    Text("settings.privacy.childrensPrivacyHeader".localized(in: .settings))
                        .font(.headline)
                    Text("settings.privacy.childrensPrivacyBody".localized(in: .settings))
                    
                    Text("settings.privacy.policyUpdatesHeader".localized(in: .settings))
                        .font(.headline)
                    Text("settings.privacy.policyUpdatesBody".localized(in: .settings))
                    
                    Text("settings.privacy.contactUsHeader".localized(in: .settings))
                        .font(.headline)
                    Text("settings.privacy.contactUsBody".localized(in: .settings))
                    
                    Text("\("settings.privacy.lastUpdatedPrefix".localized(in: .settings))\("settings.privacy.lastUpdatedDate".localized(in: .settings))")
                        .italic()
                        .padding(.top)
                }
            }
            .padding()
        }
        .navigationTitle("settings.隐私政策".localized(in: .settings))
        .navigationBarTitleDisplayMode(.inline)
    }
} 