import SwiftUI

// Paridade lib/models/task.dart — Priority
enum Priority: String, Codable, CaseIterable {
  case high
  case medium
  case low

  var color: Color {
    switch self {
    case .high: AppColors.priorityHigh
    case .medium: AppColors.priorityMedium
    case .low: AppColors.priorityLow
    }
  }

  var label: String {
    switch self {
    case .high: "P1"
    case .medium: "P2"
    case .low: "P3"
    }
  }

  static func parse(_ value: String?) -> Priority? {
    guard let value else { return nil }
    return Priority(rawValue: value)
  }
}
