import Foundation
import SwiftUI

// Paridade lib/models/task.dart
struct Task: Identifiable, Equatable {
  let id: String
  var title: String
  var description: String?
  var project: String
  var projectId: String?
  var sectionId: String?
  var priority: Priority?
  var time: String?
  /// FASE5: formatado uma vez em TaskMapper.mapRow — não recalcular no body da row.
  var timeDisplay: String? = nil
  var labels: [TaskLabel]
  var subtasks: [Subtask]
  var dueDate: Date?
  /// FASE5: chip de vencimento memoizado no mapeamento.
  var dueDateChipLabel: String? = nil
  var dueDateChipColor: Color? = nil
  var done: Bool
  var commentCount: Int
  var recurrence: String?
  var whatsappRoutine: Bool = false
  /// PERF_FASEB2_ETAPA4: contadores memoizados — zero filter no body da row.
  var subtasksDoneCount: Int = 0
  var subtasksTotalCount: Int = 0
  var subtasksCounterLabel: String? = nil

  var tags: [String] { labels.map(\.name) }
  // PERF_FASEB2_ETAPA4: var subtasksDone: Int { subtasks.filter(\.done).count }
  // PERF_FASEB2_ETAPA4: var subtasksTotal: Int { subtasks.count }
  var subtasksDone: Int { subtasksDoneCount }
  var subtasksTotal: Int { subtasksTotalCount }
  var hasSubtasks: Bool { !subtasks.isEmpty }
  var hasPendingSubtasks: Bool { subtasks.contains { !$0.done } }
  var hasDescription: Bool {
    guard let description else { return false }
    return !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  /// Meta line visível — espelha TaskMetaLine.hasMeta sem montar a view.
  var hasMetaLine: Bool {
    let showsProject = !project.isEmpty && project != "Sem projeto"
    return showsProject
      || !labels.isEmpty
      || priority != nil
      || dueDate != nil
      || subtasksTotalCount > 0
      || commentCount > 0
  }
}
