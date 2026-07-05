import Foundation
import SwiftUI

// Paridade lib/models/subtask.dart
struct Subtask: Identifiable, Equatable {
  let id: String?
  let taskId: String?
  let title: String
  let description: String?
  let done: Bool
  let priority: Priority?
  let order: Int
  let valor: Double?
  let dueDate: Date?
  /// FASE5: chip de vencimento memoizado em TaskMapper.mapSubtask.
  var dueDateChipLabel: String? = nil
  var dueDateChipColor: Color? = nil
  let labelIds: [String]

  var idOrFallback: String {
    if let id, !id.isEmpty { return id }
    if let taskId { return "\(taskId):\(order)" }
    return "sub-\(order)-\(title)"
  }
}
