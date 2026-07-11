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
  /// Fase 3 — ilha expansível (estilo Dynamic Island).
  var islandNavExpanded = false

  private init() {}

  var fabIntegratedInIsland: Bool {
    FabIntegratedInIslandStorage.isEnabled
  }

  /// FAB_INTEGRADO_ETAPA2 — trava expand/collapse da ilha enquanto o menu "+" está aberto.
  var islandNavLockedByFabMenu: Bool {
    navBarStyle == .island && fabIntegratedInIsland && fabOpen
  }

  var usesIntegratedIslandFab: Bool {
    navBarStyle == .island && fabIntegratedInIsland
  }

  var navBarStyle: NavBarStyle {
    NavBarStyleStorage.style(
      from: UserDefaults.standard.string(forKey: NavBarStyleStorage.key)
        ?? NavBarStyleStorage.defaultRawValue
    )
  }

  func expandIslandNav(reduceMotion: Bool = UIAccessibility.isReduceMotionEnabled) {
    guard navBarStyle == .island else { return }
    guard !islandNavLockedByFabMenu else { return }
    fabOpen = false
    AppMotion.animate(AppMotion.islandNavSpring, reduceMotion: reduceMotion) {
      islandNavExpanded = true
    }
  }

  func collapseIslandNav(reduceMotion: Bool = UIAccessibility.isReduceMotionEnabled) {
    guard islandNavExpanded else { return }
    guard !islandNavLockedByFabMenu else { return }
    AppMotion.animate(AppMotion.islandNavSpring, reduceMotion: reduceMotion) {
      islandNavExpanded = false
    }
  }

  private func collapseIslandNavIfNeeded() {
    if navBarStyle == .island {
      islandNavExpanded = false
    }
  }

  func setTabPressed(_ tab: NavTab?) {
    guard pressedTab != tab else { return }
    if tab != nil {
      HapticService.prepareTabChange()
    }
    pressedTab = tab
  }

  func selectTab(_ tab: NavTab, reduceMotion: Bool = UIAccessibility.isReduceMotionEnabled) {
    pressedTab = nil
    let changing = tab != selectedTab
    if changing {
      HapticService.tabChanged()
      PopoverPresenter.shared.dismiss()
      fabOpen = false
    }

    if navBarStyle == .island {
      if islandNavExpanded {
        AppMotion.animate(AppMotion.islandTabSelectSpring, reduceMotion: reduceMotion) {
          selectedTab = tab
          islandNavExpanded = false
        }
      } else if changing {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
          selectedTab = tab
        }
      }
      return
    }

    AppMotion.animate(AppMotion.navMorphSpring, reduceMotion: reduceMotion) {
      selectedTab = tab
      self.collapseIslandNavIfNeeded()
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
