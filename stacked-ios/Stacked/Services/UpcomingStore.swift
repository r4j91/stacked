import Foundation

enum UpcomingCalendarMode: String, CaseIterable, Identifiable {
  case month
  case week
  case agenda

  var id: String { rawValue }

  var label: String {
    switch self {
    case .month: "Mês"
    case .week: "Semana"
    case .agenda: "Agenda"
    }
  }
}

@MainActor
@Observable
final class UpcomingStore {
  static let shared = UpcomingStore()

  private let repo = TaskRepository.shared

  private(set) var tasks: [Task] = []
  private(set) var scheduledSubtasks: [SubtaskScheduleEntry] = []
  private(set) var calendarEvents: [CalendarEvent] = []
  private(set) var isLoading = false
  private(set) var error: String?

  var mode: UpcomingCalendarMode = .agenda
  var focusedDay = Date()
  var selectedDay: Date?

  private init() {}

  var filteredTasks: [Task] {
    guard let selectedDay else { return tasks }
    return tasks.filter { task in
      guard let due = task.dueDate else { return false }
      return TaskMapper.isSameDay(due, selectedDay)
    }
  }

  var groupedTasks: [(day: Date, tasks: [Task])] {
    TaskMapper.groupTasksByDay(filteredTasks)
  }

  var filteredSubtasks: [SubtaskScheduleEntry] {
    guard let selectedDay else { return scheduledSubtasks }
    return scheduledSubtasks.filter { entry in
      guard let due = entry.subtask.dueDate else { return false }
      return TaskMapper.isSameDay(due, selectedDay)
    }
  }

  private(set) var groupedSchedule: [(day: Date, items: [ScheduleItem])] = []

  private func rebuildScheduleDerived() {
    let events: [CalendarEvent]
    if let selectedDay {
      events = calendarEvents.filter { TaskMapper.isSameDay($0.day, selectedDay) }
    } else {
      events = calendarEvents
    }
    groupedSchedule = TaskMapper.groupScheduleItems(
      tasks: filteredTasks,
      subtasks: filteredSubtasks,
      events: events
    )
  }

  var daysWithTasks: Set<Date> {
    var days = Set(tasks.compactMap { task in
      task.dueDate.map(TaskMapper.startOfDay)
    })
    for entry in scheduledSubtasks {
      if let due = entry.subtask.dueDate {
        days.insert(TaskMapper.startOfDay(due))
      }
    }
    for event in calendarEvents {
      days.insert(event.day)
    }
    return days
  }

  func reloadCalendarEvents() async {
    calendarEvents = EventKitCalendarService.shared.fetchUpcomingEvents()
    rebuildScheduleDerived()
  }

  /// Virada de dia / foreground — reavalia chips relativos a “Hoje”.
  func refreshRelativeDateChips() {
    TaskMapper.refreshDisplayMemos(in: &tasks)
    scheduledSubtasks = scheduledSubtasks.map { entry in
      var sub = entry.subtask
      var parent = entry.parent
      TaskMapper.applyDisplayMemos(to: &sub)
      TaskMapper.applyDisplayMemos(to: &parent)
      return SubtaskScheduleEntry(subtask: sub, parent: parent)
    }
    rebuildScheduleDerived()
  }

  var agendaPeriodLabel: String {
    let taskDates = tasks.compactMap(\.dueDate)
    let subtaskDates = scheduledSubtasks.compactMap { $0.subtask.dueDate }
    let dated = (taskDates + subtaskDates).sorted()
    guard let first = dated.first, let last = dated.last else { return "Agenda" }
    let firstLabel = TaskMapper.dayLabel(for: first)
    let lastLabel = TaskMapper.dayLabel(for: last)
    return firstLabel == lastLabel ? firstLabel : "\(firstLabel) – \(lastLabel)"
  }

  func applySubtaskPatch(_ snapshot: SubtaskSaveSnapshot) {
    SubtaskListPatch.apply(snapshot, to: &tasks)
    if snapshot.done || snapshot.dueDate == nil {
      scheduledSubtasks.removeAll {
        $0.parent.id == snapshot.parentTaskId && $0.subtask.order == snapshot.order
      }
    }
    rebuildScheduleDerived()
  }

