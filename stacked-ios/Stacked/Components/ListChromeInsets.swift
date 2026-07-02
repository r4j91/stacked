import SwiftUI

// Paridade lib/theme/app_layout.dart bottomListInset / homeDockBottomInset
extension AppLayout {
  static func totalBottomChromeHeight(safeBottom: CGFloat) -> CGFloat {
    safeBottom + bottomNavPillMargin + bottomNavPillHeight + fabGap + fabSize
  }

  static func listTailInset(safeBottom: CGFloat) -> CGFloat {
    totalBottomChromeHeight(safeBottom: safeBottom) + 8
  }
}

struct ListTailSpacer: View {
  var body: some View {
    GeometryReader { geo in
      Color.clear
        .frame(height: AppLayout.listTailInset(safeBottom: geo.safeAreaInsets.bottom))
    }
    .frame(height: AppLayout.listTailInset(safeBottom: 0))
  }
}

extension View {
  func stackedListTailInset() -> some View {
    safeAreaPadding(.bottom, AppLayout.fabSize + AppLayout.fabGap + AppLayout.bottomNavPillHeight + AppLayout.bottomNavPillMargin)
  }
}
