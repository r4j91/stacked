import SwiftUI

// Paridade lib/models/label.dart
struct TaskLabel: Identifiable, Equatable {
  let id: String
  let name: String
  let color: Color
  let sortOrder: Int

  init(id: String, name: String, color: Color, sortOrder: Int = 0) {
    self.id = id
    self.name = name
    self.color = color
    self.sortOrder = sortOrder
  }
}
