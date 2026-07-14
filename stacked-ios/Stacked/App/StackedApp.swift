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
              .environment(MobileChromeController.shared)
          }
        }
    }
    .syncWindowBackground(themeManager.colors.background)
    .onAppear { HapticService.prepare() }
    .task {
      await MainActor.run {
        IconCache.shared.warmUp()
      }
    } // AJUSTADO_ICONCACHE_WARMUP
    .onOpenURL { AppNavigationRouter.shared.handle(url: $0) }
  }
}
