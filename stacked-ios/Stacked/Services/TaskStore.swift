import Foundation

@MainActor
@Observable
final class TaskStore {
  static let shared = TaskStore()

  private let repo = TaskRepository.shared

  // Today
  private(set) var todayPending: [Task] = []
  private(set) var todayCompleted: [Task] = []
  private(set) var todayScheduledSubtasks: [SubtaskScheduleEntry] = []
  private(set) var todayCalendarEvents: [CalendarEvent] = []
  private(set) var todayLoading = false
  private(set) var todayError: String?

  // Inbox
  private(set) var inboxPending: [Task] = []
  private(set) var inboxCompleted: [Task] = []
  private(set) var inboxLoading = false
  private(set) var inboxError: String?

  private init() {}

  private(set) var todayOverdue: [Task] = []
  private(set) var todayOverdueItems: [ScheduleItem] = []
  private(set) var todayOnly: [Task] = []
  private(set) var todayTimeline: [ScheduleItem] = []

  private func rebuildTodayDerived() {
    let split = TaskMapper.splitTodayPending(todayPending)
    todayOverdue = split.overdue
    todayOnly = split.today
    todayOverdueItems = TaskMapper.overdueScheduleItems(
      tasks: todayPending,
      subtasks: todayScheduledSubtasks
    )
    let todaySubtasks = TaskMapper.splitTodayScheduledSubtasks(todayScheduledSubtasks).today
    todayTimeline = TaskMapper.todayTimeline(
      tasks: split.today,
      subtasks: todaySubtasks,
      events: todayCalendarEvents
    )
  }

  func reloadCalendarEvents() async {
    todayCalendarEvents = EventKitCalendarService.shared.fetchTodayEvents()
    rebuildTodayDerived()
  }

  private var loadTodayGeneration = 0
  private var loadInboxGeneration = 0

  func applySubtaskPatch(_ snapshot: SubtaskSaveSnapshot) {
    SubtaskListPatch.apply(snapshot, to: &todayPending)
    SubtaskListPatch.apply(snapshot, to: &todayCompleted)
    SubtaskListPatch.apply(snapshot, to: &inboxPending)
    SubtaskListPatch.apply(snapshot, to: &inboxCompleted)
    if snapshot.done || snapshot.dueDate == nil {
      todayScheduledSubtasks.removeAll {
        $0.parent.id == snapshot.parentTaskId && $0.subtask.order == snapshot.order
      }
    }
    rebuildTodayDerived()
  }

  func loadToday() async {
    loadTodayGeneration += 1
    let generation = loadTodayGeneration
    todayLoading = todayPending.isEmpty
      && todayCompleted.isEmpty
      && todayScheduledSubtasks.isEmpty
      && todayCalendarEvents.isEmpty
    todayError = nil
    defer { todayLoading = false }
    do {
      async let pending = repo.fetchTodayTasks()
      async let completed = repo.fetchCompletedTodayTasks()
      async let scheduledSubs = SubtaskRepository.shared.fetchTodayScheduleEntries()
      let (p, c, subs) = try await (pending, completed, scheduledSubs)
      guard generation == loadTodayGeneration else { return }
      todayPending = p
      todayCompleted = c
      todayScheduledSubtasks = subs
      todayCalendarEvents = EventKitCalendarService.shared.fetchTodayEvents()
      rebuildTodayDerived()
      WidgetSnapshotSync.updateFromToday(pending: p, completed: c)
    } catch {
      if AsyncLoad.isCancellation(error) { return }
      guard generation == loadTodayGeneration else { return }
      todayError = error.localizedDescription
    }
  }

  func loadInbox() async {
    loadInboxGeneration += 1
    let generation = loadInboxGeneration
    inboxLoading = inboxPending.isEmpty && inboxCompleted.isEmpty
    inboxError = nil
    defer { inboxLoading = false }
    do {
      async let pending = repo.fetchInboxTasks()
      async let completed = repo.fetchCompletedInboxTasks()
      let (p, c) = try await (pending, completed)
      guard generation == loadInboxGeneration else { return }
      inboxPending = p
      inboxCompleted = c
    } catch {
      if AsyncLoad.isCancellation(error) { return }
      guard generation == loadInboxGeneration else { return }
      inboxError = error.localizedDescription
    }
  }

  func completeScheduledSubtask(_ entry: SubtaskScheduleEntry) {
    guard let subId = entry.subtask.id else { return }
    guard todayScheduledSubtasks.contains(where: { $0.id == entry.id }) else { return }

    todayScheduledSubtasks.removeAll { $0.id == entry.id }
    rebuildTodayDerived()
    HapticService.taskCompleted()

    _Concurrency.Task {
      try? await SubtaskRepository.shared.toggleDone(id: subId, done: true)
      await NotificationService.shared.cancelSubtaskNotification(id: subId)
      TaskCalendarSync.remove(subtaskId: subId)
      applySubtaskPatch(SubtaskSaveSnapshot(
        parentTaskId: entry.parent.id,
        order: entry.subtask.order,
        resolvedId: subId,
        title: entry.subtask.title,
        description: entry.subtask.description,
        done: true,
        priority: entry.subtask.priority,
        dueDate: entry.subtask.dueDate,
        time: entry.subtask.time,
        labelIds: entry.subtask.labelIds
      ))
      GlobalDataRefresh.afterTaskMutation(invalidateTabs: [.today])
    }
  }

