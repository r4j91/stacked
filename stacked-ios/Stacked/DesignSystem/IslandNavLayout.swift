import CoreGraphics

// FAB_INTEGRADO_ETAPA2 — geometria compartilhada (SwiftUI + UIKit overlay).
enum IslandNavLayout {
  static let fabDividerWidth: CGFloat = 1
  static let fabSegmentWidth: CGFloat = 44

  static func fabSegmentTotalWidth(integrated: Bool) -> CGFloat {
    integrated ? fabDividerWidth + fabSegmentWidth : 0
  }

  static func pillWidth(trackWidth: CGFloat, expanded: Bool, fabIntegrated: Bool) -> CGFloat {
    guard trackWidth > 0 else { return 0 }
    if expanded {
      return trackWidth
    }
    return trackWidth * IslandNavMetrics.compactWidthRatio + fabSegmentTotalWidth(integrated: fabIntegrated)
  }

  static func pillLeading(
    screenWidth: CGFloat,
    sideMargin: CGFloat,
    innerPadding: CGFloat,
    trackWidth: CGFloat,
    pillWidth: CGFloat
  ) -> CGFloat {
    sideMargin + innerPadding + max(0, (trackWidth - pillWidth) / 2)
  }

  static func trackWidth(screenWidth: CGFloat, sideMargin: CGFloat, innerPadding: CGFloat) -> CGFloat {
    max(0, screenWidth - sideMargin * 2 - innerPadding * 2)
  }

  /// Centro X do segmento "+" na tela (para âncora do menu).
  static func fabSegmentCenterX(
    screenWidth: CGFloat,
    sideMargin: CGFloat,
    innerPadding: CGFloat,
    expanded: Bool,
    fabIntegrated: Bool
  ) -> CGFloat {
    let track = trackWidth(screenWidth: screenWidth, sideMargin: sideMargin, innerPadding: innerPadding)
    let pillW = pillWidth(trackWidth: track, expanded: expanded, fabIntegrated: fabIntegrated)
    let pillL = pillLeading(
      screenWidth: screenWidth,
      sideMargin: sideMargin,
      innerPadding: innerPadding,
      trackWidth: track,
      pillWidth: pillW
    )
    return pillL + pillW - fabSegmentWidth / 2
  }

  /// Base Y do segmento "+" a partir do fundo da tela (UIKit coords).
  static func fabSegmentBottom(screenSafeBottom: CGFloat) -> CGFloat {
    ChromeLayout.pillMarginBottom(safeBottom: screenSafeBottom)
  }
}
