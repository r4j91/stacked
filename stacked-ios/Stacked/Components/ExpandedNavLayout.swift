import CoreGraphics

/// Larguras de slot da navbar expandida — compartilhado entre SwiftUI e DockTouchOverlay.
enum ExpandedNavLayout {
  static let activeWidthMultiplier: CGFloat = 2.4

  static func slotWidths(totalWidth: CGFloat, selected: NavTab) -> [NavTab: CGFloat] {
    guard totalWidth > 0 else { return [:] }
    let tabs = NavTab.allCases
    let inactiveCount = CGFloat(tabs.count - 1)
    let unit = totalWidth / (activeWidthMultiplier + inactiveCount)
    var map: [NavTab: CGFloat] = [:]
    for tab in tabs {
      map[tab] = tab == selected ? unit * activeWidthMultiplier : unit
    }
    return map
  }

  static func orderedSlotWidths(totalWidth: CGFloat, selected: NavTab) -> [CGFloat] {
    NavTab.allCases.map { slotWidths(totalWidth: totalWidth, selected: selected)[$0] ?? 0 }
  }
}
