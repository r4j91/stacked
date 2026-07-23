import SwiftUI

/// Layout da linha de tarefa (Aparência) — F2 / X2 / C / G dos mocks.
enum TaskRowLayout: String, CaseIterable, Identifiable {
  /// Layout atual: título + meta em linha.
  case `default`
  /// F2 — projeto · prioridade no eyebrow; agenda fundida plana na meta.
  case f2
  /// X2 — projeto no eyebrow; prioridade + agenda fundida plana na meta.
  case x2
  /// C — hora (+ projeto) à direita; meta só com data/tags.
  case trailingTime
  /// G — lista densa: título menor + meta em texto corrido.
  case dense

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .default: "Atual"
    case .f2: "Eyebrow"
    case .x2: "Híbrida"
    case .trailingTime: "Hora à direita"
    case .dense: "Lista densa"
    }
  }

  var subtitle: String {
    switch self {
    case .default: "Título + meta em linha (projeto, hora, data, etiquetas)"
    case .f2: "Projeto · prioridade acima; agenda fundida plana na meta"
    case .x2: "Projeto acima; prioridade + agenda fundida plana na meta"
    case .trailingTime: "Hora e projeto à direita; chips só para data e etiquetas"
    case .dense: "Mais compacto: meta em uma linha de texto, sem chips"
    }
  }

  var usesEyebrow: Bool {
    self == .f2 || self == .x2
  }

  /// Hora/projeto na coluna trailing (layout C).
  var usesTrailingTimeColumn: Bool {
    self == .trailingTime
  }

  var isDense: Bool {
    self == .dense
  }
}

enum TaskRowLayoutStorage {
  static let key = "taskRowLayout"

  static var defaultRawValue: String { TaskRowLayout.f2.rawValue }

  static func layout(from rawValue: String) -> TaskRowLayout {
    TaskRowLayout(rawValue: rawValue) ?? .f2
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
