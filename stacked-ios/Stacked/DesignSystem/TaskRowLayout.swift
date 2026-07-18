import SwiftUI

/// Layout da linha de tarefa (Aparência) — F2 / X2 dos mocks web.
enum TaskRowLayout: String, CaseIterable, Identifiable {
  /// Layout atual: título + meta em linha.
  case `default`
  /// F2 — projeto · prioridade no eyebrow; agenda fundida plana na meta.
  case f2
  /// X2 — projeto no eyebrow; prioridade + agenda fundida plana na meta.
  case x2

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .default: "Atual"
    case .f2: "Eyebrow"
    case .x2: "Híbrida"
    }
  }

  var subtitle: String {
    switch self {
    case .default: "Título + meta em linha (projeto, hora, data, etiquetas)"
    case .f2: "Projeto · prioridade acima; agenda fundida plana na meta"
    case .x2: "Projeto acima; prioridade + agenda fundida plana na meta"
    }
  }

  var usesEyebrow: Bool {
    self == .f2 || self == .x2
  }
}

enum TaskRowLayoutStorage {
  static let key = "taskRowLayout"

  static var defaultRawValue: String { TaskRowLayout.default.rawValue }

  static func layout(from rawValue: String) -> TaskRowLayout {
    TaskRowLayout(rawValue: rawValue) ?? .default
  }

  static var current: TaskRowLayout {
    layout(from: UserDefaults.standard.string(forKey: key) ?? defaultRawValue)
  }

  static func showsEyebrow(
    layout: TaskRowLayout = current,
    projectName: String?,
    showProject: Bool,
    priority: Priority?
  ) -> Bool {
    guard layout.usesEyebrow else { return false }
    let hasProject =
      showProject
      && !(projectName ?? "").isEmpty
      && projectName != "Sem projeto"
    if layout == .f2 {
      return hasProject || priority != nil
    }
    return hasProject
  }
}
