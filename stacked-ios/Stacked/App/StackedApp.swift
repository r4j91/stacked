import SwiftUI

@main
struct StackedApp: App {
  var body: some Scene {
    WindowGroup {
      AppRootView()
    }
  }
}

private struct AppRootView: View {
  @State private var themeManager = ThemeManager.shared
  @Bindable private var popover = PopoverPresenter.shared
  @Bindable private var windowPopover = WindowPopoverCoordinator.shared

  var body: some View {
    AuthGateView()
      .environment(themeManager)
      .preferredColorScheme(themeManager.colors.isDark ? .dark : .light)
      .overlay {
        if let sheetPresenter = windowPopover.presenter {
          WindowSheetPopoverLayer(presenter: sheetPresenter)
        } else if popover.isPresented {
          PopoverOverlayHost()
        }
      }
      .onAppear { HapticService.prepare() }
      .onOpenURL { AppNavigationRouter.shared.handle(url: $0) }
  }
}

/// Observa isPresented do presenter escopado ao Quick Add sheet.
private struct WindowSheetPopoverLayer: View {
  @Bindable var presenter: PopoverPresenter

  var body: some View {
    if presenter.isPresented {
      PopoverOverlayHost(
        presenter: presenter,
        hostBounds: ScreenMetrics.bounds,
        forcePreferAbove: true
      )
    }
  }
}
