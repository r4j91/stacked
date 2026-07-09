import Foundation

/// Ponte entre tarefas/subtarefas Stacked e o Calendário do iPhone (export).
@MainActor
enum TaskCalendarSync {
  static func sync(_ task: Task) {
    EventKitCalendarService.shared.syncTask(task)
  }

  static func sync(_ subtask: Subtask) {
    EventKitCalendarService.shared.syncSubtask(subtask)
  }

  static func remove(taskId: String) {
    EventKitCalendarService.shared.removeExportedTask(taskId: taskId)
  }

  static func remove(subtaskId: String) {
    EventKitCalendarService.shared.removeExportedSubtask(subtaskId: subtaskId)
  }

  static func syncTaskId(_ taskId: String) async {
    guard CalendarPreferences.exportEnabled else { return }
    guard let task = try? await TaskRepository.shared.fetchTaskById(taskId) else { return }
    sync(task)
  }

  static func syncSubtaskId(_ subtaskId: String) async {
    guard CalendarPreferences.exportEnabled else { return }
    let entries = (try? await SubtaskRepository.shared.fetchDatedPendingScheduleEntries()) ?? []
    guard let entry = entries.first(where: { $0.subtask.id == subtaskId }) else { return }
    sync(entry.subtask)
  }

  static func syncAfterMutation(taskId: String, title: String?, dueDate: Date?, time: String?, done: Bool) {
    guard CalendarPreferences.exportEnabled else { return }
    var task = Task(
      id: taskId,
      title: title ?? "",
      description: nil,
      project: "",
      projectId: nil,
      sectionId: nil,
      priority: nil,
      time: time,
      labels: [],
      subtasks: [],
      dueDate: dueDate,
      done: done,
      commentCount: 0,
      recurrence: nil
    )
    if let title { task.title = title }
    sync(task)
  }

  static func syncAfterSubtaskMutation(
    subtaskId: String,
    title: String?,
    dueDate: Date?,
    time: String?,
    done: Bool
  ) {
    guard CalendarPreferences.exportEnabled else { return }
    let subtask = Subtask(
      id: subtaskId,
      taskId: nil,
      title: title ?? "",
      description: nil,
      done: done,
      priority: nil,
      order: 0,
      valor: nil,
      dueDate: dueDate,
      time: time,
      labelIds: []
    )
    sync(subtask)
  }
}