  func completeToday(_ task: Task) {
    guard let i = todayPending.firstIndex(where: { $0.id == task.id }) else { return }
    guard !todayPending[i].done else { return }

    let originalIndex = i
    let snapshot = todayPending[i]
    let taskId = task.id

    todayPending[i].done = true
    HapticService.taskCompleted()

    TaskCompletionMotion.afterDwell(
      animatedRemoval: { [self] in
        guard let idx = todayPending.firstIndex(where: { $0.id == taskId }) else { return }
        var updated = todayPending[idx]
        updated.done = true
        todayPending.remove(at: idx)
        if !todayCompleted.contains(where: { $0.id == taskId }) {
          todayCompleted.insert(updated, at: 0)
        }
        WidgetSnapshotSync.updateFromToday(pending: todayPending, completed: todayCompleted)
        rebuildTodayDerived()
      },
      persist: {
        if let newId = try await self.repo.completeTask(snapshot) {
          await TaskCalendarSync.syncTaskId(newId)
          await TabDataLoader.load(.today)
        }
        TaskCalendarSync.remove(taskId: taskId)
        GlobalDataRefresh.afterTaskMutation(invalidateTabs: [.today])
      },
      rollback: { [self] in
        todayCompleted.removeAll { $0.id == taskId }
        var restored = snapshot
        restored.done = false
        todayPending.insert(restored, at: min(originalIndex, todayPending.count))
        WidgetSnapshotSync.updateFromToday(pending: todayPending, completed: todayCompleted)
        rebuildTodayDerived()
      }
    )
  }

  func completeInbox(_ task: Task) {
    guard let i = inboxPending.firstIndex(where: { $0.id == task.id }) else { return }
    guard !inboxPending[i].done else { return }

    let originalIndex = i
    let snapshot = inboxPending[i]
    let taskId = task.id

    inboxPending[i].done = true
    HapticService.taskCompleted()

    TaskCompletionMotion.afterDwell(
      animatedRemoval: { [self] in
        guard let idx = inboxPending.firstIndex(where: { $0.id == taskId }) else { return }
        var updated = inboxPending[idx]
        updated.done = true
        inboxPending.remove(at: idx)
        if !inboxCompleted.contains(where: { $0.id == taskId }) {
          inboxCompleted.insert(updated, at: 0)
        }
      },
      persist: {
        if let newId = try await self.repo.completeTask(snapshot) {
          await TaskCalendarSync.syncTaskId(newId)
          await TabDataLoader.load(.inbox)
        }
        TaskCalendarSync.remove(taskId: taskId)
        GlobalDataRefresh.afterTaskMutation(invalidateTabs: [.inbox])
      },
      rollback: { [self] in
        inboxCompleted.removeAll { $0.id == taskId }
        var restored = snapshot
        restored.done = false
        inboxPending.insert(restored, at: min(originalIndex, inboxPending.count))
      }
    )
  }

  func deleteToday(_ task: Task) {
    let wasPending = todayPending.contains { $0.id == task.id }
    todayPending.removeAll { $0.id == task.id }
    todayCompleted.removeAll { $0.id == task.id }
    rebuildTodayDerived()
    HapticService.taskDeleted()
    WidgetSnapshotSync.updateFromToday(pending: todayPending, completed: todayCompleted)
    _Concurrency.Task {
      try? await repo.deleteTask(id: task.id)
      TaskCalendarSync.remove(taskId: task.id)
      GlobalDataRefresh.afterTaskMutation(invalidateTabs: [.today])
    }
    _ = wasPending
  }

  func deleteInbox(_ task: Task) {
    inboxPending.removeAll { $0.id == task.id }
    inboxCompleted.removeAll { $0.id == task.id }
    _Concurrency.Task {
      try? await repo.deleteTask(id: task.id)
      TaskCalendarSync.remove(taskId: task.id)
      GlobalDataRefresh.afterTaskMutation(invalidateTabs: [.inbox])
    }
  }

  func postponeToday(_ task: Task) async throws {
    let iso = TaskMapper.postponedDateISO(for: task)
    try await repo.updateTaskDate(id: task.id, isoDate: iso)
    todayPending.removeAll { $0.id == task.id }
    rebuildTodayDerived()
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
      if let newId = try? await repo.duplicateTask(task) {
        await TaskCalendarSync.syncTaskId(newId)
      }
      await loadToday()
    }
  }

  func duplicateInbox(_ task: Task) {
    _Concurrency.Task {
      if let newId = try? await repo.duplicateTask(task) {
        await TaskCalendarSync.syncTaskId(newId)
      }
      await loadInbox()
    }
  }
}

// SUBSTITUIDO_FASE3B: remoção imediata do pending no mesmo frame do tap
// func completeToday(_ task: Task) {
//   guard let i = todayPending.firstIndex(where: { $0.id == task.id }) else { return }
//   var updated = todayPending[i]
//   updated.done = true
//   todayPending.remove(at: i)
//   ...
// }
