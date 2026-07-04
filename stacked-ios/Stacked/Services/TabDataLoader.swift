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
