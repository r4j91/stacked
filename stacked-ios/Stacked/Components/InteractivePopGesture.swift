import SwiftUI
import UIKit

/// Reabilita o swipe da borda esquerda quando o voltar nativo está oculto
/// (`navigationBarBackButtonHidden(true)` desliga o gesto no UINavigationController).
struct InteractivePopGestureEnabler: UIViewControllerRepresentable {
  func makeCoordinator() -> Coordinator { Coordinator() }

  func makeUIViewController(context: Context) -> UIViewController {
    let controller = PopGestureHostViewController()
    controller.coordinator = context.coordinator
    return controller
  }

  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    (uiViewController as? PopGestureHostViewController)?.coordinator = context.coordinator
    if let host = uiViewController as? PopGestureHostViewController {
      context.coordinator.enablePopGesture(for: host)
    }
  }

  final class Coordinator: NSObject, UIGestureRecognizerDelegate {
    private weak var navigationController: UINavigationController?

    func enablePopGesture(for viewController: UIViewController) {
      guard let navigationController = viewController.navigationController else { return }
      self.navigationController = navigationController
      guard navigationController.viewControllers.count > 1 else { return }
      navigationController.interactivePopGestureRecognizer?.isEnabled = true
      navigationController.interactivePopGestureRecognizer?.delegate = self
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
      guard gestureRecognizer === navigationController?.interactivePopGestureRecognizer else {
        return true
      }
      return (navigationController?.viewControllers.count ?? 0) > 1
    }
  }
}

private final class PopGestureHostViewController: UIViewController {
  weak var coordinator: InteractivePopGestureEnabler.Coordinator?

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    coordinator?.enablePopGesture(for: self)
  }
}
