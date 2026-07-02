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
  static func afterDwell(
    animatedRemoval: @escaping @MainActor () -> Void,
    persist: @escaping () async throws -> Void,
    rollback: @escaping @MainActor () -> Void
  ) {
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

extension View {
  func taskCompleteRemovalTransition() -> some View {
    transition(TaskCompletionMotion.removalTransition)
  }
}
