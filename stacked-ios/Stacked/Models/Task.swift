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

  var tags: [String] { labels.map(\.name) }
  var subtasksDone: Int { subtasks.filter(\.done).count }
  var subtasksTotal: Int { subtasks.count }
  var hasSubtasks: Bool { !subtasks.isEmpty }
}
