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

/// Overlay UIKit que captura frame de tela no toque (confiável dentro de .sheet).
struct ScreenAnchorTapOverlay: UIViewRepresentable {
  let onTap: (CGRect) -> Void

  func makeUIView(context: Context) -> ScreenAnchorTapView {
    let view = ScreenAnchorTapView()
    view.onTap = onTap
    return view
  }

  func updateUIView(_ uiView: ScreenAnchorTapView, context: Context) {
    uiView.onTap = onTap
  }
}

final class ScreenAnchorTapView: UIView {
  var onTap: ((CGRect) -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    isUserInteractionEnabled = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    guard let touch = touches.first, touch.tapCount == 1 else { return }
    guard bounds.width > 1, bounds.height > 1 else { return }
    onTap?(convert(bounds, to: nil))
  }
}

/// Legado — preferir ScreenAnchorTapOverlay para toques em sheet.
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
  /// Quando `false`, só captura via `capture()` explícito (scroll não dispara @State).
  var autoCaptureOnLayout = true
  private var lastReportedRect: CGRect?

  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = false
    backgroundColor = .clear
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  override func layoutSubviews() {
    super.layoutSubviews()
    if autoCaptureOnLayout { capture() }
  }

  func capture() {
    guard let window else { return }
    let inWindow = convert(bounds, to: window)
    let rect = window.convert(inWindow, to: nil)
    guard rect.width > 1, rect.height > 1 else { return }
    if let last = lastReportedRect, last.equalTo(rect) { return }
    lastReportedRect = rect
    onUpdate?(rect)
  }
}

/// Captura frame de tela sob demanda — evita UIView → @State em cada frame de scroll.
struct OnDemandScreenBoundsReader: UIViewRepresentable {
  let captureGeneration: Int
  @Binding var rect: CGRect

  final class Coordinator {
    var lastGeneration = -1
  }

  func makeCoordinator() -> Coordinator { Coordinator() }

  func makeUIView(context: Context) -> ScreenBoundsCaptureView {
    let view = ScreenBoundsCaptureView()
    view.autoCaptureOnLayout = false
    return view
  }

  func updateUIView(_ uiView: ScreenBoundsCaptureView, context: Context) {
    guard captureGeneration != context.coordinator.lastGeneration else { return }
    context.coordinator.lastGeneration = captureGeneration
    uiView.onUpdate = { rect = $0 }
    uiView.capture()
  }
}
