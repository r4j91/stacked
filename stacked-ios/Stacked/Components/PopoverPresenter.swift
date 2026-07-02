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

  private var onSelectHandler: ((String?) -> Void)?

  func present(
    anchorRect: CGRect,
    items: [PopoverMenuItem],
    allowsToggle: Bool = false,
    onSelect: @escaping (String?) -> Void
  ) {
    let rect = anchorRect.isValidAnchor ? anchorRect : Self.fallbackAnchor(near: anchorRect)
    self.anchorRect = rect
    self.items = items
    self.allowsToggle = allowsToggle
    onSelectHandler = onSelect
    isPresented = true
  }

  func present(
    anchor: CGPoint,
    items: [PopoverMenuItem],
    allowsToggle: Bool = false,
    onSelect: @escaping (String?) -> Void
  ) {
    present(
      anchorRect: CGRect(x: anchor.x - 22, y: anchor.y - 22, width: 44, height: 44),
      items: items,
      allowsToggle: allowsToggle,
      onSelect: onSelect
    )
  }

  func dismiss(_ value: String? = nil) {
    let handler = onSelectHandler
    isPresented = false
    items = []
    allowsToggle = false
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
  @Bindable private var presenter = PopoverPresenter.shared
  @State private var keyboardHeight: CGFloat = 0

  var body: some View {
    ZStack {
      if presenter.isPresented {
        StackedPopoverOverlay(
          anchorRect: presenter.anchorRect,
          keyboardHeight: keyboardHeight,
          rootItems: presenter.items,
          allowsToggle: presenter.allowsToggle
        ) { value in
          presenter.dismiss(value)
        } onToggle: { value in
          presenter.toggleWithoutDismiss(value)
        }
        .environment(ThemeManager.shared)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .zIndex(9999)
      }
    }
    .allowsHitTesting(presenter.isPresented)
    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
      guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
      let screenH = UIScreen.main.bounds.height
      keyboardHeight = max(0, screenH - frame.origin.y)
    }
  }
}

extension CGRect {
  var isValidAnchor: Bool { width > 1 && height > 1 }
}
