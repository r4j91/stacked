import SwiftUI

// Paridade lib/widgets/task_tile.dart + screen titles
enum AppTypography {
  static let screenTitle: Font = .system(size: 30, weight: .heavy)
  static let screenGreeting: Font = .system(size: 28, weight: .heavy)
  static let sheetTitle: Font = .system(size: 20, weight: .bold)
  static let taskTitle: Font = .system(size: 15.5, weight: .semibold)
  static let taskPreview: Font = .system(size: 13)
  static let body: Font = .system(size: 14)
  static let bodySemibold: Font = .system(size: 15, weight: .semibold)
  static let meta: Font = .system(size: 12)
  static let metaSmall: Font = .system(size: 11)
  static let sectionLabel: Font = .system(size: 11, weight: .bold)
  static let badge: Font = .system(size: 12, weight: .medium)
  static let navLabel: Font = .system(size: 10.5, weight: .regular)
  static let navLabelSelected: Font = .system(size: 10.5, weight: .semibold)

  // Auth (Slate branded)
  static let authTitle: Font = .system(size: 40, weight: .heavy)
  static let authSubtitle: Font = .system(size: 14)
  static let fieldLabel: Font = .system(size: 13)
  static let fieldInput: Font = .system(size: 14)
  static let authLink: Font = .system(size: 13)
  static let screenSubtitle: Font = .system(size: 12.5)
  static let drillDownTitle: Font = .system(size: 22, weight: .heavy)
}
