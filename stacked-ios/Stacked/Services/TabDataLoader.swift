import Foundation

/// Carregamento centralizado das abas — evita duplicar `.task` em cada view (Fase I lazy load).
@MainActor
enum TabDataLoader {
  static func load(_ tab: NavTab) async {
    switch tab {
    case .home:
      await HomeStore.shared.load()
    case .today:
      await TaskStore.shared.loadToday()
    case .inbox:
      await TaskStore.shared.loadInbox()
    case .upcoming:
      await UpcomingStore.shared.load()
    case .filters:
      await FiltersStore.shared.loadDashboard()
    }
    TabRefreshPolicy.markLoaded(tab)
  }

  /// Ordem de prefetch após a aba inicial — uso típico do app.
  static func prefetchOrder(excluding priority: NavTab) -> [NavTab] {
    let typical: [NavTab] = [.today, .inbox, .upcoming, .filters, .home]
    return typical.filter { $0 != priority }
  }
}

/// Prefetch escalonado das abas inativas — não bloqueia cold start.
@MainActor
enum TabBootstrapCoordinator {
  private static var prefetchTask: _Concurrency.Task<Void, Never>?

  static func schedulePrefetch(excluding priority: NavTab) {
    prefetchTask?.cancel()
    prefetchTask = _Concurrency.Task {
      try? await _Concurrency.Task.sleep(for: .milliseconds(1200))
      guard !_Concurrency.Task.isCancelled else { return }

      for tab in TabDataLoader.prefetchOrder(excluding: priority) {
        guard !_Concurrency.Task.isCancelled else { return }
        guard TabRefreshPolicy.shouldRefresh(tab) else { continue }
        await TabDataLoader.load(tab)
        try? await _Concurrency.Task.sleep(for: .milliseconds(350))
      }
    }
  }

  static func cancelPrefetch() {
    prefetchTask?.cancel()
    prefetchTask = nil
  }
}

/// Metadados da tarefa criada — define quais abas precisam recarregar.
struct QuickAddSaveSummary: Sendable {
  let projectId: String?
  let dueDateISO: String?
  var extraTabs: [NavTab] = []

  var affectsInbox: Bool {
    projectId == nil && dueDateISO == nil
  }

  func affectsToday(todayStr: String) -> Bool {
    guard let dueDateISO else { return false }
    return dueDateISO <= todayStr
  }

  func affectsUpcoming(todayStr: String) -> Bool {
    guard let dueDateISO else { return false }
    return dueDateISO > todayStr
  }

  func tabsToReload(todayStr: String) -> [NavTab] {
    var tabs: [NavTab] = []
    if affectsInbox { tabs.append(.inbox) }
    if affectsToday(todayStr: todayStr) { tabs.append(.today) }
    if affectsUpcoming(todayStr: todayStr) { tabs.append(.upcoming) }
    for tab in extraTabs where !tabs.contains(tab) {
      tabs.append(tab)
    }
    return tabs
  }
}

/// Atualiza contagens globais (Home + Filtros) sem recarregar listas inteiras.
@MainActor
enum GlobalDataRefresh {
  private static var refreshTask: _Concurrency.Task<Void, Never>?

  static func refreshDashboardCounts() async {
    async let home: Void = HomeStore.shared.refreshCounts()
    async let filters: Void = FiltersStore.shared.refreshDashboardCounts()
    _ = await (home, filters)
  }

  static func afterTaskMutation(invalidateTabs tabs: [NavTab] = []) {
    TabRefreshPolicy.invalidate(.home)
    TabRefreshPolicy.invalidate(.filters)
    for tab in tabs {
      TabRefreshPolicy.invalidate(tab)
    }
    refreshTask?.cancel()
    refreshTask = _Concurrency.Task {
      try? await _Concurrency.Task.sleep(for: .milliseconds(280))
      guard !_Concurrency.Task.isCancelled else { return }
      await refreshDashboardCounts()
    }
  }
}
