import SwiftUI

/// Fase 1 — switch de estilo de navbar. Fases 2/3 substituem os placeholders por novas views.
struct NavBarContainer: View {
  @AppStorage(NavBarStyleStorage.key) private var navBarStyleRaw = NavBarStyleStorage.defaultRawValue
  @Binding var selectedTab: NavTab

  private var style: NavBarStyle {
    NavBarStyleStorage.style(from: navBarStyleRaw)
  }

  var body: some View {
    switch style {
    case .classic:
      ClassicNavBar(selectedTab: $selectedTab)
    case .expanded:
      // SUBSTITUIDO_FASE2 — placeholder classic → ExpandedNavBar.
      ExpandedNavBar(selectedTab: $selectedTab)
      // ClassicNavBar(selectedTab: $selectedTab)
    case .island:
      // SUBSTITUIDO_FASE3 — placeholder classic → IslandNavBar.
      IslandNavBar(selectedTab: $selectedTab)
      // ClassicNavBar(selectedTab: $selectedTab)
    }
  }
}
