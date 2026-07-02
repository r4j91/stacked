import Foundation

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
  let labelIds: [String]

  var idOrFallback: String { id ?? UUID().uuidString }
}
