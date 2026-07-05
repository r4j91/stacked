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

  var groupedSchedule: [(day: Date, items: [ScheduleItem])] {
    let events: [CalendarEvent]
    if let selectedDay {
      events = calendarEvents.filter { TaskMapper.isSameDay($0.day, selectedDay) }
    } else {
      events = calendarEvents
    }
    return TaskMapper.groupScheduleItems(tasks: filteredTasks, events: events)
  }

  var daysWithTasks: Set<Date> {
    var days = Set(tasks.compactMap { task in
      task.dueDate.map(TaskMapper.startOfDay)
    })
    for event in calendarEvents {
      days.insert(event.day)
    }
    return days
  }

  func reloadCalendarEvents() async {
    calendarEvents = EventKitCalendarService.shared.fetchUpcomingEvents()
  }

  var agendaPeriodLabel: String {
    let dated = tasks.compactMap(\.dueDate).sorted()
    guard let first = dated.first, let last = dated.last else { return "Agenda" }
    let firstLabel = TaskMapper.dayLabel(for: first)
    let lastLabel = TaskMapper.dayLabel(for: last)
    return firstLabel == lastLabel ? firstLabel : "\(firstLabel) – \(lastLabel)"
  }

  func applySubtaskPatch(_ snapshot: SubtaskSaveSnapshot) {
    SubtaskListPatch.apply(snapshot, to: &tasks)
  }

  func load() async {
    isLoading = tasks.isEmpty
    error = nil
    do {
      tasks = try await repo.fetchDatedPendingTasks()
      calendarEvents = EventKitCalendarService.shared.fetchUpcomingEvents()
    } catch {
      if AsyncLoad.isCancellation(error) { return }
      self.error = error.localizedDescription
    }
    isLoading = false
  }

  func toggleDaySelection(_ day: Date) {
    let normalized = TaskMapper.startOfDay(day)
    if let selectedDay, TaskMapper.isSameDay(selectedDay, normalized) {
      self.selectedDay = nil
    } else {
      selectedDay = normalized
    }
  }

  func complete(_ task: Task) {
    guard let i = tasks.firstIndex(where: { $0.id == task.id }) else { return }
    guard !tasks[i].done else { return }

    let originalIndex = i
    let snapshot = tasks[i]
    let taskId = task.id

    tasks[i].done = true
    HapticService.taskCompleted()

    TaskCompletionMotion.afterDwell(
      animatedRemoval: { [self] in
        tasks.removeAll { $0.id == taskId }
      },
      persist: {
        try await self.repo.toggleTaskDone(id: taskId, done: true)
        TaskCalendarSync.remove(taskId: taskId)
      },
      rollback: { [self] in
        var restored = snapshot
        restored.done = false
        tasks.insert(restored, at: min(originalIndex, tasks.count))
      }
    )
  }

  func delete(_ task: Task) {
    tasks.removeAll { $0.id == task.id }
    TaskCalendarSync.remove(taskId: task.id)
    _Concurrency.Task {
      try? await repo.deleteTask(id: task.id)
    }
  }

  func postpone(_ task: Task) async {
    let iso = TaskMapper.postponedDateISO(for: task)
    try? await repo.updateTaskDate(id: task.id, isoDate: iso)
    await load()
  }
}
