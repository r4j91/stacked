import SwiftUI

/// Reporta fase de scroll das Lists para o dock congelar o glass ao vivo.
struct ListScrollDockGlassReporter: ViewModifier {
  @Environment(MobileChromeController.self) private var chrome

  func body(content: Content) -> some View {
    content.onScrollPhaseChange { _, phase in
      let scrolling = phase != .idle
      // PERF_FASEB3 — probe/UI removidos do path ativo; reativar só se precisar medir de novo.
      // if scrolling { ScrollHitchProbe.scrollBecameActive() }
      // PERF_FASEB3_ETAPA2 T1 — chrome estático: não propaga fase de scroll.
      if ScrollPerfDebugStorage.t1ChromeStatic { return }
      chrome.setContentScrolling(scrolling)
    }
  }
}

extension View {
  func stackedReportListScrollForDockGlass() -> some View {
    modifier(ListScrollDockGlassReporter())
  }
}
