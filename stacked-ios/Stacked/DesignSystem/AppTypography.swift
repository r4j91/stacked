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
  /// Título de seção colapsável em detalhe de projeto.
  static let collapsibleSectionTitle: Font = .system(size: 14, weight: .bold)
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

  // Settings / sheets secundários
  static let profileName: Font = .system(size: 17, weight: .semibold)
  static let settingsTitle: Font = .system(size: 15, weight: .medium)
  static let sheetPageTitle: Font = .system(size: 16, weight: .bold)
  static let cardHeading: Font = .system(size: 13.5, weight: .semibold)
  static let metricHero: Font = .system(size: 36, weight: .heavy)
  static let metricHeroCompact: Font = .system(size: 32, weight: .heavy)
  static let popoverRowLabel: Font = .system(size: 15)

  // Fase K — tokens adicionais
  static let detailTitle: Font = .system(size: 22, weight: .bold)
  static let detailSectionLabel: Font = .system(size: 12, weight: .semibold)
  static let metadataLabel: Font = .system(size: 13, weight: .medium)
  static let commentBody: Font = .system(size: 14)
  static let emptyStateTitle: Font = .system(size: 16, weight: .semibold)
  static let emptyStateSubtitle: Font = .system(size: 13)
  static let completedSectionHeader: Font = .system(size: 13, weight: .semibold)
  static let metricValue: Font = .system(size: 28, weight: .heavy)
  static let metricLabel: Font = .system(size: 12, weight: .medium)
  static let filterRowTitle: Font = .system(size: 15, weight: .semibold)
  static let subtaskRowTitle: Font = .system(size: 14)
  static let subtaskPreview: Font = .system(size: 12)
  static let timeChip: Font = .system(size: 11)
  static let navRowTitle: Font = .system(size: 16, weight: .medium)
  static let navRowCount: Font = .system(size: 16, weight: .medium)
  static let statBadge: Font = .system(size: 12, weight: .bold)

  static func modeToggleLabel(selected: Bool) -> Font {
    .system(size: 13, weight: selected ? .semibold : .medium)
  }

  static func calendarDayNumber(selected: Bool) -> Font {
    .system(size: 16, weight: selected ? .bold : .semibold)
  }
}
