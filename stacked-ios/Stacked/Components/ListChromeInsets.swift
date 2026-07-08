import SwiftUI

// Paridade lib/theme/app_layout.dart bottomListInset / homeDockBottomInset
extension AppLayout {
  static func totalBottomChromeHeight(safeBottom: CGFloat) -> CGFloat {
    safeBottom + bottomNavPillMargin + bottomNavPillHeight + fabGap + fabSize
  }

  static func listTailInset(safeBottom: CGFloat) -> CGFloat {
    totalBottomChromeHeight(safeBottom: safeBottom) + 8
  }

  /// Safe area inferior da janela ativa — mesma fonte usada pelo MobileShell.
  static var windowSafeBottomInset: CGFloat {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)?
      .safeAreaInsets.bottom ?? 0
  }
}

struct ListTailSpacer: View {
  private static let cachedSafeBottom: CGFloat = {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)?
      .safeAreaInsets.bottom ?? 0
  }()

  var body: some View {
    Color.clear
      .frame(height: AppLayout.listTailInset(safeBottom: Self.cachedSafeBottom))
  }
}

extension View {
  /// iOS 26 — remove fade/blur tardio nas bordas do scroll (`.soft` padrão do sistema).
  /// `.hard` = corte limpo no topo e na base (dock customizado, sem fade atrasado).
  func stackedScrollEdgeChrome() -> some View {
    self
      .scrollEdgeEffectStyle(.hard, for: .top)
      .scrollEdgeEffectStyle(.hard, for: .bottom)
  }

  /// Padding inferior para listas — paridade bottomListInset (sem duplicar ListTailSpacer).
  func stackedListTailInset() -> some View {
    safeAreaPadding(
      .bottom,
      AppLayout.fabSize + AppLayout.fabGap + AppLayout.bottomNavPillHeight + AppLayout.bottomNavPillMargin + 8
    )
    .stackedScrollEdgeChrome()
  }

  /// Dashboard — só borda inferior; sem `.hard` no topo (evita tarja no push do drill-down).
  func stackedDashboardListChrome() -> some View {
    safeAreaPadding(
      .bottom,
      AppLayout.fabSize + AppLayout.fabGap + AppLayout.bottomNavPillHeight + AppLayout.bottomNavPillMargin + 8
    )
    .scrollEdgeEffectStyle(.hard, for: .bottom)
  }

  /// Adia labels/async pesados nas TaskRows até após o primeiro frame — scroll inicial mais leve.
  func stackedListRowWorkGate(_ allowHeavyWork: Binding<Bool>) -> some View {
    task {
      guard !allowHeavyWork.wrappedValue else { return }
      try? await _Concurrency.Task.sleep(for: .milliseconds(150))
      guard !_Concurrency.Task.isCancelled else { return }
      allowHeavyWork.wrappedValue = true
    }
  }

  /// Drill-down — corte limpo no topo (iOS 26 scroll edge) + inset inferior do dock.
  func stackedDrillDownListChrome() -> some View {
    safeAreaPadding(
      .bottom,
      AppLayout.fabSize + AppLayout.fabGap + AppLayout.bottomNavPillHeight + AppLayout.bottomNavPillMargin + 8
    )
    .scrollEdgeEffectStyle(.hard, for: .top)
    .scrollEdgeEffectStyle(.hard, for: .bottom)
  }
}
