import CoreGraphics
import SwiftUI

// Métricas compartilhadas entre MobileShell (SwiftUI) e DockTouchOverlay (UIKit).
enum ChromeLayout {
  static let pillInnerPadding: CGFloat = 4

  static func resolvedSafeBottom(_ geo: GeometryProxy) -> CGFloat {
    max(geo.safeAreaInsets.bottom, AppLayout.windowSafeBottomInset)
  }

  static func pillMarginBottom(safeBottom: CGFloat) -> CGFloat {
    AppLayout.navPillBottomInset(safeBottom: safeBottom)
  }

  static func fabMarginBottom(safeBottom: CGFloat) -> CGFloat {
    AppLayout.fabBottomInset(safeBottom: safeBottom)
  }

  /// Altura visual da pill (conteúdo + padding interno 4+4).
  static var pillVisualHeight: CGFloat {
    AppLayout.bottomNavPillHeight + pillInnerPadding * 2
  }

  /// Altura da faixa inferior onde o UIKit overlay captura toques (pill + FAB).
  static func dockTouchRegionHeight(safeBottom: CGFloat) -> CGFloat {
    let pillStack = pillMarginBottom(safeBottom: safeBottom) + pillVisualHeight
    let fabStack = fabMarginBottom(safeBottom: safeBottom) + AppLayout.fabSize
    return max(pillStack, fabStack) + 16
  }
}
