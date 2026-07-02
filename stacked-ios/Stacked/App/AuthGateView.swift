import SwiftUI

// Paridade lib/main.dart _AuthGate
struct AuthGateView: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var auth = AuthManager.shared

  var body: some View {
    Group {
      if auth.isLoading && auth.session == nil {
        loadingView
      } else if auth.isAuthenticated {
        RootView()
          .environment(MobileChromeController.shared)
      } else {
        AuthView()
      }
    }
    // SUBSTITUIDO_FASE2: .animation(.easeInOut(duration: 0.2), value: auth.isAuthenticated)
    .animation(AppMotion.smooth(reduceMotion: reduceMotion), value: auth.isAuthenticated)
  }

  private var loadingView: some View {
    ZStack {
      theme.colors.background.ignoresSafeArea()
      ProgressView()
        .tint(theme.colors.accent)
    }
  }
}
