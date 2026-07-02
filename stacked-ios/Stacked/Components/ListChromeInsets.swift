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
  var body: some View {
    Color.clear
      .frame(height: AppLayout.listTailInset(safeBottom: AppLayout.windowSafeBottomInset))
  }
}

extension View {
  /// Padding inferior para listas — paridade bottomListInset (sem duplicar ListTailSpacer).
  func stackedListTailInset() -> some View {
    safeAreaPadding(
      .bottom,
      AppLayout.fabSize + AppLayout.fabGap + AppLayout.bottomNavPillHeight + AppLayout.bottomNavPillMargin + 8
    )
  }
}
