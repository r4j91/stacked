import SwiftUI

/// Fase 1 — barra clássica por composição. `BottomNavPill` permanece intacto (sem reescrita).
struct ClassicNavBar: View {
  @Binding var selectedTab: NavTab

  var body: some View {
    BottomNavPill(selectedTab: $selectedTab)
  }
}
