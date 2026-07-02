import SwiftUI

// Paridade lib/widgets/responsive_layout.dart — extendBody + overlay no fundo da tela.
struct MobileShell<Content: View>: View {
  @Environment(ThemeManager.self) private var theme
  @Binding var selectedTab: NavTab
  @Binding var fabOpen: Bool
  var hideBottomChrome: Bool = false
  var onNewTask: () -> Void = {}
  var onSearch: () -> Void = {}
  var onNewProject: () -> Void = {}
  @ViewBuilder var content: () -> Content

  init(
    selectedTab: Binding<NavTab>,
    fabOpen: Binding<Bool>,
    hideBottomChrome: Bool = false,
    onNewTask: @escaping () -> Void = {},
    onSearch: @escaping () -> Void = {},
    onNewProject: @escaping () -> Void = {},
    @ViewBuilder content: @escaping () -> Content
  ) {
    _selectedTab = selectedTab
    _fabOpen = fabOpen
    self.hideBottomChrome = hideBottomChrome
    self.onNewTask = onNewTask
    self.onSearch = onSearch
    self.onNewProject = onNewProject
    self.content = content
  }

  var body: some View {
    let c = theme.colors

    GeometryReader { geo in
      // Com ignoresSafeArea(.bottom), safeAreaInsets reflete o home indicator uma vez só.
      let safeBottom = geo.safeAreaInsets.bottom
      let pillBottom = AppLayout.navPillBottomInset(safeBottom: safeBottom)
      let fabBottom = AppLayout.fabBottomInset(safeBottom: safeBottom)

      ZStack(alignment: .bottomTrailing) {
        content()
          .frame(width: geo.size.width, height: geo.size.height)

        if !hideBottomChrome {
          BottomNavPill(selectedTab: selectedTab) { tab in
            HapticService.tabChanged()
            PopoverPresenter.shared.dismiss()
            fabOpen = false
            selectedTab = tab
          }
          .padding(.horizontal, AppLayout.fabSideMargin)
          .padding(.bottom, pillBottom)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
          .zIndex(20)
        }

        if !hideBottomChrome, fabOpen {
          Color.black.opacity(0.55)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture { fabOpen = false }
            .frame(width: geo.size.width, height: geo.size.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .transition(.opacity)
            .zIndex(30)
        }

        if !hideBottomChrome, fabOpen {
          FabActionMenuOverlay(
            safeBottom: safeBottom,
            isOpen: $fabOpen,
            onNewTask: onNewTask,
            onNewProject: onNewProject,
            onSearch: onSearch
          )
          .frame(width: geo.size.width, height: geo.size.height, alignment: .bottomTrailing)
          .transition(.opacity)
          .zIndex(40)
        }

        if !hideBottomChrome {
          ExpandableFAB(isOpen: $fabOpen)
            .padding(.trailing, AppLayout.fabSideMargin)
            .padding(.bottom, fabBottom)
            .zIndex(50)
        }
      }
    }
    .ignoresSafeArea(edges: .bottom)
    .background(c.background.ignoresSafeArea())
  }
}
