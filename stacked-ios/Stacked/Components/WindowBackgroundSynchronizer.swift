import SwiftUI
import UIKit

/// Sincroniza UIWindow.backgroundColor do app — evita cantos pretos (#000) atrás do teclado.
/// Só altera a janela principal (.normal); nunca overlay de popover.
struct WindowBackgroundSynchronizer: UIViewControllerRepresentable {
  let color: Color

  func makeUIViewController(context: Context) -> Controller {
    Controller()
  }

  func updateUIViewController(_ controller: Controller, context: Context) {
    controller.apply(color: UIColor(color))
  }

  final class Controller: UIViewController {
    private var pendingColor: UIColor?

    override func viewDidLoad() {
      super.viewDidLoad()
      view.isUserInteractionEnabled = false
      view.backgroundColor = .clear
    }

    override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()
      if let pendingColor {
        paintMainWindow(with: pendingColor)
      }
    }

    func apply(color: UIColor) {
      pendingColor = color
      paintMainWindow(with: color)
    }

    private func paintMainWindow(with color: UIColor) {
      let window = view.window
        ?? UIApplication.shared.connectedScenes
          .compactMap { $0 as? UIWindowScene }
          .flatMap(\.windows)
          .first(where: { $0.isKeyWindow && $0.windowLevel == .normal })
      guard let window else { return }
      window.backgroundColor = color
    }
  }
}

extension View {
  func syncWindowBackground(_ color: Color) -> some View {
    background(WindowBackgroundSynchronizer(color: color))
  }
}
