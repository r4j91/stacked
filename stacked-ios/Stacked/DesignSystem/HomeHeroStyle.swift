import SwiftUI

enum HomeHeroStyle: String, CaseIterable, Identifiable {
  case classic
  case orbital
  case orbitalOpen
  case horizon
  case capsule
  case openType
  case focus
  case motivation
  case focusDay
  case streak
  case motivationIntegrated
  case focusDayIntegrated
  case streakIntegrated
  case streakOpen
  case panel
  case compass
  case queue
  case thermometer
  case rhythm
  case nextStep

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .classic: "Clássico"
    case .orbital: "Orbital"
    case .orbitalOpen: "Orbital aberto"
    case .horizon: "Horizonte"
    case .capsule: "Cápsula"
    case .openType: "Aberto"
    case .focus: "Foco"
    case .motivation: "Mensagem"
    case .focusDay: "Foco do dia"
    case .streak: "Sequência"
    case .motivationIntegrated: "Mensagem integrada"
    case .focusDayIntegrated: "Foco integrado"
    case .streakIntegrated: "Sequência integrada"
    case .streakOpen: "Sequência aberta"
    case .panel: "Painel"
    case .compass: "Bússola"
    case .queue: "Fila"
    case .thermometer: "Termômetro"
    case .rhythm: "Ritmo"
    case .nextStep: "Próximo passo"
    }
  }

  var subtitle: String {
    switch self {
    case .classic: "Saudação e status como hoje"
    case .orbital: "Stack com halo animado"
    case .orbitalOpen: "Mesma arte, sem o card"
    case .horizon: "Mini horizonte por hora do dia"
    case .capsule: "Status em cápsula no topo"
    case .openType: "Tipografia direta no fundo"
    case .focus: "Status direto com bandeja"
    case .motivation: "Frase motivacional do dia"
    case .focusDay: "Próxima tarefa de hoje"
    case .streak: "Dias seguidos com conclusões"
    case .motivationIntegrated: "Mensagem com status no rodapé"
    case .focusDayIntegrated: "Foco do dia com status no rodapé"
    case .streakIntegrated: "Sequência com status no rodapé"
    case .streakOpen: "Sequência sem card, direto no fundo"
    case .panel: "Foco, status e métricas num card"
    case .compass: "Direção do dia com status integrado"
    case .queue: "Fila de hoje com status nas linhas"
    case .thermometer: "Contadores de atraso, hoje e breve"
    case .rhythm: "Semana de conclusões, tom factual"
    case .nextStep: "Próxima ação com contexto de status"
    }
  }

  /// Cards conceito com faixa de status separada (legado).
  var isConceptCard: Bool {
    switch self {
    case .motivation, .focusDay, .streak: true
    default: false
    }
  }

  /// Cards unificados: status no mesmo bloco.
  var isUnifiedConceptCard: Bool {
    switch self {
    case .panel, .compass, .queue, .thermometer, .rhythm, .nextStep,
         .motivationIntegrated, .focusDayIntegrated, .streakIntegrated: true
    default: false
    }
  }
}

enum HomeTimeOfDay {
  case morning
  case afternoon
  case night

  static var current: HomeTimeOfDay {
    let hour = Calendar.current.component(.hour, from: Date())
    if hour < 12 { return .morning }
    if hour < 18 { return .afternoon }
    return .night
  }
}

enum HomeHeroStyleStorage {
  static let key = "homeHeroStyle"

  static var defaultRawValue: String { HomeHeroStyle.classic.rawValue }

  static func style(from rawValue: String) -> HomeHeroStyle {
    HomeHeroStyle(rawValue: rawValue) ?? .classic
  }
}

