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
  case streakOpenCentered
  case greetingProgress
  case greetingFocus
  case greetingWeather
  case greetingProgressTinted
  case greetingFocusTinted
  case greetingWeatherTinted
  case greetingWeatherPremium
  case greetingWeatherPremiumOpen
  case greetingWeatherPremiumScene
  case greetingWeatherPremiumSceneOpen
  case greetingWeatherMinimal
  case greetingWeatherMinimalOpen
  case greetingWeatherRefined
  case greetingWeatherRefinedOpen
  case greetingWeatherTint
  case greetingWeatherTintOpen
  case journeyDaily
  case journeyMist
  case journeyForest
  case journeySummit
  case auroraCalm
  case auroraDusk
  case auroraEmber
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
    case .streakOpenCentered: "Sequência centralizada"
    case .greetingProgress: "Saudação e progresso"
    case .greetingFocus: "Saudação e foco"
    case .greetingWeather: "Saudação e clima"
    case .greetingProgressTinted: "Progresso (tom app)"
    case .greetingFocusTinted: "Foco (tom app)"
    case .greetingWeatherTinted: "Clima (tom app)"
    case .greetingWeatherPremium: "Clima premium"
    case .greetingWeatherPremiumOpen: "Clima premium aberto"
    case .greetingWeatherPremiumScene: "Clima cena premium"
    case .greetingWeatherPremiumSceneOpen: "Clima cena aberto"
    case .greetingWeatherMinimal: "Clima minimal"
    case .greetingWeatherMinimalOpen: "Clima minimal aberto"
    case .greetingWeatherRefined: "Clima refinado"
    case .greetingWeatherRefinedOpen: "Clima refinado aberto"
    case .greetingWeatherTint: "Clima refinado tom"
    case .greetingWeatherTintOpen: "Clima refinado tom aberto"
    case .journeyDaily: "Jornada diária"
    case .journeyMist: "Jornada neblina"
    case .journeyForest: "Jornada floresta"
    case .journeySummit: "Jornada cume"
    case .auroraCalm: "Aurora teal"
    case .auroraDusk: "Aurora violeta"
    case .auroraEmber: "Aurora titanium"
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
    case .streakOpenCentered: "Sequência aberta com conteúdo ao centro"
    case .greetingProgress: "Bom dia com barra de progresso do dia"
    case .greetingFocus: "Saudação com cartão de foco do dia"
    case .greetingWeather: "Saudação com clima ilustrativo do dia"
    case .greetingProgressTinted: "Progresso com fundo na cor do app"
    case .greetingFocusTinted: "Foco com fundo na cor do app"
    case .greetingWeatherTinted: "Clima real da localização com fundo temático"
    case .greetingWeatherPremium: "Clima ao vivo com cena ilustrada premium"
    case .greetingWeatherPremiumOpen: "Clima premium sem card, direto no fundo"
    case .greetingWeatherPremiumScene: "Clima ao vivo com cena ilustrada no card"
    case .greetingWeatherPremiumSceneOpen: "Cena ilustrada sem card, direto no fundo"
    case .greetingWeatherMinimal: "Ícone !Weather sutil com card escuro"
    case .greetingWeatherMinimalOpen: "Clima minimal sem card, direto no fundo"
    case .greetingWeatherRefined: "Ícone monocromático premium com profundidade"
    case .greetingWeatherRefinedOpen: "Clima refinado sem card, direto no fundo"
    case .greetingWeatherTint: "Ícone refinado com cor sutil e sombras suaves"
    case .greetingWeatherTintOpen: "Clima refinado tom sem card, direto no fundo"
    case .journeyDaily: "Ilustração editorial com trilha e status do dia"
    case .journeyMist: "Vale enevoado com temperatura ao vivo"
    case .journeyForest: "Trilha na mata com clima em tempo real"
    case .journeySummit: "Crista montanhosa com condições do dia"
    case .auroraCalm: "Ondas teal suaves como no conceito"
    case .auroraDusk: "Ribbons violeta e roxo premium"
    case .auroraEmber: "Brilho titanium cinza monocromático"
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
         .motivationIntegrated, .focusDayIntegrated, .streakIntegrated,
         .greetingProgress, .greetingFocus, .greetingWeather,
         .greetingProgressTinted, .greetingFocusTinted, .greetingWeatherTinted,
         .greetingWeatherPremium, .greetingWeatherPremiumScene, .greetingWeatherMinimal, .greetingWeatherRefined, .greetingWeatherTint, .journeyDaily, .journeyMist, .journeyForest, .journeySummit, .auroraCalm, .auroraDusk, .auroraEmber: true
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
    case .orbitalOpen, .streakOpen, .streakOpenCentered, .greetingWeatherPremiumOpen, .greetingWeatherPremiumSceneOpen, .greetingWeatherMinimalOpen, .greetingWeatherRefinedOpen, .greetingWeatherTintOpen:
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
         .greetingProgress, .greetingFocus, .greetingWeather,
         .greetingProgressTinted, .greetingFocusTinted, .greetingWeatherTinted,
         .greetingWeatherPremium, .greetingWeatherPremiumScene, .greetingWeatherMinimal, .greetingWeatherRefined, .greetingWeatherTint,
         .journeyDaily, .journeyMist, .journeyForest, .journeySummit,
         .auroraCalm, .auroraDusk, .auroraEmber,
         .panel, .compass, .queue, .thermometer, .rhythm, .nextStep:
      return HomeHeroMetrics(
        phraseSize: 12,
        nameSize: 22,
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
