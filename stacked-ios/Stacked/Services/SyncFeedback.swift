import Foundation
import SwiftUI

/// Toast discreto — sync/retry e Desfazer de ações (mesmo visual).
@MainActor
@Observable
final class SyncFeedback {
  static let shared = SyncFeedback()

  struct Banner: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let taskId: String?
    let actionLabel: String?
    let action: (() -> Void)?
    /// `nil` = fica até dismiss/ação (erros de sync). Undo = 5s.
    let autoDismiss: TimeInterval?

    static func == (lhs: Banner, rhs: Banner) -> Bool {
      lhs.id == rhs.id
    }
  }

  private(set) var banner: Banner?
  private var autoDismissTask: _Concurrency.Task<Void, Never>?

  private init() {}

  func show(_ error: SyncError, taskId: String? = nil, retry: (() -> Void)? = nil) {
    guard error.shouldShowToast, let message = error.userMessage else { return }
    present(
      Banner(
        message: message,
        taskId: taskId,
        actionLabel: retry != nil ? "Tentar" : nil,
        action: retry,
        autoDismiss: nil
      )
    )
  }

  func showMessage(_ message: String, taskId: String? = nil, retry: (() -> Void)? = nil) {
    present(
      Banner(
        message: message,
        taskId: taskId,
        actionLabel: retry != nil ? "Tentar" : nil,
        action: retry,
        autoDismiss: nil
      )
    )
  }

  /// Toast de alívio imediato — Desfazer por 5s.
  func showUndo(message: String, action: @escaping () -> Void) {
    present(
      Banner(
        message: message,
        taskId: nil,
        actionLabel: "Desfazer",
        action: action,
        autoDismiss: 5
      )
    )
  }

  /// Descarta toast se a sync do mesmo id concluiu depois (falso positivo).
  func clearSuccess(for taskId: String) {
    guard banner?.taskId == taskId else { return }
    dismiss()
  }

  func dismiss() {
    autoDismissTask?.cancel()
    autoDismissTask = nil
    banner = nil
  }

  func invokeAction() {
    let action = banner?.action
    dismiss()
    action?()
  }

  private func present(_ next: Banner) {
    autoDismissTask?.cancel()
    banner = next
    guard let seconds = next.autoDismiss, seconds > 0 else { return }
    let id = next.id
    autoDismissTask = _Concurrency.Task { @MainActor in
      try? await _Concurrency.Task.sleep(for: .seconds(seconds))
      guard !_Concurrency.Task.isCancelled, banner?.id == id else { return }
      banner = nil
      autoDismissTask = nil
    }
  }
}

// MARK: - Pending delete (hard delete após 5s, como na web)

@MainActor
enum PendingTaskDeletion {
  private struct Entry {
    let timer: _Concurrency.Task<Void, Never>
    let restore: () -> Void
  }

  private static var entries: [String: Entry] = [:]

  static func schedule(
    id: String,
    restore: @escaping () -> Void,
    commit: @escaping () async -> Void,
    showToast: Bool = true
  ) {
    cancelTimer(id: id)

    let timer = _Concurrency.Task { @MainActor in
      try? await _Concurrency.Task.sleep(for: .seconds(5))
      guard !_Concurrency.Task.isCancelled else { return }
      entries.removeValue(forKey: id)
      await commit()
    }
    entries[id] = Entry(timer: timer, restore: restore)

    guard showToast else { return }
    SyncFeedback.shared.showUndo(message: "Tarefa excluída") {
      undo(id: id)
    }
  }

  static func undo(id: String) {
    guard let entry = entries.removeValue(forKey: id) else { return }
    entry.timer.cancel()
    entry.restore()
  }

  private static func cancelTimer(id: String) {
    if let existing = entries.removeValue(forKey: id) {
      existing.timer.cancel()
    }
  }
}

/// Estado compartilhado entre remoção local e persist — Desfazer pode chegar antes do `newId`.
@MainActor
final class CompleteUndoGate {
  var cancelled = false
  var occurrenceId: String?
}

// MARK: - Helpers de undo (concluir / adiar)

/// Remove a tarefa das listas em memória (detalhe → Desfazer) sem toast duplicado.
@MainActor
enum LocalTaskListUndo {
  struct RestoreToken {
    let restore: () -> Void
  }

  static func purge(id: String, snapshot: Task) -> [RestoreToken] {
    var tokens: [RestoreToken] = []
    if let token = TaskStore.shared.purgeLocally(id: id, snapshot: snapshot) {
      tokens.append(token)
    }
    if let token = UpcomingStore.shared.purgeLocally(id: id, snapshot: snapshot) {
      tokens.append(token)
    }
    return tokens
  }

  static func restore(_ tokens: [RestoreToken]) {
    for token in tokens { token.restore() }
  }
}

@MainActor
enum TaskActionUndo {
  static func presentCompleted(
    taskId: String,
    gate: CompleteUndoGate,
    restore: @escaping () -> Void
  ) {
    SyncFeedback.shared.showUndo(message: "Tarefa concluída") {
      gate.cancelled = true
      restore()
      _Concurrency.Task {
        try? await TaskRepository.shared.toggleTaskDone(id: taskId, done: false)
        if let occurrenceId = gate.occurrenceId {
          try? await TaskRepository.shared.deleteTask(id: occurrenceId)
          TaskCalendarSync.remove(taskId: occurrenceId)
        }
        await TaskCalendarSync.syncTaskId(taskId)
        GlobalDataRefresh.afterTaskMutation()
      }
    }
  }

  static func presentPostponed(
    taskId: String,
    plan: TaskPostponePlan,
    restore: @escaping () -> Void
  ) {
    SyncFeedback.shared.showUndo(message: "Tarefa adiada") {
      restore()
      _Concurrency.Task {
        let repo = TaskRepository.shared
        switch plan.field {
        case .dueDate:
          try? await repo.updateTaskDueDate(id: taskId, isoDate: plan.previousISO)
        case .deadline:
          try? await repo.updateTaskDeadline(id: taskId, isoDate: plan.previousISO)
        }
        GlobalDataRefresh.afterTaskMutation()
      }
    }
  }
}

struct SyncToastBanner: View {
  @Environment(ThemeManager.self) private var theme
  let banner: SyncFeedback.Banner

  var body: some View {
    let c = theme.colors
    Button {
      if banner.action != nil {
        SyncFeedback.shared.invokeAction()
      } else {
        SyncFeedback.shared.dismiss()
      }
    } label: {
      HStack(spacing: 10) {
        Text(banner.message)
          .font(AppTypography.meta)
          .foregroundStyle(c.textPrimary)
          .multilineTextAlignment(.leading)
        Spacer(minLength: 0)
        if let actionLabel = banner.actionLabel {
          Text(actionLabel)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(c.accent)
        }
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 12)
      .background(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .fill(c.surface)
          .shadow(color: .black.opacity(0.28), radius: 12, y: 4)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .stroke(c.textTertiary.opacity(0.18), lineWidth: 1)
      )
    }
    .buttonStyle(.plain)
    .padding(.horizontal, 16)
    .padding(.bottom, 12)
    .transition(.move(edge: .bottom).combined(with: .opacity))
  }
}
