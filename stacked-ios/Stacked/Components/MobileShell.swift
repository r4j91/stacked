import SwiftUI

// Paridade lib/widgets/responsive_layout.dart — extendBody + overlay no fundo da tela.
struct MobileShell<Content: View>: View {
  @Environment(ThemeManager.self) private var theme
  @Binding var selectedTab: NavTab
  @Binding var fabOpen: Bool
  var onNewTask: () -> Void = {}
  var onSearch: () -> Void = {}
  var onNewProject: () -> Void = {}
  @ViewBuilder var content: () -> Content

  init(
    selectedTab: Binding<NavTab>,
    fabOpen: Binding<Bool>,
    onNewTask: @escaping () -> Void = {},
    onSearch: @escaping () -> Void = {},
    onNewProject: @escaping () -> Void = {},
    @ViewBuilder content: @escaping () -> Content
  ) {
    _selectedTab = selectedTab
    _fabOpen = fabOpen
    self.onNewTask = onNewTask
    self.onSearch = onSearch
    self.onNewProject = onNewProject
    self.content = content
  }

  var body: some View {
    let c = theme.colors

    GeometryReader { geo in
      let safeBottom = geo.safeAreaInsets.bottom
      let fabBottomInset = safeBottom
        + AppLayout.bottomNavPillMargin
        + AppLayout.bottomNavPillHeight
        + AppLayout.fabGap

      ZStack(alignment: .bottom) {
        content()
          .frame(width: geo.size.width, height: geo.size.height)

        BottomNavPill(selectedTab: selectedTab) { tab in
          HapticService.tabChanged()
          PopoverPresenter.shared.dismiss()
          fabOpen = false
          selectedTab = tab
        }
        .padding(.horizontal, AppLayout.fabSideMargin)
        .padding(.bottom, safeBottom + AppLayout.bottomNavPillMargin)
        .frame(maxWidth: .infinity, alignment: .bottom)
        .zIndex(10)

        if fabOpen {
          FabActionMenuOverlay(
            safeBottom: safeBottom,
            isOpen: $fabOpen,
            onNewTask: onNewTask,
            onNewProject: onNewProject,
            onSearch: onSearch
          )
          .frame(width: geo.size.width, height: geo.size.height)
          .zIndex(40)
        }

        ExpandableFAB(isOpen: $fabOpen)
          .padding(.trailing, AppLayout.fabSideMargin)
          .padding(.bottom, fabBottomInset)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
          .zIndex(50)
      }
    }
    .background(c.background.ignoresSafeArea())
    .animation(.spring(response: 0.32, dampingFraction: 0.86), value: fabOpen)
  }
}
