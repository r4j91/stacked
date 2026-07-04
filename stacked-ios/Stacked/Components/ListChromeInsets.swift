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
}
