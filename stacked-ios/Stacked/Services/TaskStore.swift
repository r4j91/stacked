import Foundation

@MainActor
@Observable
final class TaskStore {
  static let shared = TaskStore()

  private let repo = TaskRepository.shared

  // Today
  private(set) var todayPending: [Task] = []
  private(set) var todayCompleted: [Task] = []
  private(set) var todayLoading = false
  private(set) var todayError: String?

  // Inbox
  private(set) var inboxPending: [Task] = []
  private(set) var inboxCompleted: [Task] = []
  private(set) var inboxLoading = false
  private(set) var inboxError: String?

  private init() {}

  var todayOverdue: [Task] { TaskMapper.splitTodayPending(todayPending).overdue }
  var todayOnly: [Task] { TaskMapper.splitTodayPending(todayPending).today }

  func loadToday() async {
    todayLoading = todayPending.isEmpty && todayCompleted.isEmpty
    todayError = nil
    do {
      async let pending = repo.fetchTodayTasks()
      async let completed = repo.fetchCompletedTodayTasks()
      let (p, c) = try await (pending, completed)
      todayPending = p
      todayCompleted = c
      WidgetSnapshotSync.updateFromToday(pending: p, completed: c)
    } catch {
      todayError = error.localizedDescription
    }
    todayLoading = false
  }

  func loadInbox() async {
    inboxLoading = inboxPending.isEmpty && inboxCompleted.isEmpty
    inboxError = nil
    do {
      async let pending = repo.fetchInboxTasks()
      async let completed = repo.fetchCompletedInboxTasks()
      let (p, c) = try await (pending, completed)
      inboxPending = p
      inboxCompleted = c
    } catch {
      inboxError = error.localizedDescription
    }
    inboxLoading = false
  }

  func completeToday(_ task: Task) {
    guard let i = todayPending.firstIndex(where: { $0.id == task.id }) else { return }
    var updated = todayPending[i]
    updated.done = true
    todayPending.remove(at: i)
    if !todayCompleted.contains(where: { $0.id == task.id }) {
      todayCompleted.insert(updated, at: 0)
    }
    HapticService.taskCompleted()
    WidgetSnapshotSync.updateFromToday(pending: todayPending, completed: todayCompleted)
    _Concurrency.Task {
      do {
        try await repo.toggleTaskDone(id: task.id, done: true)
      } catch {
        await MainActor.run {
          todayCompleted.removeAll { $0.id == task.id }
          todayPending.insert(task, at: min(i, todayPending.count))
        }
      }
    }
  }

  func completeInbox(_ task: Task) {
    guard let i = inboxPending.firstIndex(where: { $0.id == task.id }) else { return }
    var updated = inboxPending[i]
    updated.done = true
    inboxPending.remove(at: i)
    if !inboxCompleted.contains(where: { $0.id == task.id }) {
      inboxCompleted.insert(updated, at: 0)
    }
    HapticService.taskCompleted()
    _Concurrency.Task {
      do {
        try await repo.toggleTaskDone(id: task.id, done: true)
      } catch {
        await MainActor.run {
          inboxCompleted.removeAll { $0.id == task.id }
          inboxPending.insert(task, at: min(i, inboxPending.count))
        }
      }
    }
  }

  func deleteToday(_ task: Task) {
    let wasPending = todayPending.contains { $0.id == task.id }
    todayPending.removeAll { $0.id == task.id }
    todayCompleted.removeAll { $0.id == task.id }
    HapticService.taskDeleted()
    WidgetSnapshotSync.updateFromToday(pending: todayPending, completed: todayCompleted)
    _Concurrency.Task {
      try? await repo.deleteTask(id: task.id)
    }
    _ = wasPending
  }

  func deleteInbox(_ task: Task) {
    inboxPending.removeAll { $0.id == task.id }
    inboxCompleted.removeAll { $0.id == task.id }
    _Concurrency.Task {
      try? await repo.deleteTask(id: task.id)
    }
  }

  func postponeToday(_ task: Task) async throws {
    let iso = TaskMapper.postponedDateISO(for: task)
    try await repo.updateTaskDate(id: task.id, isoDate: iso)
    todayPending.removeAll { $0.id == task.id }
    await loadToday()
  }

  func postponeInbox(_ task: Task) async throws {
    let iso = TaskMapper.tomorrowISO()
    try await repo.updateTaskDate(id: task.id, isoDate: iso)
    inboxPending.removeAll { $0.id == task.id }
    await loadInbox()
  }

  func duplicateToday(_ task: Task) {
    _Concurrency.Task {
      _ = try? await repo.duplicateTask(task)
      await loadToday()
    }
  }

  func duplicateInbox(_ task: Task) {
    _Concurrency.Task {
      _ = try? await repo.duplicateTask(task)
      await loadInbox()
    }
  }
}
