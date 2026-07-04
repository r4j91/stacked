import Foundation

/// Evita reload de rede a cada troca de aba — stale-while-revalidate (Fase I).
/// Carregamento inicial: `TabDataLoader` + prefetch escalonado em `TabBootstrapCoordinator`.
@MainActor
enum TabRefreshPolicy {
  private static let staleInterval: TimeInterval = 45
  private static var lastLoaded: [NavTab: Date] = [:]

  static func shouldRefresh(_ tab: NavTab) -> Bool {
    guard let last = lastLoaded[tab] else { return true }
    return Date().timeIntervalSince(last) >= staleInterval
  }

  static func markLoaded(_ tab: NavTab) {
    lastLoaded[tab] = Date()
  }

  static func invalidate(_ tab: NavTab? = nil) {
    if let tab {
      lastLoaded.removeValue(forKey: tab)
    } else {
      lastLoaded.removeAll()
    }
  }
}
