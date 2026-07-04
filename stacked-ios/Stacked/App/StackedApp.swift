import SwiftUI

@main
struct StackedApp: App {
  @UIApplicationDelegateAdaptor(AppOrientationDelegate.self) private var appOrientation

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
    ZStack {
      themeManager.colors.background
        .ignoresSafeArea(.all)

      AuthGateView()
        .environment(themeManager)
        .preferredColorScheme(themeManager.colors.isDark ? .dark : .light)
        .overlay {
          if popover.isPresented {
            PopoverOverlayHost()
          }
        }
    }
    .syncWindowBackground(themeManager.colors.background)
    .onAppear { HapticService.prepare() }
    .onOpenURL { AppNavigationRouter.shared.handle(url: $0) }
  }
}
