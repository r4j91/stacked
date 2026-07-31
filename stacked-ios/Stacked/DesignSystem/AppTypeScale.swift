import SwiftUI

/// Escala dos títulos de seção e das linhas de navegação — vale para o app inteiro
/// (Home, Filtros, Hoje, Em breve, Busca e as listas hospedadas em UIKit).
/// `classic` mantém os tokens de sempre (eyebrow 11 + linha 16).
enum AppTypeScale: String, CaseIterable, Identifiable {
  case classic
  case large
  case eyebrow

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .classic: "Atual"
    case .large: "Título grande"
    case .eyebrow: "Eyebrow legível"
    }
  }

  var subtitle: String {
    switch self {
    case .classic: "Eyebrow 11 e linha 16 — como está hoje"
    case .large: "Header 17, linha 16.5 semibold"
    case .eyebrow: "Header 13 em caixa alta, linha igual"
    }
  }

  var metrics: AppTypeScaleMetrics {
    switch self {
    case .classic:
      return AppTypeScaleMetrics(
        headerFont: AppTypography.sectionLabel,
        headerTracking: 0.2,
        headerCase: .title,
        headerUsesPrimaryColor: false,
        actionFont: AppTypography.sectionLabel,
        rowTitleFont: AppTypography.navRowTitle,
        rowCountFont: AppTypography.navRowCount,
        navIconDelta: 0,
        navIconBoxDelta: 0,
        collapsedNavLabelSize: 13
      )
    case .large:
      return AppTypeScaleMetrics(
        headerFont: .system(size: 17, weight: .bold),
        headerTracking: -0.2,
        headerCase: .sentence,
        headerUsesPrimaryColor: true,
        actionFont: .system(size: 15, weight: .semibold),
        rowTitleFont: .system(size: 16.5, weight: .semibold),
        rowCountFont: .system(size: 15, weight: .medium),
        navIconDelta: 2,
        navIconBoxDelta: 2,
        collapsedNavLabelSize: 15
      )
    case .eyebrow:
      return AppTypeScaleMetrics(
        headerFont: .system(size: 13, weight: .bold),
        headerTracking: 0.5,
        headerCase: .upper,
        headerUsesPrimaryColor: false,
        actionFont: .system(size: 13.5, weight: .semibold),
        rowTitleFont: AppTypography.navRowTitle,
        rowCountFont: AppTypography.navRowCount,
        navIconDelta: 1,
        navIconBoxDelta: 1,
        collapsedNavLabelSize: 13.5
      )
    }
  }

  static var current: AppTypeScale {
    AppTypeScaleStorage.scale(from: UserDefaults.standard.string(forKey: AppTypeScaleStorage.key) ?? "")
  }
}

struct AppTypeScaleMetrics {
  let headerFont: Font
  let headerTracking: CGFloat
  let headerCase: AppSectionHeaderCase
  let headerUsesPrimaryColor: Bool
  /// Ações no header ("Editar", "+").
  let actionFont: Font
  let rowTitleFont: Font
  let rowCountFont: Font

  /// Navbar. O ícone acompanha a escala em todos os estilos, mas o rótulo só cresce
  /// na ilha colapsada: com as 5 abas lado a lado o texto já roda perto do limite e
  /// o `minimumScaleFactor` encolheria de volta, sem ganho real.
  let navIconDelta: CGFloat
  let navIconBoxDelta: CGFloat
  let collapsedNavLabelSize: CGFloat
}

enum AppSectionHeaderCase {
  /// "Visão Geral" — casing de sempre.
  case title
  /// "Visão geral"
  case sentence
  /// "VISÃO GERAL"
  case upper

  /// Só reescreve quando o caller manda tudo em caixa alta; textos já formatados
  /// ("Meus filtros") passam intactos, como o `ListSectionHeader` sempre fez.
  func apply(to text: String) -> String {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    let isAllCaps = !trimmed.isEmpty
      && trimmed == trimmed.uppercased(with: .current)
      && trimmed.contains(where: \.isLetter)

    switch self {
    case .upper:
      return text.uppercased(with: .current)
    case .title:
      return isAllCaps ? trimmed.capitalized(with: .current) : text
    case .sentence:
      guard isAllCaps else { return text }
      let lowered = trimmed.lowercased(with: .current)
      guard let first = lowered.first else { return text }
      return String(first).uppercased(with: .current) + lowered.dropFirst()
    }
  }
}

enum AppTypeScaleStorage {
  static let key = "homeTypeScale"

  static var defaultScale: AppTypeScale { .classic }
  static var defaultRawValue: String { defaultScale.rawValue }

  static func scale(from rawValue: String) -> AppTypeScale {
    AppTypeScale(rawValue: rawValue) ?? defaultScale
  }
}
