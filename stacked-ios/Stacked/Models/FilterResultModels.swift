import Foundation

enum FilterResultItem: Identifiable, Equatable {
  case task(Task)
  case subtask(Subtask, parent: Task, index: Int)

  var id: String {
    switch self {
    case .task(let task):
      return "task-\(task.id)"
    case .subtask(let sub, _, _):
      return "subtask-\(sub.idOrFallback)"
    }
  }
}

enum FilterResultCountLabel {
  static func text(for count: Int) -> String {
    switch count {
    case 0: return "0 itens"
    case 1: return "1 item"
    default: return "\(count) itens"
    }
  }
}

enum FilterMatcher {
  static func taskMatches(_ task: Task, criteria: FilterCriteria, todayStr: String, weekStr: String) -> Bool {
    if let projectId = criteria.projectId, task.projectId != projectId { return false }
    if !matchesPriority(task.priority, criteria: criteria.priorities) { return false }
    if !matchesLabels(task.labels.map(\.id), required: criteria.labelIds) { return false }
    if !matchesDate(task.dueDate, scope: criteria.dateScope, todayStr: todayStr, weekStr: weekStr) { return false }
    return true
  }

  static func subtaskMatches(
    _ sub: Subtask,
    parent: Task,
    criteria: FilterCriteria,
    todayStr: String,
    weekStr: String
  ) -> Bool {
    if let projectId = criteria.projectId, parent.projectId != projectId { return false }
    if !matchesPriority(sub.priority, criteria: criteria.priorities) { return false }
    if !matchesLabels(sub.labelIds, required: criteria.labelIds) { return false }
    if !matchesDate(sub.dueDate, scope: criteria.dateScope, todayStr: todayStr, weekStr: weekStr) { return false }
    return true
  }

  static func buildPendingResults(
    tasks: [Task],
    criteria: FilterCriteria,
    todayStr: String,
    weekStr: String
  ) -> [FilterResultItem] {
    var results: [FilterResultItem] = []
    for task in tasks where !task.done {
      if taskMatches(task, criteria: criteria, todayStr: todayStr, weekStr: weekStr) {
        results.append(.task(task))
        continue
      }
      for (index, sub) in task.subtasks.enumerated() where !sub.done {
        if subtaskMatches(sub, parent: task, criteria: criteria, todayStr: todayStr, weekStr: weekStr) {
          results.append(.subtask(sub, parent: task, index: index))
        }
      }
    }
    return results
  }

  static func buildCompletedResults(
    tasks: [Task],
    criteria: FilterCriteria,
    todayStr: String,
    weekStr: String
  ) -> [FilterResultItem] {
    var results: [FilterResultItem] = []
    for task in tasks {
      if task.done, taskMatches(task, criteria: criteria, todayStr: todayStr, weekStr: weekStr) {
        results.append(.task(task))
        continue
      }
      for (index, sub) in task.subtasks.enumerated() where sub.done {
        if subtaskMatches(sub, parent: task, criteria: criteria, todayStr: todayStr, weekStr: weekStr) {
          results.append(.subtask(sub, parent: task, index: index))
        }
      }
    }
    return results
  }

  private static func matchesPriority(_ priority: Priority?, criteria: [FilterPriorityCriteria]) -> Bool {
    guard !criteria.isEmpty else { return true }
    return criteria.contains(FilterPriorityCriteria.from(priority: priority))
  }

  private static func matchesLabels(_ labelIds: [String], required: [String]) -> Bool {
    guard !required.isEmpty else { return true }
    let ids = Set(labelIds)
    return required.allSatisfy { ids.contains($0) }
  }

  private static func matchesDate(
    _ due: Date?,
    scope: FilterDateScope,
    todayStr: String,
    weekStr: String
  ) -> Bool {
    switch scope {
    case .any:
      return true
    case .noDate:
      return due == nil
    case .overdue, .today, .week:
      guard let due else { return false }
      let dueStr = TaskMapper.dateString(due)
      switch scope {
      case .overdue:
        return dueStr < todayStr
      case .today:
        return dueStr == todayStr
      case .week:
        return dueStr > todayStr && dueStr <= weekStr
      default:
        return true
      }
    }
  }
}

enum FilterResultListPatch {
  static func apply(_ snapshot: SubtaskSaveSnapshot, to results: inout [FilterResultItem]) {
    for index in results.indices {
      switch results[index] {
      case .task(var task):
        guard task.id == snapshot.parentTaskId else { continue }
        SubtaskListPatch.apply(snapshot, to: &task.subtasks)
        results[index] = .task(task)
      case .subtask(_, let parent, let subIndex):
        guard parent.id == snapshot.parentTaskId, subIndex == snapshot.order else { continue }
        var updatedParent = parent
        SubtaskListPatch.apply(snapshot, to: &updatedParent.subtasks)
        guard subIndex < updatedParent.subtasks.count else { continue }
        results[index] = .subtask(updatedParent.subtasks[subIndex], parent: updatedParent, index: subIndex)
      }
    }
  }

  static func remove(parentTaskId: String, subtask: Subtask, from results: inout [FilterResultItem]) {
    results.removeAll { item in
      if case .subtask(let sub, let parent, _) = item {
        return parent.id == parentTaskId && (sub.id == subtask.id || sub.order == subtask.order)
      }
      return false
    }
    for index in results.indices {
      if case .task(var task) = results[index], task.id == parentTaskId {
        SubtaskListPatch.remove(subtask, from: &task.subtasks)
        results[index] = .task(task)
      }
    }
  }
}