  func removeSubtask(parentId: String, subtask: Subtask) {
    SubtaskListPatch.remove(parentTaskId: parentId, subtask: subtask, from: &tasks)
    if let id = subtask.id {
      scheduledSubtasks.removeAll { $0.subtask.id == id }
    } else {
      scheduledSubtasks.removeAll {
        $0.parent.id == parentId && $0.subtask.order == subtask.order
      }
    }
    rebuildScheduleDerived()
  }

  // NET_FASEC_ETAPA2
  func insertOptimistic(_ task: Task) {
    guard !tasks.contains(where: { $0.id == task.id }) else { return }
    tasks.insert(task, at: 0)
    rebuildScheduleDerived()
  }

  func load() async {
    isLoading = tasks.isEmpty
    error = nil
    defer { isLoading = false }
    do {
      async let taskReq = repo.fetchDatedPendingTasks()
      async let subtaskReq = SubtaskRepository.shared.fetchDatedPendingScheduleEntries()
      let (fetchedTasks, fetchedSubs) = try await (taskReq, subtaskReq)
      tasks = fetchedTasks
      scheduledSubtasks = fetchedSubs
      calendarEvents = EventKitCalendarService.shared.fetchUpcomingEvents()
      rebuildScheduleDerived()
    } catch {
      if AsyncLoad.isCancellation(error) { return }
      self.error = error.localizedDescription
    }
    WidgetSnapshotSync.refreshAll()
  }

  func toggleDaySelection(_ day: Date) {
    let normalized = TaskMapper.startOfDay(day)
    if let selectedDay, TaskMapper.isSameDay(selectedDay, normalized) {
      self.selectedDay = nil
    } else {
      selectedDay = normalized
    }
    rebuildScheduleDerived()
  }

  func completeScheduledSubtask(_ entry: SubtaskScheduleEntry) {
    guard let subId = entry.subtask.id else { return }
    scheduledSubtasks.removeAll { $0.id == entry.id }
    rebuildScheduleDerived()
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
      GlobalDataRefresh.afterTaskMutation(invalidateTabs: [.upcoming])
    }
  }

  func complete(_ task: Task) {
    guard let i = tasks.firstIndex(where: { $0.id == task.id }) else { return }
    guard !tasks[i].done else { return }

    let originalIndex = i
    let snapshot = tasks[i]
    let taskId = task.id

    tasks[i].done = true
    // Rebuild já no dwell — a UI lê groupedSchedule (cópias).
    // Sem isso o DoneCircle nunca vê done=true e a animação some.
    rebuildScheduleDerived()
    HapticService.taskCompleted()

    TaskCompletionMotion.afterDwell(
      animatedRemoval: { [self] in
        tasks.removeAll { $0.id == taskId }
        rebuildScheduleDerived()
      },
      persist: {
        if let newId = try await self.repo.completeTask(snapshot) {
          await TaskCalendarSync.syncTaskId(newId)
          await TabDataLoader.load(.upcoming)
        }
        TaskCalendarSync.remove(taskId: taskId)
        GlobalDataRefresh.afterTaskMutation(invalidateTabs: [.upcoming])
      },
      rollback: { [self] in
        var restored = snapshot
        restored.done = false
        tasks.insert(restored, at: min(originalIndex, tasks.count))
        rebuildScheduleDerived()
      }
    )
  }

  func delete(_ task: Task) {
    tasks.removeAll { $0.id == task.id }
    rebuildScheduleDerived()
    TaskCalendarSync.remove(taskId: task.id)
    _Concurrency.Task {
      try? await repo.deleteTask(id: task.id)
      GlobalDataRefresh.afterTaskMutation(invalidateTabs: [.upcoming])
    }
  }

  func postpone(_ task: Task) async {
    let iso = TaskMapper.postponedDateISO(for: task)
    try? await repo.updateTaskDate(id: task.id, isoDate: iso)
    await load()
  }
}
