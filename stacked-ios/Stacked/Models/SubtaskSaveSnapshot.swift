import Foundation

/// Estado salvo de uma subtarefa — usado para patch otimista nas listas antes do reload.
struct SubtaskSaveSnapshot: Sendable {
  let parentTaskId: String
  let order: Int
  let resolvedId: String?
  let title: String
  let description: String?
  let done: Bool
  let priority: Priority?
  let dueDate: Date?
  let time: String?
  let labelIds: [String]
}

enum SubtaskListPatch {
  static func apply(_ snapshot: SubtaskSaveSnapshot, to tasks: inout [Task]) {
    guard let taskIndex = tasks.firstIndex(where: { $0.id == snapshot.parentTaskId }) else { return }
    apply(snapshot, to: &tasks[taskIndex].subtasks)
  }

  static func apply(_ snapshot: SubtaskSaveSnapshot, to subtasks: inout [Subtask]) {
    guard let subIndex = subtasks.firstIndex(where: { $0.order == snapshot.order }) else { return }
    let previous = subtasks[subIndex]
    let due = snapshot.dueDate
    subtasks[subIndex] = Subtask(
      id: snapshot.resolvedId ?? previous.id,
      taskId: snapshot.parentTaskId,
      title: snapshot.title,
      description: snapshot.description,
      done: snapshot.done,
      priority: snapshot.priority,
      order: snapshot.order,
      valor: previous.valor,
      dueDate: due,
      time: snapshot.time,
      dueDateChipLabel: due.map { TaskMapper.dueDateChipLabel(for: $0) },
      dueDateChipColor: due.map { TaskMapper.dateColor(for: $0, done: snapshot.done) },
      labelIds: snapshot.labelIds
    )
    subtasks = TaskMapper.sortSubtasksForDisplay(subtasks)
  }
}

enum SubtaskSaveHandler {
  @MainActor
  static func handle(
    _ snapshot: SubtaskSaveSnapshot?,
    patch: ((SubtaskSaveSnapshot) -> Void)? = nil,
    reload: () async -> Void
  ) async {
    if let snapshot {
      TaskStore.shared.applySubtaskPatch(snapshot)
      patch?(snapshot)
    }
    await reload()
  }
}
