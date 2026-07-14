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
  /// Lista principal em scroll — dock pode congelar o glass ao vivo.
  var isContentScrolling = false

  private var scrollIdleTask: _Concurrency.Task<Void, Never>?

  private init() {}

  /// Atualiza flag de scroll; no idle espera um tick para não piscar o glass no fim do fling.
  func setContentScrolling(_ scrolling: Bool) {
    scrollIdleTask?.cancel()
    scrollIdleTask = nil
    if scrolling {
      if !isContentScrolling {
        isContentScrolling = true
      }
      return
    }
    scrollIdleTask = _Concurrency.Task { @MainActor in
      try? await _Concurrency.Task.sleep(for: .milliseconds(120))
      guard !_Concurrency.Task.isCancelled else { return }
      isContentScrolling = false
    }
  }

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

  /// Glass ao vivo vs congelado vs sólido (reduce transparency / kill switch).
  func dockGlassMode(
    reduceTransparency: Bool,
    freezeWhileScrolling: Bool? = nil,
    alwaysFrozen: Bool? = nil,
    disableAllGlass: Bool? = nil,
    alwaysStaticGlass: Bool? = nil
  ) -> DockGlassMode {
    if GlassChromePreference.prefersSolid(
      reduceTransparency: reduceTransparency,
      disableAllGlass: disableAllGlass
    ) {
      return .solid
    }
    // PERF_FASEB3_ETAPA2 T1 — sem reação ao scroll (permanece live).
    if ScrollPerfDebugStorage.t1ChromeStatic { return .live }
    let always =
      (alwaysFrozen ?? AlwaysFrozenDockGlassStorage.isEnabled)
      || GlassChromePreference.prefersStaticFrozen(alwaysStaticGlass: alwaysStaticGlass)
    if always { return .frozen }
    let freeze = freezeWhileScrolling ?? FreezeDockGlassWhileScrollingStorage.isEnabled
    if freeze, isContentScrolling {
      return .frozen
    }
    return .live
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

enum DockGlassMode: Equatable {
  case live
  /// Glass “pausado”: fill estático (sem amostrar a lista ao vivo).
  case frozen
  case solid
}
