import SwiftUI

/// Visual da data na meta line de tarefas/subtarefas (Aparência).
enum DueDateChipStyle: String, CaseIterable, Identifiable {
  /// Atual: fill + borda + ícone (agora sem dia fixo no glyph).
  case soft
  /// Ícone + texto na cor, sem container.
  case flat
  /// Só o texto colorido (“Hoje”, “17 jul”).
  case plain
  /// Badge com o dia do mês real + rótulo.
  case day
  /// Contorno fino, sem fill.
  case outline

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .soft: "Suave"
    case .flat: "Plano"
    case .plain: "Texto"
    case .day: "Dia"
    case .outline: "Traço"
    }
  }

  var subtitle: String {
    switch self {
    case .soft: "Fundo translúcido, borda e calendário (atual)"
    case .flat: "Calendário + texto na cor, sem container"
    case .plain: "Só o texto colorido, sem ícone"
    case .day: "Número do dia real + rótulo ao lado"
    case .outline: "Contorno fino, sem preenchimento"
    }
  }
}

enum DueDateChipStyleStorage {
  static let key = "dueDateChipStyle"

  static var defaultRawValue: String { DueDateChipStyle.flat.rawValue }

  static func style(from rawValue: String) -> DueDateChipStyle {
    DueDateChipStyle(rawValue: rawValue) ?? .flat
  }

  static var current: DueDateChipStyle {
    style(from: UserDefaults.standard.string(forKey: key) ?? defaultRawValue)
  }
}
