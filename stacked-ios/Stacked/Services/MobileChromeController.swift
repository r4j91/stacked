import Foundation
import SwiftUI

/// Estado do dock mobile — UIKit e SwiftUI leem/escrevem a mesma fonte.
@MainActor
@Observable
final class MobileChromeController {
  static let shared = MobileChromeController()

  var selectedTab: NavTab = .home
  var fabOpen = false
  /// Aba com dedo em touch-down (feedback visual SwiftUI).
  var pressedTab: NavTab?

  private init() {}

  func setTabPressed(_ tab: NavTab?) {
    guard pressedTab != tab else { return }
    if tab != nil {
      HapticService.prepareTabChange()
    }
    pressedTab = tab
  }

  func selectTab(_ tab: NavTab, reduceMotion: Bool = UIAccessibility.isReduceMotionEnabled) {
    pressedTab = nil
    guard tab != selectedTab else { return }
    HapticService.tabChanged()
    PopoverPresenter.shared.dismiss()
    fabOpen = false
    AppMotion.animate(AppMotion.navMorphSpring, reduceMotion: reduceMotion) {
      selectedTab = tab
    }
  }

  func toggleFabMenu() {
    if fabOpen {
      fabOpen = false
    } else {
      HapticService.fabOpened()
      fabOpen = true
    }
  }

  func closeFabMenu() {
    fabOpen = false
  }
}
