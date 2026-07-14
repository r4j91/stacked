import SwiftUI
import UIKit

/// Popover acima do Quick Add — janela separada só enquanto um menu está aberto.
@MainActor
final class WindowPopoverOverlayManager {
  static let shared = WindowPopoverOverlayManager()

  private var overlayWindow: PopoverPassthroughWindow?
  private weak var attachedPresenter: PopoverPresenter?
  private weak var attachedColorGridPresenter: ColorGridPopoverPresenter?
  private var popoverForcePreferAbove = true

  private init() {}

  func attach(presenter: PopoverPresenter, forcePreferAbove: Bool = true) {
    attachedPresenter = presenter
    popoverForcePreferAbove = forcePreferAbove
    syncWindowVisibility()
  }

  func detach() {
    attachedPresenter = nil
    popoverForcePreferAbove = true
    syncWindowVisibility()
  }

  func attachColorGrid(presenter: ColorGridPopoverPresenter) {
    attachedColorGridPresenter = presenter
    syncWindowVisibility()
  }

  func detachColorGrid() {
    attachedColorGridPresenter = nil
    syncWindowVisibility()
  }

  func refreshIfNeeded() {
    syncWindowVisibility()
  }

  private func syncWindowVisibility() {
    let popoverActive = attachedPresenter?.isPresented == true
    let colorGridActive = attachedColorGridPresenter?.isPresented == true
    guard popoverActive || colorGridActive else {
      hideWindow()
      return
    }
    ensureWindow()
    refreshRootView()
  }

  private func ensureWindow() {
    guard overlayWindow == nil else { return }
    guard
      let scene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first(where: { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive })
        ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
    else { return }

    let window = PopoverPassthroughWindow(windowScene: scene)
    window.windowLevel = .alert + 1
    window.backgroundColor = .clear
    window.isOpaque = false
    window.isHidden = false
    overlayWindow = window
  }

  private func hideWindow() {
    overlayWindow?.isHidden = true
    overlayWindow?.rootViewController = nil
    overlayWindow = nil
  }

  private func refreshRootView() {
    let popoverActive = attachedPresenter?.isPresented == true
    let colorGridActive = attachedColorGridPresenter?.isPresented == true
    guard popoverActive || colorGridActive else {
      hideWindow()
      return
    }

    ensureWindow()
    guard let window = overlayWindow else { return }

    window.backgroundColor = .clear
    window.isOpaque = false
    window.presenterIsActive = { [weak self] in
      guard let self else { return false }
      return attachedPresenter?.isPresented == true || attachedColorGridPresenter?.isPresented == true
    }

    let root = ZStack {
      if colorGridActive, let colorPresenter = attachedColorGridPresenter {
        ProjectColorGridPopoverOverlay(
          anchorRect: colorPresenter.anchorRect,
          selectedHex: colorPresenter.selectedHex,
          hostBounds: ScreenMetrics.bounds,
          onSelect: { colorPresenter.dismiss(selected: $0) },
          onDismiss: { colorPresenter.dismiss() }
        )
        .environment(ThemeManager.shared)
        .environment(MobileChromeController.shared)
      }
      if popoverActive, let presenter = attachedPresenter {
        PopoverOverlayHost(
          presenter: presenter,
          hostBounds: ScreenMetrics.bounds,
          forcePreferAbove: popoverForcePreferAbove,
          opaquePopoverSurface: true
        )
        .environment(ThemeManager.shared)
        .environment(MobileChromeController.shared)
      }
    }
    .ignoresSafeArea()

    if let host = window.rootViewController as? UIHostingController<AnyView> {
      host.rootView = AnyView(root)
      host.view.backgroundColor = .clear
    } else {
      let host = UIHostingController(rootView: AnyView(root))
      host.view.backgroundColor = .clear
      host.view.isOpaque = false
      window.rootViewController = host
    }
  }
}

private final class PopoverPassthroughWindow: UIWindow {
  var presenterIsActive: (() -> Bool)?

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    guard presenterIsActive?() == true else { return nil }
    return super.hitTest(point, with: event)
  }
}

/// Mantém overlay de popover na janela enquanto Quick Add está aberto.
struct QuickAddWindowPopoverHost: View {
  @Bindable var presenter: PopoverPresenter
  var forcePreferAbove: Bool = true

  var body: some View {
    Color.clear
      .frame(width: 0, height: 0)
      .onAppear {
        WindowPopoverOverlayManager.shared.attach(
          presenter: presenter,
          forcePreferAbove: forcePreferAbove
        )
      }
      .onDisappear {
        WindowPopoverOverlayManager.shared.detach()
      }
      .onChange(of: presenter.isPresented) { _, _ in
        WindowPopoverOverlayManager.shared.refreshIfNeeded()
      }
  }
}
