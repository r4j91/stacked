import SwiftUI
import UIKit

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
    .onAppear {
      UIKitTaskListStorage.registerDefaultsIfNeeded()
      ChromeGlassModeStorage.migrateIfNeeded()
      HomeHeroStyleStorage.migrateRetiredSelectionIfNeeded()
      HapticService.prepare()
    }
    .task {
      await MainActor.run {
        IconCache.shared.warmUp()
        let colors = ThemeManager.shared.colors
        let tertiary = UIColor(colors.textTertiary)
        UIKitRowIconRaster.warmCommon(
          textTertiary: tertiary,
          accent: UIColor(colors.accent)
        )
        for done in [false, true] {
          _ = DoneCircleRaster.image(
            done: done,
            size: DoneCircle.listRowCircleSize,
            borderWidth: DoneCircle.RingStyle.borderWidth,
            ringColor: tertiary,
            ringFillAlpha: done ? 0 : DoneCircle.RingStyle.inactiveFillAlpha,
            tickSize: 13
          )
        }
        for priority in Priority.allCases {
          _ = DoneCircleRaster.image(
            done: false,
            size: DoneCircle.listRowCircleSize,
            borderWidth: DoneCircle.RingStyle.borderWidth,
            ringColor: UIColor(priority.color),
            ringFillAlpha: DoneCircle.RingStyle.inactiveFillAlpha,
            tickSize: 13
          )
        }
      }
    }
    .onOpenURL { AppNavigationRouter.shared.handle(url: $0) }
  }
}
