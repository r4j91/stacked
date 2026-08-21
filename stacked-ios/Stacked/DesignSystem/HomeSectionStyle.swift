import SwiftUI

/// Agrupamento visual das seções da Home (Visão geral / Projetos).
/// `classic` é o layout de hoje — lista solta, sem fundo por trás dos grupos.
enum HomeSectionStyle: String, CaseIterable, Identifiable {
  case classic
  case container
  case capsule
  case quiet
  /// Quieto + filete accent na borda esquerda (segue o raio do card).
  case quietEdge
  /// Quieto + header em pílula (sem borda na chip nem no card).
  case quietPill
  /// Bandeja quieta com cada linha em caixa inset (sem borda externa).
  case quietNested

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .classic: "Atual"
    case .container: "Container"
    case .capsule: "Cápsulas"
    case .quiet: "Container quieto"
    case .quietEdge: "Quieto com filete"
    case .quietPill: "Label em pílula"
    case .quietNested: "Caixas internas"
    }
  }

  var subtitle: String {
    switch self {
    case .classic: "Lista solta, sem fundo nos grupos"
    case .capsule: "Cada linha em sua própria cápsula"
    case .container: "Grupo em card único, com contorno"
    case .quiet: "Card sem contorno, divisores finos"
    case .quietEdge: "Quieto com barra accent à esquerda"
    case .quietPill: "Quieto com título em chip, sem bordas"
    case .quietNested: "Bandeja quieta com linhas em caixas"
    }
  }

  /// Linhas coladas formando um bloco só (inclui bandeja nested).
  var isGroupedContainer: Bool {
    switch self {
    case .container, .quiet, .quietEdge, .quietPill, .quietNested:
      true
    case .classic, .capsule:
      false
    }
  }

  var hasSurface: Bool {
    self != .classic
  }

  /// Só o Container desenha contorno hairline.
  var drawsBorder: Bool {
    self == .container
  }

  /// Filete accent na borda esquerda do card (só `quietEdge`).
  var drawsAccentEdge: Bool {
    self == .quietEdge
  }

  /// Header da seção vira chip flutuante.
  var usesPillHeader: Bool {
    self == .quietPill
  }

  /// Bandeja externa + caixas inset por linha.
  var usesNestedRows: Bool {
    self == .quietNested
  }

  var showsRowDividers: Bool {
    isGroupedContainer && !usesNestedRows
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
    case .quietPill:
      return HomeSectionMetrics(
        contentInsetH: 30,
        containerInsetH: 18,
        rowSpacingV: 0,
        rowPaddingV: 11,
        cornerRadius: 18,
        capsuleGapV: 0,
        headerTopPadding: 6,
        headerBottomPadding: 8,
        firstSectionExtraTopPadding: 8
      )
    case .quietNested:
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
    case .container, .quiet, .quietEdge:
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
  /// Largura do filete accent em `quietEdge` (inset na borda esquerda do card).
  static let accentEdgeWidth: CGFloat = 3
  /// Raio das caixas internas em `quietNested`.
  static let nestedInnerRadius: CGFloat = 12
  /// Inset horizontal da caixa interna em relação à bandeja.
  static let nestedInnerInsetH: CGFloat = 6
  /// Gap vertical entre caixas internas (metade em cada célula).
  static let nestedInnerGapV: CGFloat = 3
  /// Padding extra no topo/base da bandeja nested.
  static let nestedTrayPaddingV: CGFloat = 4
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

  static var defaultStyle: HomeSectionStyle { .quiet }
  static var defaultRawValue: String { defaultStyle.rawValue }

  static func style(from rawValue: String) -> HomeSectionStyle {
    HomeSectionStyle(rawValue: rawValue) ?? defaultStyle
  }
}

/// Card de saudação no topo da Home. Desligado, entra o container de utilidades
/// (Buscar / Relatórios / Filtros / Etiquetas) no estilo ativo das seções.
enum HomeTopCardStorage {
  static let key = "homeTopCardEnabled"
  static let defaultEnabled = false
}

/// Home · Dinheiro: segunda linha “Nas contas” (saldo + sobra projetada).
enum HomeMoneyRichStorage {
  static let key = "appearance.homeMoneyRich"
  static let defaultEnabled = true

  static var isEnabled: Bool {
    UserDefaults.standard.object(forKey: key) as? Bool ?? defaultEnabled
  }
}

/// Mostra a seção DINHEIRO na Home (resumo; toque abre a aba).
enum HomeMoneyOnHomeStorage {
  static let key = "appearance.homeMoneyOnHome"
  static let defaultEnabled = true

  static var isEnabled: Bool {
    UserDefaults.standard.object(forKey: key) as? Bool ?? defaultEnabled
  }
}

/// Dinheiro · visual premium (cores semânticas, ícones, cascata no fluxo). Desligado = layout clássico.
enum MoneyPremiumAppearanceStorage {
  static let key = "appearance.moneyPremium"
  static let defaultEnabled = false

  static var isEnabled: Bool {
    UserDefaults.standard.object(forKey: key) as? Bool ?? defaultEnabled
  }
}

/// Dinheiro · layout proposto (mockup B+C). Só se aplica com premium ligado.
enum MoneyProposedAppearanceStorage {
  static let key = "appearance.moneyProposed"
  static let defaultEnabled = false

  static var isEnabled: Bool {
    UserDefaults.standard.object(forKey: key) as? Bool ?? defaultEnabled
  }
}