/// Escala tipográfica e de arte do hero — clássico não usa (mantém tokens próprios).
struct HomeHeroMetrics {
  let phraseSize: CGFloat
  let nameSize: CGFloat
  let statusSize: CGFloat
  let orbitalArtSize: CGFloat
  let cardPaddingH: CGFloat
  let cardPaddingV: CGFloat
  let rowSpacing: CGFloat
  let focusTitleSize: CGFloat
  let focusSubtitleSize: CGFloat
  let capsuleStatusSize: CGFloat
  let openVerticalPadding: CGFloat
  let dividerTopPadding: CGFloat

  static func forStyle(_ style: HomeHeroStyle) -> HomeHeroMetrics {
    switch style {
    case .orbitalOpen, .streakOpen:
      return HomeHeroMetrics(
        phraseSize: 14,
        nameSize: 26,
        statusSize: 14,
        orbitalArtSize: 56,
        cardPaddingH: 14,
        cardPaddingV: 12,
        rowSpacing: 14,
        focusTitleSize: 16,
        focusSubtitleSize: 13,
        capsuleStatusSize: 11,
        openVerticalPadding: 6,
        dividerTopPadding: 14
      )
    case .orbital, .horizon:
      return HomeHeroMetrics(
        phraseSize: 13,
        nameSize: 22,
        statusSize: 13.5,
        orbitalArtSize: 52,
        cardPaddingH: 14,
        cardPaddingV: 12,
        rowSpacing: 14,
        focusTitleSize: 16,
        focusSubtitleSize: 13,
        capsuleStatusSize: 11,
        openVerticalPadding: 4,
        dividerTopPadding: 10
      )
    case .capsule:
      return HomeHeroMetrics(
        phraseSize: 13,
        nameSize: 25,
        statusSize: 13.5,
        orbitalArtSize: 48,
        cardPaddingH: 15,
        cardPaddingV: 13,
        rowSpacing: 14,
        focusTitleSize: 16,
        focusSubtitleSize: 13,
        capsuleStatusSize: 11,
        openVerticalPadding: 4,
        dividerTopPadding: 10
      )
    case .openType:
      return HomeHeroMetrics(
        phraseSize: 13,
        nameSize: 26,
        statusSize: 13.5,
        orbitalArtSize: 48,
        cardPaddingH: 14,
        cardPaddingV: 12,
        rowSpacing: 14,
        focusTitleSize: 16,
        focusSubtitleSize: 13,
        capsuleStatusSize: 11,
        openVerticalPadding: 6,
        dividerTopPadding: 10
      )
    case .focus:
      return HomeHeroMetrics(
        phraseSize: 13,
        nameSize: 22,
        statusSize: 13.5,
        orbitalArtSize: 48,
        cardPaddingH: 13,
        cardPaddingV: 11,
        rowSpacing: 12,
        focusTitleSize: 16,
        focusSubtitleSize: 13,
        capsuleStatusSize: 11,
        openVerticalPadding: 4,
        dividerTopPadding: 10
      )
    case .motivation, .focusDay, .streak, .motivationIntegrated, .focusDayIntegrated, .streakIntegrated,
         .panel, .compass, .queue, .thermometer, .rhythm, .nextStep:
      return HomeHeroMetrics(
        phraseSize: 12,
        nameSize: 20,
        statusSize: 12.5,
        orbitalArtSize: 48,
        cardPaddingH: 14,
        cardPaddingV: 12,
        rowSpacing: 12,
        focusTitleSize: 15,
        focusSubtitleSize: 12,
        capsuleStatusSize: 10,
        openVerticalPadding: 4,
        dividerTopPadding: 10
      )
    case .classic:
      return HomeHeroMetrics(
        phraseSize: 12,
        nameSize: 20,
        statusSize: 12.5,
        orbitalArtSize: 48,
        cardPaddingH: 13,
        cardPaddingV: 11,
        rowSpacing: 12,
        focusTitleSize: 15,
        focusSubtitleSize: 12,
        capsuleStatusSize: 10,
        openVerticalPadding: 4,
        dividerTopPadding: 10
      )
    }
  }
}
