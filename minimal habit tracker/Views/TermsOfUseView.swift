import SwiftUI

// 用户协议视图
struct TermsOfUseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("用户协议")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom)
                
                Group {
                    Text("欢迎使用EasyHabit应用")
                        .font(.title2)
                        .bold()
                    
                    Text("本协议是您与EasyHabit（下称\"我们\"）之间关于您使用EasyHabit应用及相关服务的协议。在您开始使用EasyHabit应用之前，请您务必认真阅读并充分理解本协议的全部内容。")
                    
                    Text("1. 接受条款")
                        .font(.headline)
                    Text("通过使用EasyHabit应用，您确认您已满16周岁并同意受到本协议的约束。如您未满16周岁，应在监护人陪同下阅读本协议，并在监护人同意的前提下使用我们的服务。")
                    
                    Text("2. 服务描述")
                        .font(.headline)
                    Text("EasyHabit是一款帮助用户记录和培养习惯的应用。我们为用户提供习惯追踪、统计和分析功能，帮助用户更好地管理自己的日常习惯。")
                    
                    Text("3. 用户行为规范")
                        .font(.headline)
                    Text("您应遵守中华人民共和国相关法律法规，不得利用本应用从事违法活动。您应对使用本应用的行为负责，确保您提供和发布的内容合法、真实和准确，不侵犯任何第三方的合法权益。")
                    
                    Text("4. 隐私保护")
                        .font(.headline)
                    Text("我们重视用户的隐私保护，您在使用我们的服务时，我们可能收集和使用您的相关信息。我们将按照《EasyHabit隐私政策》收集、使用、存储和分享您的信息。")
                    
                    Text("5. 知识产权")
                        .font(.headline)
                    Text("EasyHabit应用及其所有内容，包括但不限于文本、图形、用户界面、徽标、图标、图像、音频和计算机代码，均受知识产权法保护，这些权利归我们或我们的许可方所有。")
                }
                
                Group {
                    Text("6. 免责声明")
                        .font(.headline)
                    Text("EasyHabit仅提供习惯追踪和管理工具，不对用户因使用本应用而产生的任何直接或间接损失负责。我们不保证服务一定能满足您的要求，也不保证服务不会中断。")
                    
                    Text("7. 协议修改")
                        .font(.headline)
                    Text("我们保留随时修改本协议的权利。对本协议的修改将通过在应用内或网站上发布通知的方式告知用户。若您在修改后继续使用EasyHabit，则视为您已接受修改后的协议。")
                    
                    Text("8. 联系我们")
                        .font(.headline)
                    Text("如您对本协议或EasyHabit应用有任何问题，请通过应用中的\"用户反馈\"功能与我们联系。")
                    
                    Text("本协议更新日期：2024年3月20日")
                        .italic()
                        .padding(.top)
                }
            }
            .padding()
        }
        .navigationTitle("用户协议")
        .navigationBarTitleDisplayMode(.inline)
    }
} 