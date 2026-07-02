import SwiftUI

@main
struct StackedApp: App {
  @State private var themeManager = ThemeManager.shared

  var body: some Scene {
    WindowGroup {
      AuthGateView()
        .environment(themeManager)
        .preferredColorScheme(themeManager.colors.isDark ? .dark : .light)
        .overlay { PopoverOverlayGate().zIndex(99_999) }
        .onAppear { HapticService.prepare() }
        .onOpenURL { AppNavigationRouter.shared.handle(url: $0) }
    }
  }
}
