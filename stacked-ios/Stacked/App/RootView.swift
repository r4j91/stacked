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
  /// Abas já no render tree (opacity 0 quando inativas).
  @State private var mountedTabs: Set<NavTab> = [.home]
  /// Aba visível — pode atrasar vs `chrome.selectedTab` no colapso da ilha.
  @State private var displayedTab: NavTab = .home
  @State private var didBootstrap = false
  @State private var syncFeedback = SyncFeedback.shared
  @State private var tabContentSwitchTask: _Concurrency.Task<Void, Never>?
  @State private var tabWarmMountTask: _Concurrency.Task<Void, Never>?

  var body: some View {
    @Bindable var chrome = chrome
    let currentTab = chrome.selectedTab

    MobileShell(
      onNewTask: { openQuickAdd() },
      onSearch: { showSearch = true },
      onNewProject: { openNewProject() }
    ) {
      RootTabContent(mountedTabs: mountedTabs, displayedTab: displayedTab)
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
      scheduleDisplayedTab(tab)
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
      scheduleWarmTabMounts(excluding: currentTab)
    }
    .onDisappear {
      tabContentSwitchTask?.cancel()
      tabWarmMountTask?.cancel()
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

  /// Troca o conteúdo visível. No colapso da ilha, espera o snappy terminar
  /// para não competir com a animação da pill (navbar continua imediata).
  private func scheduleDisplayedTab(_ tab: NavTab) {
    tabContentSwitchTask?.cancel()

    let deferForIslandCollapse =
      !reduceMotion
      && chrome.lastSelectCollapsedIsland
      && chrome.navBarStyle == .island

    guard deferForIslandCollapse else {
      mountedTabs.insert(tab)
      displayedTab = tab
      return
    }

    tabContentSwitchTask = _Concurrency.Task { @MainActor in
      try? await _Concurrency.Task.sleep(for: AppMotion.islandTabContentSettle)
      guard !_Concurrency.Task.isCancelled else { return }
      guard chrome.selectedTab == tab else { return }
      mountedTabs.insert(tab)
      displayedTab = tab
    }
  }

  /// Pré-monta abas inativas no idle — 1ª visita deixa de custar no meio do gesto da ilha.
  private func scheduleWarmTabMounts(excluding priority: NavTab) {
    tabWarmMountTask?.cancel()
    tabWarmMountTask = _Concurrency.Task { @MainActor in
      try? await _Concurrency.Task.sleep(for: .milliseconds(700))
      guard !_Concurrency.Task.isCancelled else { return }

      for tab in NavTab.allCases where tab != priority {
        guard !_Concurrency.Task.isCancelled else { return }
        if !mountedTabs.contains(tab) {
          mountedTabs.insert(tab)
        }
        try? await _Concurrency.Task.sleep(for: .milliseconds(140))
      }
    }
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
  let mountedTabs: Set<NavTab>
  let displayedTab: NavTab

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
    let isActive = displayedTab == tab
    let isMounted = mountedTabs.contains(tab)

    // Aba nunca montada e inativa: não entra no render tree
    guard isActive || isMounted else { return AnyView(EmptyView()) }

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
