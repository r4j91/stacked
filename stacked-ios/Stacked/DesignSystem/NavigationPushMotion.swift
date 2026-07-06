import SwiftUI

/// Coordena handoffs de estado após push/pop do NavigationStack — evita layout thrash na transição.
@MainActor
enum NavigationPushMotion {
  static func awaitSettle() async {
    await _Concurrency.Task.yield()
    try? await _Concurrency.Task.sleep(for: .milliseconds(32))
    await _Concurrency.Task.yield()
    try? await _Concurrency.Task.sleep(for: AppMotion.navigationPushSettle)
    await _Concurrency.Task.yield()
  }

  static func afterSettle(_ body: () -> Void) async {
    await awaitSettle()
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction, body)
  }
}
