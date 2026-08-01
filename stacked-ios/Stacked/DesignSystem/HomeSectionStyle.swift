import SwiftUI

/// Agrupamento visual das seções da Home (Visão geral / Projetos).
/// `classic` é o layout de hoje — lista solta, sem fundo por trás dos grupos.
enum HomeSectionStyle: String, CaseIterable, Identifiable {
  case classic
  case container
  case capsule
  case quiet

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .classic: "Atual"
    case .container: "Container"
    case .capsule: "Cápsulas"
    case .quiet: "Container quieto"
    }
  }

  var subtitle: String {
    switch self {
    case .classic: "Lista solta, sem fundo nos grupos"
    case .capsule: "Cada linha em sua própria cápsula"
    case .container: "Grupo em card único, com contorno"
    case .quiet: "Card sem contorno, divisores finos"
    }
  }

  /// Linhas coladas formando um bloco só (A e E).
  var isGroupedContainer: Bool {
    self == .container || self == .quiet
  }

  var hasSurface: Bool {
    self != .classic
  }

  /// Só o Container (A) desenha contorno — é o que separa A de E.
  var drawsBorder: Bool {
    self == .container
  }

  var showsRowDividers: Bool {
    isGroupedContainer
  }

  var metrics: HomeSectionMetrics {
    switch self {
    case .classic:
      return HomeSectionMetrics(
        contentInsetH: AppSpacing.xl,
        containerInsetH: AppSpacing.xl,
        rowSpacingV: AppSpacing.xs,
        rowPaddingV: AppSpacing.sm + 2,
        cornerRadius: 0,
        capsuleGapV: 0,
        headerTopPadding: 0,
        headerBottomPadding: 0,
        firstSectionExtraTopPadding: 8
      )
    case .capsule:
      return HomeSectionMetrics(
        contentInsetH: 30,
        containerInsetH: 18,
        rowSpacingV: 0,
        rowPaddingV: 11,
        cornerRadius: 18,
        capsuleGapV: 3,
        headerTopPadding: 6,
        headerBottomPadding: 4,
        firstSectionExtraTopPadding: 8
      )
    case .container, .quiet:
      return HomeSectionMetrics(
        contentInsetH: 30,
        containerInsetH: 18,
        rowSpacingV: 0,
        rowPaddingV: 11,
        cornerRadius: 18,
        capsuleGapV: 0,
        headerTopPadding: 6,
        headerBottomPadding: 4,
        firstSectionExtraTopPadding: 8
      )
    }
  }
}

struct HomeSectionMetrics {
  /// Inset horizontal do conteúdo da linha (ícone → borda da tela).
  let contentInsetH: CGFloat
  /// Inset horizontal do card/cápsula.
  let containerInsetH: CGFloat
  /// Respiro vertical entre linhas no estilo atual (vira 0 nos containers).
  let rowSpacingV: CGFloat
  let rowPaddingV: CGFloat
  let cornerRadius: CGFloat
  /// Metade do gap entre cápsulas — aplicado como padding no fundo da linha.
  let capsuleGapV: CGFloat
  let headerTopPadding: CGFloat
  let headerBottomPadding: CGFloat
  /// Respiro extra do primeiro header da tela, que nasce colado na navbar.
  let firstSectionExtraTopPadding: CGFloat

  var rowInsets: EdgeInsets {
    EdgeInsets(
      top: rowSpacingV,
      leading: contentInsetH,
      bottom: rowSpacingV,
      trailing: contentInsetH
    )
  }

  /// Divisor começa alinhado ao texto, não à borda do card.
  var dividerLeadingInset: CGFloat {
    (contentInsetH - containerInsetH) + HomeSectionRowLayout.iconWidth + HomeSectionRowLayout.iconSpacing
  }
}

enum HomeSectionRowLayout {
  static let iconWidth: CGFloat = 28
  static let iconSpacing: CGFloat = AppSpacing.md + 2
  /// Faixa que a alça de arrastar do sistema ocupa na borda direita da célula
  /// em modo de edição. Ela é desenhada sobre a célula inteira, ignorando os
  /// insets da linha, então o card recua isso para não passar por baixo dela.
  static let reorderHandleZone: CGFloat = 28
}

/// Posição da linha dentro do container — define quais cantos arredondam.
enum HomeSectionRowPosition {
  case first
  case middle
  case last
  case only

  var isFirst: Bool { self == .first || self == .only }
  var isLast: Bool { self == .last || self == .only }

  static func at(index: Int, count: Int) -> HomeSectionRowPosition {
    if count <= 1 { return .only }
    if index == 0 { return .first }
    if index == count - 1 { return .last }
    return .middle
  }
}

// MARK: - Storage

enum HomeSectionStyleStorage {
  static let key = "homeSectionStyle"

  static var defaultStyle: HomeSectionStyle { .classic }
  static var defaultRawValue: String { defaultStyle.rawValue }

  static func style(from rawValue: String) -> HomeSectionStyle {
    HomeSectionStyle(rawValue: rawValue) ?? defaultStyle
  }
}

/// Card de saudação no topo da Home. Desligado, entra o container de utilidades
/// (Buscar / Relatórios / Filtros / Etiquetas) no estilo ativo das seções.
enum HomeTopCardStorage {
  static let key = "homeTopCardEnabled"
  static let defaultEnabled = true
}

