import Foundation

/// Ordenação da lista de resultados de filtro salvo (⋮ do drill-down).
enum SavedFilterSortMode: String, CaseIterable {
  case dueDate
  case alphabetical
  case priority

  var label: String {
    switch self {
    case .dueDate: "Por vencimento"
    case .alphabetical: "Ordem alfabética"
    case .priority: "Por prioridade"
    }
  }
}

enum SavedFilterSortPreferences {
  static let defaultMode: SavedFilterSortMode = .dueDate

  static func key(filterId: String) -> String {
    "saved_filter_sort_\(filterId)"
  }

  static func mode(forFilterId filterId: String) -> SavedFilterSortMode {
    let raw = UserDefaults.standard.string(forKey: key(filterId: filterId))
    return SavedFilterSortMode(rawValue: raw ?? "") ?? defaultMode
  }

  static func set(_ mode: SavedFilterSortMode, forFilterId filterId: String) {
    UserDefaults.standard.set(mode.rawValue, forKey: key(filterId: filterId))
  }
}

enum FilterResultSorter {
  static func sort(_ items: [FilterResultItem], by mode: SavedFilterSortMode) -> [FilterResultItem] {
    switch mode {
    case .dueDate:
      return items.sorted {
        let lhs = dueDate(of: $0) ?? .distantFuture
        let rhs = dueDate(of: $1) ?? .distantFuture
        if lhs != rhs { return lhs < rhs }
        return title(of: $0).localizedCaseInsensitiveCompare(title(of: $1)) == .orderedAscending
      }
    case .alphabetical:
      return items.sorted {
        title(of: $0).localizedCaseInsensitiveCompare(title(of: $1)) == .orderedAscending
      }
    case .priority:
      return items.sorted {
        let lhs = priorityRank(of: $0)
        let rhs = priorityRank(of: $1)
        if lhs != rhs { return lhs < rhs }
        return title(of: $0).localizedCaseInsensitiveCompare(title(of: $1)) == .orderedAscending
      }
    }
  }

  private static func title(of item: FilterResultItem) -> String {
    switch item {
    case .task(let task): task.title
    case .subtask(let sub, _, _): sub.title
    }
  }

  private static func dueDate(of item: FilterResultItem) -> Date? {
    switch item {
    case .task(let task): task.dueDate
    case .subtask(let sub, _, _): sub.dueDate
    }
  }

  private static func priorityRank(of item: FilterResultItem) -> Int {
    let priority: Priority?
    switch item {
    case .task(let task): priority = task.priority
    case .subtask(let sub, _, _): priority = sub.priority
    }
    switch priority {
    case .high: return 0
    case .medium: return 1
    case .low: return 2
    case nil: return 3
    }
  }
}
