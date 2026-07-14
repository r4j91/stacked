import SwiftUI

/// Reporta fase de scroll das Lists para o dock congelar o glass ao vivo.
struct ListScrollDockGlassReporter: ViewModifier {
  @Environment(MobileChromeController.self) private var chrome
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @AppStorage(FreezeDockGlassWhileScrollingStorage.key) private var freezeDockGlassWhileScrolling = true
  @AppStorage(AlwaysFrozenDockGlassStorage.key) private var alwaysFrozenDockGlass = false
  @AppStorage(AlwaysStaticGlassStorage.key) private var alwaysStaticGlass = false
  @AppStorage(DisableAllGlassStorage.key) private var disableAllGlass = false

  /// Se o modo do dock não muda com o scroll, não vale mutar `isContentScrolling`
  /// (evita republish do chrome no 1º frame do gesto).
  private var scrollAffectsDockGlass: Bool {
    if ScrollPerfDebugStorage.t1ChromeStatic { return false }
    if GlassChromePreference.prefersSolid(
      reduceTransparency: reduceTransparency,
      disableAllGlass: disableAllGlass
    ) {
      return false
    }
    if alwaysFrozenDockGlass || alwaysStaticGlass { return false }
    return freezeDockGlassWhileScrolling
  }

  func body(content: Content) -> some View {
    content.onScrollPhaseChange { _, phase in
      guard scrollAffectsDockGlass else { return }
      let scrolling = phase != .idle
      // PERF_FASEB3 — probe/UI removidos do path ativo; reativar só se precisar medir de novo.
      // if scrolling { ScrollHitchProbe.scrollBecameActive() }
      chrome.setContentScrolling(scrolling)
    }
  }
}

extension View {
  func stackedReportListScrollForDockGlass() -> some View {
    modifier(ListScrollDockGlassReporter())
  }
}
