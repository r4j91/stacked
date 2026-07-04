import SwiftUI

// Paridade lib/main.dart RootScreen + ResponsiveLayout (mobile)
struct RootView: View {
  @Environment(MobileChromeController.self) private var chrome
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var showSearch = false
  @State private var showQuickAdd = false
  @State private var showNewProject = false
  @State private var router = AppNavigationRouter.shared

  var body: some View {
    @Bindable var chrome = chrome
    let currentTab = chrome.selectedTab

    MobileShell(
      onNewTask: { openQuickAdd() },
      onSearch: { showSearch = true },
      onNewProject: { openNewProject() }
    ) {
      RootTabContent()
    }
    .onChange(of: currentTab) { _, tab in
      reloadData(for: tab)
    }
    .onChange(of: router.pendingTab) { _, tab in
      if let tab { chrome.selectTab(tab, reduceMotion: reduceMotion) }
    }
    .onChange(of: router.pendingOpenSearch) { _, open in
      if open { showSearch = true }
    }
    .task {
      await bootstrap(tab: currentTab)
    }
    .sheet(isPresented: $showSearch) {
      SearchView().environment(ThemeManager.shared)
    }
    .quickAddFloating(isPresented: $showQuickAdd, onSaved: { reloadAll() })
    .newProjectFloating(isPresented: $showNewProject) {
      TabRefreshPolicy.invalidate()
      _Concurrency.Task {
        await HomeStore.shared.load()
        await FiltersStore.shared.loadDashboard()
      }
    }
  }

  private func openNewProject() {
    chrome.closeFabMenu()
    PopoverPresenter.shared.dismiss()
    showNewProject = true
  }

  private func openQuickAdd() {
    chrome.closeFabMenu()
    PopoverPresenter.shared.dismiss()
    showQuickAdd = true
  }

  /// Cold start: aba visível primeiro; demais abas em prefetch escalonado.
  private func bootstrap(tab: NavTab) async {
    TabBootstrapCoordinator.cancelPrefetch()
    TabRefreshPolicy.invalidate()
    await TabDataLoader.load(tab)
    TabBootstrapCoordinator.schedulePrefetch(excluding: tab)
    await EventKitCalendarService.shared.syncExportIfNeeded()
  }

  private func reloadData(for tab: NavTab, force: Bool = false) {
    guard force || TabRefreshPolicy.shouldRefresh(tab) else { return }
    _Concurrency.Task { await TabDataLoader.load(tab) }
  }

  private func reloadAll() {
    TabBootstrapCoordinator.cancelPrefetch()
    TabRefreshPolicy.invalidate()
    reloadData(for: chrome.selectedTab, force: true)
    _Concurrency.Task {
      await TabDataLoader.load(.today)
      await TabDataLoader.load(.inbox)
      await TabDataLoader.load(.upcoming)
      await TabDataLoader.load(.home)
      await TabDataLoader.load(.filters)
    }
  }
}

/// Conteúdo por aba — mantém as 5 telas vivas para preservar scroll e estado (Fase I).
struct RootTabContent: View {
  @Environment(MobileChromeController.self) private var chrome
  @Environment(ThemeManager.self) private var theme

  var body: some View {
    ZStack {
      preservedTab(.home) {
        HomeView(
          onNavigateToTab: { chrome.selectTab($0) },
          onOpenFilter: { kind in
            _Concurrency.Task {
              await FiltersStore.shared.openFilter(kind)
              chrome.selectTab(.filters)
            }
          }
        )
      }
      preservedTab(.inbox) { InboxView() }
      preservedTab(.today) { TodayView() }
      preservedTab(.upcoming) { UpcomingView() }
      preservedTab(.filters) { FiltersView() }
    }
    .background(theme.colors.background.ignoresSafeArea())
  }

  @ViewBuilder
  private func preservedTab<Content: View>(_ tab: NavTab, @ViewBuilder content: () -> Content) -> some View {
    let isActive = chrome.selectedTab == tab
    content()
      .opacity(isActive ? 1 : 0)
      .zIndex(isActive ? 1 : 0)
      .allowsHitTesting(isActive)
      .accessibilityHidden(!isActive)
  }
}
