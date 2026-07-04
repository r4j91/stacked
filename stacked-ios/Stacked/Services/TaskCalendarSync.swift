import Foundation

/// Ponte entre tarefas Stacked e o Calendário do iPhone (export).
@MainActor
enum TaskCalendarSync {
  static func sync(_ task: Task) {
    EventKitCalendarService.shared.syncTask(task)
  }

  static func remove(taskId: String) {
    EventKitCalendarService.shared.removeEvent(forTaskId: taskId)
  }

  static func syncTaskId(_ taskId: String) async {
    guard CalendarPreferences.exportEnabled else { return }
    guard let task = try? await TaskRepository.shared.fetchTaskById(taskId) else { return }
    sync(task)
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
}
