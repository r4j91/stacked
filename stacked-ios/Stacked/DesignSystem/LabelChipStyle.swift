import SwiftUI

/// Visual das etiquetas na meta line de tarefas/subtarefas (Aparência).
/// Só labels usam esta preferência — data tem `DueDateChipStyle` próprio.
enum LabelChipStyle: String, CaseIterable, Identifiable {
  /// Atual: fill translúcido + borda.
  case soft
  /// A — ícone + texto na cor, sem container.
  case flat
  /// B — ponto sólido + texto neutro.
  case dot
  /// C — ícone na cor + texto secundário, sem container.
  case ink
  /// D — só borda fina, sem fill.
  case outline

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .soft: "Suave"
    case .flat: "Plano"
    case .dot: "Ponto"
    case .ink: "Ícone"
    case .outline: "Traço"
    }
  }

  var subtitle: String {
    switch self {
    case .soft: "Fundo translúcido e borda (atual)"
    case .flat: "Só ícone e texto na cor da etiqueta"
    case .dot: "Bolinha colorida e nome em cinza"
    case .ink: "Ícone colorido e texto secundário"
    case .outline: "Contorno fino, sem preenchimento"
    }
  }
}

enum LabelChipStyleStorage {
  static let key = "labelChipStyle"

  static var defaultRawValue: String { LabelChipStyle.flat.rawValue }

  static func style(from rawValue: String) -> LabelChipStyle {
    LabelChipStyle(rawValue: rawValue) ?? .flat
  }

  static var current: LabelChipStyle {
    style(from: UserDefaults.standard.string(forKey: key) ?? defaultRawValue)
  }
}
