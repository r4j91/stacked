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

  var body: some View {
    AuthGateView()
      .environment(themeManager)
      .preferredColorScheme(themeManager.colors.isDark ? .dark : .light)
      .overlay {
        if popover.isPresented {
          PopoverOverlayHost()
        }
      }
      .onAppear { HapticService.prepare() }
      .onOpenURL { AppNavigationRouter.shared.handle(url: $0) }
  }
}
