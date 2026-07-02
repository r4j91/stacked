import SwiftUI

// Paridade lib/models/label.dart
struct TaskLabel: Identifiable, Equatable {
  let id: String
  let name: String
  let color: Color

  init(id: String, name: String, color: Color) {
    self.id = id
    self.name = name
    self.color = color
  }
}
