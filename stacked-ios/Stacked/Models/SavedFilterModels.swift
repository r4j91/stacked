import Foundation
import SwiftUI

enum FilterDateScope: String, Codable, CaseIterable, Equatable {
  case any
  case overdue
  case today
  case week
  case noDate = "no_date"

  var title: String {
    switch self {
    case .any: "Qualquer"
    case .overdue: "Atrasadas"
    case .today: "Hoje"
    case .week: "Próximos 7 dias"
    case .noDate: "Sem data"
    }
  }
}

enum FilterPriorityCriteria: String, Codable, CaseIterable, Equatable {
  case high
  case medium
  case low
  case none

  var menuLabel: String {
    switch self {
    case .high: "Prioridade 1"
    case .medium: "Prioridade 2"
    case .low: "Prioridade 3"
    case .none: "Sem prioridade"
    }
  }

  var iconColor: Color {
    switch self {
    case .high: AppColors.priorityHigh
    case .medium: AppColors.priorityMedium
    case .low: AppColors.priorityLow
    case .none: AppColors.textTertiaryFallback
    }
  }

  static func from(priority: Priority?) -> FilterPriorityCriteria {
    guard let priority else { return .none }
    switch priority {
    case .high: return .high
    case .medium: return .medium
    case .low: return .low
    }
  }
}

struct FilterCriteria: Equatable, Codable {
  var labelIds: [String]
  var priorities: [FilterPriorityCriteria]
  var projectId: String?
  var dateScope: FilterDateScope

  static let empty = FilterCriteria(
    labelIds: [],
    priorities: [],
    projectId: nil,
    dateScope: .any
  )
}

struct SavedFilter: Identifiable, Equatable, Codable {
  let id: String
  var name: String
  var colorHex: String?
  var criteria: FilterCriteria
  var sortOrder: Int
}

struct SavedFilterWithCount: Identifiable, Equatable {
  var id: String { filter.id }
  let filter: SavedFilter
  let pendingCount: Int
}

enum FilterCriteriaSummary {
  static func text(
    _ criteria: FilterCriteria,
    labels: [TaskLabel],
    projects: [Project]
  ) -> String {
    var parts: [String] = []
    if !criteria.labelIds.isEmpty {
      let names = criteria.labelIds.compactMap { id in labels.first(where: { $0.id == id })?.name }
      if names.count == 1, let name = names.first {
        parts.append("Etiqueta \(name)")
      } else if names.count > 1 {
        parts.append("\(names.count) etiquetas")
      }
    }
    if criteria.priorities.count == 1, let p = criteria.priorities.first {
      parts.append(p == .high ? "Prioridade Alta" : p == .medium ? "Prioridade Média" : p == .low ? "Prioridade Baixa" : "Sem prioridade")
    } else if criteria.priorities.count > 1 {
      parts.append("\(criteria.priorities.count) prioridades")
    }
    if let pid = criteria.projectId, let project = projects.first(where: { $0.id == pid }) {
      parts.append(project.name)
    }
    if criteria.dateScope != .any {
      parts.append(criteria.dateScope.title)
    }
    return parts.isEmpty ? "Todos os critérios" : parts.joined(separator: " · ")
  }
}

private extension AppColors {
  static var textTertiaryFallback: Color { Color(hex: 0x6B6E76) }
}
