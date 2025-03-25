import SwiftUI
import UIKit

// 添加支持系统侧滑返回手势的扩展
extension View {
    // 简化为一个统一的方法
    func enableSwipeBack() -> some View {
        self.modifier(SwipeBackModifier())
    }
    
    // 添加主题色透明度扩展
    func primaryWithOpacity(colorScheme: ColorScheme) -> some View {
        self.foregroundColor(colorScheme == .dark ? .primary.opacity(0.8) : .primary)
    }
}

struct SwipeBackModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(SwipeBackHelper())
    }
}

struct SwipeBackHelper: UIViewControllerRepresentable {
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let navController = uiViewController.navigationController {
            navController.interactivePopGestureRecognizer?.isEnabled = true
            navController.interactivePopGestureRecognizer?.delegate = context.coordinator
        }
    }
}

extension UINavigationController {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = nil
        interactivePopGestureRecognizer?.isEnabled = true
    }
} 