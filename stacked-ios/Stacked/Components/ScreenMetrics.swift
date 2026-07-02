import SwiftUI
import UIKit

@MainActor
enum ScreenMetrics {
  static var keyWindow: UIWindow? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)
  }

  static var bounds: CGRect {
    keyWindow?.bounds ?? UIScreen.main.bounds
  }
}

/// Lê o frame do botão convertido para coordenadas da tela (correto dentro de .sheet).
struct ScreenBoundsReader: UIViewRepresentable {
  @Binding var rect: CGRect

  func makeUIView(context: Context) -> ScreenBoundsCaptureView {
    let view = ScreenBoundsCaptureView()
    view.onUpdate = { rect = $0 }
    return view
  }

  func updateUIView(_ uiView: ScreenBoundsCaptureView, context: Context) {
    uiView.onUpdate = { rect = $0 }
    uiView.capture()
  }
}

final class ScreenBoundsCaptureView: UIView {
  var onUpdate: ((CGRect) -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = false
    backgroundColor = .clear
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  override func layoutSubviews() {
    super.layoutSubviews()
    capture()
  }

  func capture() {
    guard let window else { return }
    let inWindow = convert(bounds, to: window)
    onUpdate?(window.convert(inWindow, to: nil))
  }
}
