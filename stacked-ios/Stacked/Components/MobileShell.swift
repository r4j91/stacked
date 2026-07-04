import SwiftUI

// Paridade lib/widgets/responsive_layout.dart — extendBody + overlay no fundo da tela.
struct MobileShell<Content: View>: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(MobileChromeController.self) private var chrome
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
              isOpen: $chrome.fabOpen,
              onNewTask: onNewTask,
              onNewProject: onNewProject,
              onSearch: onSearch
            )
            .frame(width: geo.size.width, height: geo.size.height, alignment: .bottomTrailing)
            .transition(.opacity)
          }
        }
        .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
      }
      .zIndex(20)
    }
    .animation(AppMotion.smooth(reduceMotion: reduceMotion), value: chrome.fabOpen)
    .ignoresSafeArea(edges: .bottom)
    .background(c.background.ignoresSafeArea(.all))
  }
}

private struct BottomChromeBar: View {
  @Environment(MobileChromeController.self) private var chrome
  let safeBottom: CGFloat
  let pillBottom: CGFloat
  let fabBottom: CGFloat
  let size: CGSize

  var body: some View {
    @Bindable var chrome = chrome

    ZStack(alignment: .bottomTrailing) {
      BottomNavPill(selectedTab: $chrome.selectedTab)
        .padding(.horizontal, AppLayout.fabSideMargin)
        .padding(.bottom, pillBottom)
        .frame(maxWidth: .infinity, alignment: .bottom)
        .allowsHitTesting(false)

      ExpandableFAB(isOpen: $chrome.fabOpen)
        .padding(.trailing, AppLayout.fabSideMargin)
        .padding(.bottom, fabBottom)
        .allowsHitTesting(false)

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
