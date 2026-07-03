import SwiftUI
import UIKit

/// Popover acima do Quick Add — janela separada só enquanto um menu está aberto.
@MainActor
final class WindowPopoverOverlayManager {
  static let shared = WindowPopoverOverlayManager()

  private var overlayWindow: PopoverPassthroughWindow?
  private weak var attachedPresenter: PopoverPresenter?

  private init() {}

  func attach(presenter: PopoverPresenter) {
    attachedPresenter = presenter
    syncWindowVisibility()
  }

  func detach() {
    attachedPresenter = nil
    hideWindow()
  }

  func refreshIfNeeded() {
    syncWindowVisibility()
  }

  private func syncWindowVisibility() {
    guard let presenter = attachedPresenter, presenter.isPresented else {
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
    guard let presenter = attachedPresenter, presenter.isPresented else {
      hideWindow()
      return
    }

    ensureWindow()
    guard let window = overlayWindow else { return }

    window.backgroundColor = .clear
    window.isOpaque = false
    window.presenterIsActive = { [weak presenter] in
      presenter?.isPresented ?? false
    }

    let root = PopoverOverlayHost(
      presenter: presenter,
      hostBounds: ScreenMetrics.bounds,
      forcePreferAbove: true,
      opaquePopoverSurface: true
    )
    .environment(ThemeManager.shared)
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

  var body: some View {
    Color.clear
      .frame(width: 0, height: 0)
      .onAppear {
        WindowPopoverOverlayManager.shared.attach(presenter: presenter)
      }
      .onDisappear {
        WindowPopoverOverlayManager.shared.detach()
      }
      .onChange(of: presenter.isPresented) { _, _ in
        WindowPopoverOverlayManager.shared.refreshIfNeeded()
      }
  }
}
