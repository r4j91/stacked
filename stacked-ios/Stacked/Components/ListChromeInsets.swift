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

  /// Cache — evita enumerar UIWindows a cada body do `ListTailSpacer` durante o scroll.
  private static var _cachedSafeBottom: CGFloat?
  static var windowSafeBottomInsetCached: CGFloat {
    if let cached = _cachedSafeBottom { return cached }
    let value = windowSafeBottomInset
    _cachedSafeBottom = value
    return value
  }

  static func refreshSafeBottomCache() {
    _cachedSafeBottom = windowSafeBottomInset
  }
}

struct ListTailSpacer: View {
  var body: some View {
    Color.clear
      .frame(height: AppLayout.listTailInset(safeBottom: AppLayout.windowSafeBottomInsetCached))
  }
}

extension View {
  /// UIKit lists — sem scrollEdgeEffect no wrapper (hard = tarja; soft = hitch).
  /// Edge effects ficam desligados no `UICollectionView`; só reporta scroll pro dock glass.
  func stackedScrollEdgeChrome() -> some View {
    self.stackedReportListScrollForDockGlass()
  }

  /// Padding inferior para listas — paridade bottomListInset (sem duplicar ListTailSpacer).
  /// Só `.hard` na base: `.hard` no topo (iOS 26) “arma” no 1º drag e desloca o texto.
  /// Mesmo padrão do dashboard — abas Hoje/Inbox/Em breve ficam estáveis no início do scroll.
  func stackedListTailInset() -> some View {
    safeAreaPadding(
      .bottom,
      AppLayout.fabSize + AppLayout.fabGap + AppLayout.bottomNavPillHeight + AppLayout.bottomNavPillMargin + 8
    )
    .scrollEdgeEffectStyle(.hard, for: .bottom)
    .stackedReportListScrollForDockGlass()
  }

  /// Dashboard — soft no topo (fade), hard na base; sem `.hard` no topo.
  func stackedDashboardListChrome() -> some View {
    safeAreaPadding(
      .bottom,
      AppLayout.fabSize + AppLayout.fabGap + AppLayout.bottomNavPillHeight + AppLayout.bottomNavPillMargin + 8
    )
    .scrollEdgeEffectStyle(.soft, for: .top)
    .scrollEdgeEffectStyle(.hard, for: .bottom)
    .stackedReportListScrollForDockGlass()
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

  /// Drill-down (projeto / filtros) — mesmo edge chrome da Home: soft topo + hard base.
  /// Antes tinha `.hard` no topo e gerava micro-shift ao iniciar o scroll.
  func stackedDrillDownListChrome() -> some View {
    safeAreaPadding(
      .bottom,
      AppLayout.fabSize + AppLayout.fabGap + AppLayout.bottomNavPillHeight + AppLayout.bottomNavPillMargin + 8
    )
    .scrollEdgeEffectStyle(.soft, for: .top)
    .scrollEdgeEffectStyle(.hard, for: .bottom)
    .stackedReportListScrollForDockGlass()
  }
}
