import SwiftUI

// Paridade lib/main.dart RootScreen + ResponsiveLayout (mobile)
struct RootView: View {
  @Environment(MobileChromeController.self) private var chrome
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.scenePhase) private var scenePhase
  @State private var showSearch = false
  @State private var showQuickAdd = false
  @State private var showNewProject = false
  @State private var router = AppNavigationRouter.shared
  @State private var visitedTabs: Set<NavTab> = [.home] // AJUSTADO_VISITED_TABS
  @State private var didBootstrap = false
  @State private var syncFeedback = SyncFeedback.shared

  var body: some View {
    @Bindable var chrome = chrome
    let currentTab = chrome.selectedTab

    MobileShell(
      onNewTask: { openQuickAdd() },
      onSearch: { showSearch = true },
      onNewProject: { openNewProject() }
    ) {
      RootTabContent(visitedTabs: visitedTabs)
    }
    .overlay(alignment: .bottom) {
      // NET_FASEC_ETAPA2/4 — toast de sync (acima do dock).
      if let banner = syncFeedback.banner {
        SyncToastBanner(banner: banner)
          .padding(.bottom, 88)
          .environment(ThemeManager.shared)
      }
    }
    .onChange(of: currentTab) { _, tab in
      visitedTabs.insert(tab) // AJUSTADO_VISITED_TABS
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
      didBootstrap = true
    }
    .onChange(of: scenePhase) { _, phase in
      guard didBootstrap, phase == .active else { return }
      NetLog.markForeground()
      WidgetSnapshotSync.refreshFromCachedToday()
      GlobalDataRefresh.refreshRelativeDateChips()
      _Concurrency.Task {
        // NET_FASEC_ETAPA4 — refresh proativo de sessão ao voltar do background.
        do {
          _ = try await NetLog.timed("auth.refreshSession", step: .authRefresh) {
            try await SupabaseService.client.auth.refreshSession()
          }
        } catch {
          // Refresh falhou — request seguinte ainda tenta via autoRefreshToken.
        }
        await NotificationService.shared.rescheduleAllPending()
        await GlobalDataRefresh.refreshDashboardCounts()
        await HomeStore.shared.refreshWeatherIfNeeded()
      }
    }
    .sheet(isPresented: $showSearch) {
      SearchView().environment(ThemeManager.shared)
    }
    .quickAddFloating(isPresented: $showQuickAdd, onSaved: { afterQuickAddSaved($0) })
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
    await NotificationService.shared.rescheduleAllPending()
  }

  private func reloadData(for tab: NavTab, force: Bool = false) {
    guard force || TabRefreshPolicy.shouldRefresh(tab) else { return }
    _Concurrency.Task {
      // Aguarda a animação de troca de aba completar antes de disparar fetch
      // navMorphSpring (response: 0.36) — 400ms cobre a transição com folga
      // NET_FASEC_ETAPA5 — delay ignorável via toggle NetLog (default: mantém).
      let skipDelay = UserDefaults.standard.bool(forKey: "net.log.skip.reload.delay")
      if !skipDelay {
        try? await _Concurrency.Task.sleep(for: .milliseconds(400)) // AJUSTADO_RELOAD_DELAY
      } else {
        NetLog.record(
          operation: "reloadData.skip_delay",
          step: .reload,
          durationMs: 0,
          result: .success
        )
      }
      await TabDataLoader.load(tab)
    }
  }

  private func afterQuickAddSaved(_ summary: QuickAddSaveSummary) {
    let today = TaskMapper.dateString(Date())
    let tabs = summary.tabsToReload(todayStr: today)
    // NET_FASEC_ETAPA2 — mutação local já está no store; sem force reload da lista.
    // reloadData(for: chrome.selectedTab, force: true)
    // TabBootstrapCoordinator.cancelPrefetch()
    // _Concurrency.Task {
    //   for tab in tabs where tab != chrome.selectedTab {
    //     await TabDataLoader.load(tab)
    //   }
    // }
    GlobalDataRefresh.afterTaskMutation(invalidateTabs: tabs)
    let reloadStart = Date()
    NetLog.record(
      operation: "afterQuickAddSaved.no_force_reload",
      step: .reload,
      durationMs: Int(Date().timeIntervalSince(reloadStart) * 1000),
      result: .success,
      detail: "tabs=\(tabs.map { String(describing: $0) }.joined(separator: ","))"
    )
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
  let visitedTabs: Set<NavTab> // AJUSTADO_VISITED_TABS

  var body: some View {
    ZStack {
      preservedTab(.home) {
        HomeView(
          onNavigateToTab: { chrome.selectTab($0) },
          onOpenFilter: { kind in
            FiltersStore.shared.requestPresetFilterNavigation(kind)
            chrome.selectTab(.filters)
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

  private func preservedTab<Content: View>(
    _ tab: NavTab,
    @ViewBuilder content: () -> Content
  ) -> AnyView {
    let isActive = chrome.selectedTab == tab
    let hasBeenVisited = visitedTabs.contains(tab)

    // Aba nunca visitada e inativa: não entra no render tree
    // AJUSTADO_VISITED_TABS
    guard isActive || hasBeenVisited else { return AnyView(EmptyView()) }

    return AnyView(
      content()
        .environment(\.isTabActive, isActive)
        .opacity(isActive ? 1 : 0)
        .animation(nil, value: isActive)
        .zIndex(isActive ? 1 : 0)
        .allowsHitTesting(isActive)
        .accessibilityHidden(!isActive)
        // Congela composição da aba oculta — reduz custo GPU com heroes/listas sob o scroll ativo.
        .transaction { transaction in
          if !isActive { transaction.disablesAnimations = true }
        }
    )
  }
}
