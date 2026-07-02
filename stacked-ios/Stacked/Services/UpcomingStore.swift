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

  var daysWithTasks: Set<Date> {
    Set(tasks.compactMap { task in
      task.dueDate.map(TaskMapper.startOfDay)
    })
  }

  var agendaPeriodLabel: String {
    let dated = tasks.compactMap(\.dueDate).sorted()
    guard let first = dated.first, let last = dated.last else { return "Agenda" }
    let firstLabel = TaskMapper.dayLabel(for: first)
    let lastLabel = TaskMapper.dayLabel(for: last)
    return firstLabel == lastLabel ? firstLabel : "\(firstLabel) – \(lastLabel)"
  }

  func load() async {
    isLoading = tasks.isEmpty
    error = nil
    do {
      tasks = try await repo.fetchDatedPendingTasks()
    } catch {
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
    tasks.removeAll { $0.id == task.id }
    HapticService.taskCompleted()
    _Concurrency.Task {
      try? await repo.toggleTaskDone(id: task.id, done: true)
    }
  }

  func delete(_ task: Task) {
    tasks.removeAll { $0.id == task.id }
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
