import Foundation
import SwiftUI

/// Estado do dock mobile — UIKit e SwiftUI leem/escrevem a mesma fonte.
@MainActor
@Observable
final class MobileChromeController {
  static let shared = MobileChromeController()

  var selectedTab: NavTab = .home
  var fabOpen = false

  private init() {}

  func selectTab(_ tab: NavTab) {
    guard tab != selectedTab else { return }
    HapticService.prepareTabChange()
    HapticService.tabChanged()
    PopoverPresenter.shared.dismiss()
    fabOpen = false
    withAnimation(AppMotion.navMorphSpring) {
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
