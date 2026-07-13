import SwiftUI

// Paridade lib/widgets/responsive_layout.dart — extendBody + overlay no fundo da tela.
struct MobileShell<Content: View>: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(MobileChromeController.self) private var chrome
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @AppStorage(NavBarStyleStorage.key) private var navBarStyleRaw = NavBarStyleStorage.defaultRawValue
  @AppStorage(FabIntegratedInIslandStorage.key) private var fabIntegratedInIsland = false
  var hideBottomChrome: Bool = false
  var onNewTask: () -> Void = {}
  var onSearch: () -> Void = {}
  var onNewProject: () -> Void = {}
  @ViewBuilder var content: () -> Content

  init(
    hideBottomChrome: Bool = false,
    onNewTask: @escaping () -> Void = {},
    onSearch: @escaping () -> Void = {},
    onNewProject: @escaping () -> Void = {},
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.hideBottomChrome = hideBottomChrome
    self.onNewTask = onNewTask
    self.onSearch = onSearch
    self.onNewProject = onNewProject
    self.content = content
  }

  var body: some View {
    @Bindable var chrome = chrome
    let c = theme.colors
    let navBarStyle = NavBarStyleStorage.style(from: navBarStyleRaw)
    let usesIntegratedIslandFab = navBarStyle == .island && fabIntegratedInIsland

    ZStack(alignment: .bottomTrailing) {
      // Conteúdo fora do GeometryReader — o reader não reavalia filhos quando só o tab muda.
      content()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.keyboard, edges: .bottom)

      GeometryReader { geo in
        let safeBottom = ChromeLayout.resolvedSafeBottom(geo)
        let pillBottom = ChromeLayout.pillMarginBottom(safeBottom: safeBottom)
        let fabBottom = ChromeLayout.fabMarginBottom(safeBottom: safeBottom)

        ZStack(alignment: .bottomTrailing) {
          // ISLAND_FASE3 — dismiss abaixo do dock para não bloquear DockTouchOverlay.
          if !hideBottomChrome, navBarStyle == .island, chrome.islandNavExpanded {
            Color.clear
              .ignoresSafeArea()
              .contentShape(Rectangle())
              .onTapGesture {
                guard !chrome.islandNavLockedByFabMenu else { return }
                chrome.collapseIslandNav()
              }
              .frame(width: geo.size.width, height: geo.size.height)
              .transition(.opacity)
          }

          if !hideBottomChrome {
            BottomChromeBar(
              safeBottom: safeBottom,
              pillBottom: pillBottom,
              fabBottom: fabBottom,
              size: geo.size
            )
          }

          if !hideBottomChrome, chrome.fabOpen {
            Color.black.opacity(0.55)
              .ignoresSafeArea()
              .contentShape(Rectangle())
              .onTapGesture { chrome.closeFabMenu() }
              .frame(width: geo.size.width, height: geo.size.height)
              .transition(.opacity)

            FabActionMenuOverlay(
              safeBottom: safeBottom,
              screenWidth: geo.size.width,
              fabIntegratedInIsland: usesIntegratedIslandFab,
              islandExpanded: chrome.islandNavExpanded,
              isOpen: $chrome.fabOpen,
              onNewTask: onNewTask,
              onNewProject: onNewProject,
              onSearch: onSearch
            )
            .frame(width: geo.size.width, height: geo.size.height, alignment: .bottomTrailing)
            .transition(.opacity)
            .animation(AppMotion.smooth(reduceMotion: reduceMotion), value: chrome.fabOpen)
          }
        }
        .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
      }
      .zIndex(20)
    }
    // Animação do FAB restrita ao overlay — evita invalidar conteúdo e navbar.
    // REMOVIDO_A1_ETAPA2 — .animation(AppMotion.islandNavMorph(reduceMotion: reduceMotion), value: chrome.islandNavExpanded)
    .ignoresSafeArea(edges: .bottom)
    .background(c.background.ignoresSafeArea(.all))
  }
}

private struct BottomChromeBar: View {
  @Environment(MobileChromeController.self) private var chrome
  @AppStorage(NavBarStyleStorage.key) private var navBarStyleRaw = NavBarStyleStorage.defaultRawValue
  @AppStorage(FabIntegratedInIslandStorage.key) private var fabIntegratedInIsland = false
  let safeBottom: CGFloat
  let pillBottom: CGFloat
  let fabBottom: CGFloat
  let size: CGSize

  private var usesIntegratedIslandFab: Bool {
    NavBarStyleStorage.style(from: navBarStyleRaw) == .island && fabIntegratedInIsland
  }

  var body: some View {
    @Bindable var chrome = chrome

    ZStack(alignment: .bottomTrailing) {
      // SUBSTITUIDO_ETAPA2 — BottomNavPill → NavBarContainer (classic por composição).
      NavBarContainer(selectedTab: $chrome.selectedTab)
      // BottomNavPill(selectedTab: $chrome.selectedTab)
        .padding(.horizontal, AppLayout.fabSideMargin)
        .padding(.bottom, pillBottom)
        .frame(maxWidth: .infinity, alignment: .bottom)
        .allowsHitTesting(false)

      if !usesIntegratedIslandFab {
        ExpandableFAB(isOpen: $chrome.fabOpen)
          .padding(.trailing, AppLayout.fabSideMargin)
          .padding(.bottom, fabBottom)
          .allowsHitTesting(false)
      }
      // FAB_INTEGRADO_ETAPA2 — ExpandableFAB flutuante oculto quando integrado na ilha.

      DockTouchOverlay(safeBottom: safeBottom)
        .frame(
          width: size.width,
          height: ChromeLayout.dockTouchRegionHeight(safeBottom: safeBottom)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
    .frame(width: size.width, height: size.height, alignment: .bottom)
  }
}
