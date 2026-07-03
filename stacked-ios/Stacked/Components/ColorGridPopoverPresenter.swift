import SwiftUI

@MainActor
@Observable
final class ColorGridPopoverPresenter {
  static let shared = ColorGridPopoverPresenter()

  var isPresented = false
  var anchorRect: CGRect = .zero
  var selectedHex: String = PaletteColors.defaultHex

  private var onSelectHandler: ((String) -> Void)?
  private var onCloseHandler: (() -> Void)?

  private init() {}

  func present(
    anchorRect: CGRect,
    selectedHex: String,
    onSelect: @escaping (String) -> Void,
    onClose: (() -> Void)? = nil
  ) {
    let rect = anchorRect.isValidAnchor ? anchorRect : Self.fallbackAnchor(near: anchorRect)
    self.anchorRect = rect
    self.selectedHex = selectedHex
    onSelectHandler = onSelect
    onCloseHandler = onClose
    isPresented = true
    WindowPopoverOverlayManager.shared.refreshIfNeeded()
  }

  func dismiss(selected: String? = nil) {
    let selectHandler = onSelectHandler
    let closeHandler = onCloseHandler
    isPresented = false
    anchorRect = .zero
    onSelectHandler = nil
    onCloseHandler = nil
    WindowPopoverOverlayManager.shared.refreshIfNeeded()
    if let selected { selectHandler?(selected) }
    closeHandler?()
  }

  private static func fallbackAnchor(near rect: CGRect) -> CGRect {
    if rect.isValidAnchor { return rect }
    let screen = ScreenMetrics.bounds
    return CGRect(x: screen.midX - 22, y: screen.midY - 22, width: 44, height: 44)
  }
}

/// Mantém overlay de grid de cores na janela (Quick Add / Novo projeto).
struct ColorGridWindowOverlayHost: View {
  @Bindable var presenter: ColorGridPopoverPresenter

  var body: some View {
    Color.clear
      .frame(width: 0, height: 0)
      .onAppear {
        WindowPopoverOverlayManager.shared.attachColorGrid(presenter: presenter)
      }
      .onDisappear {
        WindowPopoverOverlayManager.shared.detachColorGrid()
      }
      .onChange(of: presenter.isPresented) { _, _ in
        WindowPopoverOverlayManager.shared.refreshIfNeeded()
      }
  }
}
