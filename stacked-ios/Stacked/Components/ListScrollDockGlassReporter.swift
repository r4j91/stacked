import SwiftUI

/// Antes reportava scroll para pausar Liquid Glass. Freeze-on-scroll foi removido —
/// mantém o modifier como no-op para não espalhar diffs nos call sites.
struct ListScrollDockGlassReporter: ViewModifier {
  func body(content: Content) -> some View {
    content
  }
}

extension View {
  func stackedReportListScrollForDockGlass() -> some View {
    modifier(ListScrollDockGlassReporter())
  }
}
