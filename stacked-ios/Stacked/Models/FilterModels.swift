import Foundation

// Paridade lib/services/task_repository.dart
enum TaskFilterKind: String, CaseIterable, Identifiable {
  case overdue
  case today
  case week
  case completedToday

  var id: String { rawValue }

  var title: String {
    switch self {
    case .overdue: "Atrasadas"
    case .today: "Hoje"
    case .week: "Próximos 7 dias"
    case .completedToday: "Concluídas hoje"
    }
  }

  var stackedIcon: StackedIconKey {
    switch self {
    case .overdue: .exclamation
    case .today: .navToday
    case .week: .navUpcoming
    case .completedToday: .checkCircle
    }
  }
}

struct FilterDashboardCounts: Equatable {
  let overdue: Int
  let today: Int
  let week: Int
  let completedToday: Int
}

struct ProjectTaskStats: Identifiable, Equatable {
  let id: String
  let name: String
  let colorHex: String?
  let iconKey: String?
  let pending: Int
  let total: Int
}
