import Foundation

/// Evita reload completo da lista ao fechar o detalhe sem mutações (Fase I perf).
@MainActor
enum TaskDetailDismissRefresh {
  static func afterDismiss(tab: NavTab, reload: () async -> Void) async {
    guard TabRefreshPolicy.shouldRefresh(tab) else { return }
    await reload()
  }
}
