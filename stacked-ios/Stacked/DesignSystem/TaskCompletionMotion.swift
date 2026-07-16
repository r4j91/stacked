import SwiftUI
import UIKit

// Fase 3B — dwell + remoção animada ao concluir tarefa (benchmark Todoist).
enum TaskCompletionMotion {
  static var reduceMotion: Bool {
    UIAccessibility.isReduceMotionEnabled
  }

  static let removalTransition: AnyTransition = .asymmetric(
    insertion: .opacity.combined(with: .move(edge: .top)),
    removal: .opacity.combined(with: .move(edge: .top))
  )

  /// Aguarda dwell, remove com AppMotion.smooth, persiste API e faz rollback animado em erro.
  /// `rowIdentity` marca o DoneCircle para animar o fill mesmo após remount UIKit (reconfigure).
  @MainActor
  static func afterDwell(
    rowIdentity: String,
    animatedRemoval: @escaping @MainActor () -> Void,
    persist: @escaping () async throws -> Void,
    rollback: @escaping @MainActor () -> Void
  ) {
    TaskCompleteAnimationBridge.mark(rowIdentity)
    let reduce = reduceMotion
    _Concurrency.Task {
      let dwell = AppMotion.duration(reduceMotion: reduce, normal: AppMotion.taskCompleteDwell)
      if dwell > .zero {
        try? await _Concurrency.Task.sleep(for: dwell)
      }
      await MainActor.run {
        AppMotion.animate(AppMotion.smooth, reduceMotion: reduce, animatedRemoval)
      }
      do {
        try await persist()
      } catch {
        await MainActor.run {
          AppMotion.animate(AppMotion.smooth, reduceMotion: reduce, rollback)
        }
      }
    }
  }
}

/// UIKit reconfigure remonta o DoneCircle com `done` já true e matava o fill.
/// Marca o id no tap; o círculo consome e toca a animação no (re)appear.
@MainActor
enum TaskCompleteAnimationBridge {
  private static var pending: Set<String> = []
  private static var clearTasks: [String: _Concurrency.Task<Void, Never>] = [:]

  static func mark(_ id: String) {
    guard !id.isEmpty else { return }
    pending.insert(id)
    clearTasks[id]?.cancel()
    clearTasks[id] = _Concurrency.Task { @MainActor in
      try? await _Concurrency.Task.sleep(for: .milliseconds(700))
      pending.remove(id)
      clearTasks[id] = nil
    }
  }

  static func consume(_ id: String) -> Bool {
    guard !id.isEmpty, pending.contains(id) else { return false }
    pending.remove(id)
    clearTasks[id]?.cancel()
    clearTasks[id] = nil
    return true
  }
}

extension View {
  func taskCompleteRemovalTransition() -> some View {
    transition(TaskCompletionMotion.removalTransition)
  }
}
