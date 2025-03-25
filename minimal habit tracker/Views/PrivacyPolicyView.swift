import SwiftUI

// 隐私政策视图
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("隐私政策")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom)
                
                Group {
                    Text("EasyHabit隐私政策")
                        .font(.title2)
                        .bold()
                    
                    Text("本隐私政策旨在帮助您了解我们如何收集、使用、存储和共享您的个人信息，以及您享有的相关权利。在使用EasyHabit应用前，请您仔细阅读并了解本隐私政策的全部内容。")
                    
                    Text("1. 我们收集的信息")
                        .font(.headline)
                    Text("• 您提供的信息：当您使用EasyHabit应用时，您可能会创建习惯记录、设置提醒等，这些信息将被存储在您的设备上。\n• 设备信息：我们可能会收集您使用的设备型号、操作系统版本等基本信息，用于改进应用性能。\n• 应用使用数据：我们可能会收集您如何使用应用的信息，例如功能使用频率、应用崩溃记录等，用于优化用户体验。")
                    
                    Text("2. 信息的使用")
                        .font(.headline)
                    Text("我们使用收集的信息来：\n• 提供、维护和改进EasyHabit应用的功能和服务\n• 开发新功能和服务\n• 了解用户如何使用我们的应用，以改进用户体验\n• 向您发送有关应用更新或新功能的通知")
                    
                    Text("3. 信息的存储")
                        .font(.headline)
                    Text("我们采取以下措施保护您的信息安全：\n• 您的习惯数据主要存储在您的设备上\n• 如果您启用了云同步功能（高级版本），您的数据会加密存储在云服务上\n• 我们采取合理的技术措施保护您的数据不被未经授权的访问")
                }
                
                Group {
                    Text("4. 信息共享")
                        .font(.headline)
                    Text("除非有下列情况，我们不会与任何第三方分享您的个人信息：\n• 在法律要求下必须披露\n• 为了保护EasyHabit的合法权益\n• 获得您的明确同意")
                    
                    Text("5. 您的权利")
                        .font(.headline)
                    Text("您对自己的个人信息拥有以下权利：\n• 访问您的个人信息\n• 删除应用内所有数据\n• 导出您的数据\n• 随时停止使用我们的服务")
                    
                    Text("6. 儿童隐私")
                        .font(.headline)
                    Text("EasyHabit应用不面向16岁以下的儿童。如果您是父母或监护人，发现您的孩子未经您的同意向我们提供了个人信息，请通过应用内的\"用户反馈\"功能联系我们。")
                    
                    Text("7. 隐私政策更新")
                        .font(.headline)
                    Text("我们可能会不时更新本隐私政策。当我们进行重大更改时，我们会在应用内通知您。您继续使用应用将视为您接受修改后的隐私政策。")
                    
                    Text("8. 联系我们")
                        .font(.headline)
                    Text("如果您对本隐私政策有任何疑问，请通过应用中的\"用户反馈\"功能与我们联系。")
                    
                    Text("本隐私政策更新日期：2024年3月20日")
                        .italic()
                        .padding(.top)
                }
            }
            .padding()
        }
        .navigationTitle("隐私政策")
        .navigationBarTitleDisplayMode(.inline)
    }
} 