import SwiftUI

// 用户协议视图
struct TermsOfUseView: View {
    @EnvironmentObject var habitStore: HabitStore
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(habitStore.appLanguage == "en" ? "Terms of Use" : "用户协议")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom)
                
                Group {
                    Text(habitStore.appLanguage == "en" ? "Welcome to EasyHabit App" : "欢迎使用EasyHabit应用")
                        .font(.title2)
                        .bold()
                    
                    Text(habitStore.appLanguage == "en" ? 
                         "This agreement is between you and EasyHabit (hereinafter referred to as \"we\") regarding your use of the EasyHabit application and related services. Before you start using the EasyHabit application, please carefully read and fully understand the entire content of this agreement." : 
                         "本协议是您与EasyHabit（下称\"我们\"）之间关于您使用EasyHabit应用及相关服务的协议。在您开始使用EasyHabit应用之前，请您务必认真阅读并充分理解本协议的全部内容。")
                    
                    Text(habitStore.appLanguage == "en" ? "1. Acceptance of Terms" : "1. 接受条款")
                        .font(.headline)
                    Text(habitStore.appLanguage == "en" ? 
                         "By using the EasyHabit application, you confirm that you are at least 16 years old and agree to be bound by this agreement. If you are under 16 years of age, you should read this agreement with your guardian and use our services with the consent of your guardian." : 
                         "通过使用EasyHabit应用，您确认您已满16周岁并同意受到本协议的约束。如您未满16周岁，应在监护人陪同下阅读本协议，并在监护人同意的前提下使用我们的服务。")
                    
                    Text(habitStore.appLanguage == "en" ? "2. Service Description" : "2. 服务描述")
                        .font(.headline)
                    Text(habitStore.appLanguage == "en" ? 
                         "EasyHabit is an application that helps users record and cultivate habits. We provide users with habit tracking, statistics, and analysis functions to help users better manage their daily habits." : 
                         "EasyHabit是一款帮助用户记录和培养习惯的应用。我们为用户提供习惯追踪、统计和分析功能，帮助用户更好地管理自己的日常习惯。")
                    
                    Text(habitStore.appLanguage == "en" ? "3. User Behavior Standards" : "3. 用户行为规范")
                        .font(.headline)
                    Text(habitStore.appLanguage == "en" ? 
                         "You should comply with relevant laws and regulations of the People's Republic of China and must not use this application for illegal activities. You should be responsible for your use of this application, ensuring that the content you provide and publish is legal, true, and accurate, and does not infringe upon the legitimate rights and interests of any third party." : 
                         "您应遵守中华人民共和国相关法律法规，不得利用本应用从事违法活动。您应对使用本应用的行为负责，确保您提供和发布的内容合法、真实和准确，不侵犯任何第三方的合法权益。")
                    
                    Text(habitStore.appLanguage == "en" ? "4. Privacy Protection" : "4. 隐私保护")
                        .font(.headline)
                    Text(habitStore.appLanguage == "en" ? 
                         "We value user privacy protection. When you use our services, we may collect and use your relevant information. We will collect, use, store, and share your information in accordance with the \"EasyHabit Privacy Policy\"." : 
                         "我们重视用户的隐私保护，您在使用我们的服务时，我们可能收集和使用您的相关信息。我们将按照《EasyHabit隐私政策》收集、使用、存储和分享您的信息。")
                    
                    Text(habitStore.appLanguage == "en" ? "5. Intellectual Property" : "5. 知识产权")
                        .font(.headline)
                    Text(habitStore.appLanguage == "en" ? 
                         "The EasyHabit application and all its content, including but not limited to text, graphics, user interface, logos, icons, images, audio, and computer code, are protected by intellectual property laws, and these rights belong to us or our licensors." : 
                         "EasyHabit应用及其所有内容，包括但不限于文本、图形、用户界面、徽标、图标、图像、音频和计算机代码，均受知识产权法保护，这些权利归我们或我们的许可方所有。")
                }
                
                Group {
                    Text(habitStore.appLanguage == "en" ? "6. Disclaimer" : "6. 免责声明")
                        .font(.headline)
                    Text(habitStore.appLanguage == "en" ? 
                         "EasyHabit only provides habit tracking and management tools and is not responsible for any direct or indirect losses arising from users' use of this application. We do not guarantee that the service will meet your requirements, nor do we guarantee that the service will not be interrupted." : 
                         "EasyHabit仅提供习惯追踪和管理工具，不对用户因使用本应用而产生的任何直接或间接损失负责。我们不保证服务一定能满足您的要求，也不保证服务不会中断。")
                    
                    Text(habitStore.appLanguage == "en" ? "7. Agreement Modifications" : "7. 协议修改")
                        .font(.headline)
                    Text(habitStore.appLanguage == "en" ? 
                         "We reserve the right to modify this agreement at any time. Modifications to this agreement will be communicated to users through notifications published within the application or on the website. If you continue to use EasyHabit after the modification, it will be deemed that you have accepted the modified agreement." : 
                         "我们保留随时修改本协议的权利。对本协议的修改将通过在应用内或网站上发布通知的方式告知用户。若您在修改后继续使用EasyHabit，则视为您已接受修改后的协议。")
                    
                    Text(habitStore.appLanguage == "en" ? "8. Contact Us" : "8. 联系我们")
                        .font(.headline)
                    Text(habitStore.appLanguage == "en" ? 
                         "If you have any questions about this agreement or the EasyHabit application, please contact us through the \"User Feedback\" function in the application." : 
                         "如您对本协议或EasyHabit应用有任何问题，请通过应用中的\"用户反馈\"功能与我们联系。")
                    
                    Text(habitStore.appLanguage == "en" ? "Last updated: March 20, 2024" : "本协议更新日期：2024年3月20日")
                        .italic()
                        .padding(.top)
                }
            }
            .padding()
        }
        .navigationTitle(habitStore.appLanguage == "en" ? "Terms of Use" : "用户协议")
        .navigationBarTitleDisplayMode(.inline)
    }
} 