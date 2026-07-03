import SwiftUI

// Overlay global — popover ancorado estilo lib/widgets/anchored_select_menu.dart
@MainActor
@Observable
final class PopoverPresenter {
  static let shared = PopoverPresenter()

  var isPresented = false
  var anchorRect: CGRect = .zero
  var items: [PopoverMenuItem] = []
  var allowsToggle = false
  var preferAbove = false

  private var onSelectHandler: ((String?) -> Void)?

  init() {}

  func present(
    anchorRect: CGRect,
    items: [PopoverMenuItem],
    allowsToggle: Bool = false,
    preferAbove: Bool = false,
    onSelect: @escaping (String?) -> Void
  ) {
    let rect = anchorRect.isValidAnchor ? anchorRect : Self.fallbackAnchor(near: anchorRect)
    self.anchorRect = rect
    self.items = items
    self.allowsToggle = allowsToggle
    self.preferAbove = preferAbove
    onSelectHandler = onSelect
    isPresented = true
  }

  func present(
    anchor: CGPoint,
    items: [PopoverMenuItem],
    allowsToggle: Bool = false,
    preferAbove: Bool = false,
    onSelect: @escaping (String?) -> Void
  ) {
    present(
      anchorRect: CGRect(x: anchor.x - 22, y: anchor.y - 22, width: 44, height: 44),
      items: items,
      allowsToggle: allowsToggle,
      preferAbove: preferAbove,
      onSelect: onSelect
    )
  }

  func dismiss(_ value: String? = nil) {
    let handler = onSelectHandler
    isPresented = false
    items = []
    allowsToggle = false
    preferAbove = false
    onSelectHandler = nil
    handler?(value)
  }

  func toggleWithoutDismiss(_ value: String) {
    onSelectHandler?(value)
  }

  private static func fallbackAnchor(near rect: CGRect) -> CGRect {
    if rect.isValidAnchor { return rect }
    let screen = UIScreen.main.bounds
    return CGRect(x: screen.width - 56, y: max(100, rect.minY), width: 44, height: 44)
  }
}

struct PopoverOverlayHost: View {
  var presenter: PopoverPresenter = .shared
  var hostBounds: CGRect = .zero
  /// Deslocamento Y da âncora (sheet) para o espaço expandido do overlay local.
  var anchorYOffset: CGFloat = 0
  /// Sheet escopado: sempre abrir acima — não há espaço útil abaixo da âncora com teclado.
  var forcePreferAbove: Bool = false
  /// Quick Add: fundo opaco evita faixas do glass + scrim sobre o painel escuro.
  var opaquePopoverSurface: Bool = false

  @Bindable private var boundPresenter: PopoverPresenter
  @State private var keyboardHeight: CGFloat = 0

  init(
    presenter: PopoverPresenter = .shared,
    hostBounds: CGRect = .zero,
    anchorYOffset: CGFloat = 0,
    forcePreferAbove: Bool = false,
    opaquePopoverSurface: Bool = false
  ) {
    self.presenter = presenter
    self.hostBounds = hostBounds
    self.anchorYOffset = anchorYOffset
    self.forcePreferAbove = forcePreferAbove
    self.opaquePopoverSurface = opaquePopoverSurface
    _boundPresenter = Bindable(presenter)
  }

  var body: some View {
    ZStack {
      if boundPresenter.isPresented {
        StackedPopoverOverlay(
          anchorRect: boundPresenter.anchorRect,
          keyboardHeight: keyboardHeight,
          hostBounds: resolvedHostBounds,
          anchorYOffset: anchorYOffset,
          forcePreferAbove: forcePreferAbove,
          opaqueSurface: opaquePopoverSurface,
          preferAbove: boundPresenter.preferAbove,
          rootItems: boundPresenter.items,
          allowsToggle: boundPresenter.allowsToggle
        ) { value in
          boundPresenter.dismiss(value)
        } onToggle: { value in
          boundPresenter.toggleWithoutDismiss(value)
        }
        .environment(ThemeManager.shared)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .zIndex(9999)
      }
    }
    .allowsHitTesting(boundPresenter.isPresented)
    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
      updateKeyboardHeight(from: note)
    }
    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { note in
      updateKeyboardHeight(from: note)
    }
    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
      keyboardHeight = 0
    }
  }

  private var resolvedHostBounds: CGRect {
    if hostBounds.width > 1, hostBounds.height > 1 {
      return hostBounds
    }
    return ScreenMetrics.bounds
  }

  private func updateKeyboardHeight(from note: Notification) {
    guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
    let screenH = ScreenMetrics.bounds.height
    keyboardHeight = max(0, screenH - frame.origin.y)
  }
}

extension CGRect {
  var isValidAnchor: Bool { width > 1 && height > 1 }
}
