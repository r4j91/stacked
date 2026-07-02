import Foundation

enum AsyncLoad {
  /// Task cancelada pela view (ex.: auth gate recria a Home) — não é falha de rede/auth.
  static func isCancellation(_ error: Error) -> Bool {
    error is CancellationError || _Concurrency.Task.isCancelled
  }
}
