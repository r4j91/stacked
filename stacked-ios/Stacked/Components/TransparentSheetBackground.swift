import SwiftUI
import UIKit

/// Remove chrome retangular do `.sheet` — deixa só o conteúdo (cápsula) visível.
struct TransparentSheetBackground: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> Controller {
    Controller()
  }

  func updateUIViewController(_ uiViewController: Controller, context: Context) {
    uiViewController.apply()
  }

  final class Controller: UIViewController {
    override func viewDidLoad() {
      super.viewDidLoad()
      view.backgroundColor = .clear
      view.isOpaque = false
    }

    override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()
      apply()
    }

    func apply() {
      view.backgroundColor = .clear
      view.isOpaque = false

      presentationController?.containerView?.backgroundColor = .clear

      if let sheet = presentationController as? UISheetPresentationController {
        sheet.prefersGrabberVisible = false
        if #available(iOS 16.0, *), let id = sheet.detents.first?.identifier {
          sheet.largestUndimmedDetentIdentifier = id
        }
      }

      var current: UIView? = view
      while let layer = current {
        let typeName = String(describing: type(of: layer))
        if typeName.contains("Dimming")
          || typeName.contains("_UISheet")
          || typeName.contains("Presentation")
          || typeName.contains("UIDropShadow")
        {
          layer.backgroundColor = .clear
          layer.isOpaque = false
          if typeName.contains("Dimming") {
            layer.alpha = 0
          }
        }
        current = layer.superview
      }
    }
  }
}

extension View {
  func transparentSheetChrome() -> some View {
    background(TransparentSheetBackground())
  }
}
