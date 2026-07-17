import SwiftUI

enum HomeHeroStyle: String, CaseIterable, Identifiable {
  case classic
  case masthead
  case horizonTone
  case dayRuler
  case dayRail
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
  case greetingWeatherPremiumSceneMono
  case greetingWeatherPremiumSceneMonoOpen
  case greetingWeatherMinimal
  case greetingWeatherMinimalOpen
  case greetingWeatherRefined
  case greetingWeatherRefinedOpen
  case greetingWeatherTint
  case greetingWeatherTintOpen
  case greetingWeatherSculpt
  case greetingWeatherSculptOpen
  case greetingWeatherSculptLift
  case greetingWeatherSculptLiftOpen
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
    case .masthead: "Masthead"
    case .horizonTone: "Horizonte tonal"
    case .dayRuler: "Régua do dia"
    case .dayRail: "Trilho do dia"
    case .orbital: "Orbital"
    case .orbitalOpen: "Orbital aberto"
    case .horizon: "Horizonte"
    case .capsule: "Cápsula"
    case .openType: "Aberto"
    case .focus: "Foco"
    case .motivation: "Mensagem"
    case .focusDay: "Foco do dia"
    case .streak: "Sequência"
    case .motivationIntegrated: "Mensagem + status"
    case .focusDayIntegrated: "Foco + status"
    case .streakIntegrated: "Sequência + status"
    case .streakOpen: "Sequência aberta"
    case .streakOpenCentered: "Sequência central"
    case .greetingProgress: "Progresso"
    case .greetingFocus: "Saudação e foco"
    case .greetingWeather: "Clima"
    case .greetingProgressTinted: "Progresso · tema"
    case .greetingFocusTinted: "Foco · tema"
    case .greetingWeatherTinted: "Clima · tema"
    case .greetingWeatherPremium: "Clima · premium"
    case .greetingWeatherPremiumOpen: "Clima · premium aberto"
    case .greetingWeatherPremiumScene: "Clima · cena"
    case .greetingWeatherPremiumSceneOpen: "Clima · cena aberta"
    case .greetingWeatherPremiumSceneMono: "Clima · mono"
    case .greetingWeatherPremiumSceneMonoOpen: "Clima · mono aberto"
    case .greetingWeatherMinimal: "Clima · minimal"
    case .greetingWeatherMinimalOpen: "Clima · minimal aberto"
    case .greetingWeatherRefined: "Clima · refinado"
    case .greetingWeatherRefinedOpen: "Clima · refinado aberto"
    case .greetingWeatherTint: "Clima · tom"
    case .greetingWeatherTintOpen: "Clima · tom aberto"
    case .greetingWeatherSculpt: "Clima · escultura"
    case .greetingWeatherSculptOpen: "Clima · escultura aberta"
    case .greetingWeatherSculptLift: "Clima · destaque"
    case .greetingWeatherSculptLiftOpen: "Clima · destaque aberto"
    case .journeyDaily: "Jornada · diária"
    case .journeyMist: "Jornada · neblina"
    case .journeyForest: "Jornada · floresta"
    case .journeySummit: "Jornada · cume"
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
    case .classic: "Saudação e status do dia"
    case .masthead: "Tipografia aberta, sem card"
    case .horizonTone: "Fundo sutil que muda com a hora"
    case .dayRuler: "Instrumento do progresso do dia"
    case .dayRail: "Trilho compacto com posição atual"
    case .orbital: "Stack com halo"
    case .orbitalOpen: "Mesma arte, sem card"
    case .horizon: "Mini horizonte por hora"
    case .capsule: "Status no topo"
    case .openType: "Tipografia no fundo"
    case .focus: "Status com bandeja"
    case .motivation: "Frase do dia"
    case .focusDay: "Próxima tarefa de hoje"
    case .streak: "Dias seguidos"
    case .motivationIntegrated: "Frase com status no rodapé"
    case .focusDayIntegrated: "Foco com status no rodapé"
    case .streakIntegrated: "Sequência com status no rodapé"
    case .streakOpen: "Sequência sem card"
    case .streakOpenCentered: "Sequência aberta e centralizada"
    case .greetingProgress: "Saudação e barra do dia"
    case .greetingFocus: "Cartão de foco do dia"
    case .greetingWeather: "Ilustração do clima"
    case .greetingProgressTinted: "Fundo na cor do tema"
    case .greetingFocusTinted: "Fundo na cor do tema"
    case .greetingWeatherTinted: "Clima ao vivo na cor do tema"
    case .greetingWeatherPremium: "Cena ilustrada no card"
    case .greetingWeatherPremiumOpen: "Cena ilustrada, sem card"
    case .greetingWeatherPremiumScene: "Cena completa no card"
    case .greetingWeatherPremiumSceneOpen: "Cena completa, sem card"
    case .greetingWeatherPremiumSceneMono: "Cena em uma só cor"
    case .greetingWeatherPremiumSceneMonoOpen: "Cena monocromática, sem card"
    case .greetingWeatherMinimal: "Ícone simples no card"
    case .greetingWeatherMinimalOpen: "Ícone simples, sem card"
    case .greetingWeatherRefined: "Ícone monocromático no card"
    case .greetingWeatherRefinedOpen: "Ícone monocromático, sem card"
    case .greetingWeatherTint: "Ícone com cor sutil"
    case .greetingWeatherTintOpen: "Ícone colorido, sem card"
    case .greetingWeatherSculpt: "Ícones em relevo no card"
    case .greetingWeatherSculptOpen: "Ícones em relevo, sem card"
    case .greetingWeatherSculptLift: "Arte maior à direita"
    case .greetingWeatherSculptLiftOpen: "Arte maior, sem card"
    case .journeyDaily: "Trilha e status do dia"
    case .journeyMist: "Vale com temperatura"
    case .journeyForest: "Trilha na mata"
    case .journeySummit: "Crista e clima"
    case .auroraCalm: "Ondas teal suaves"
    case .auroraDusk: "Faixas violeta"
    case .auroraEmber: "Brilho monocromático"
    case .panel: "Foco e métricas"
    case .compass: "Direção do dia"
    case .queue: "Tarefas de hoje"
    case .thermometer: "Atraso, hoje e breve"
    case .rhythm: "Conclusões da semana"
    case .nextStep: "Próxima ação"
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
         .greetingWeatherPremium, .greetingWeatherPremiumScene, .greetingWeatherPremiumSceneMono, .greetingWeatherMinimal, .greetingWeatherRefined, .greetingWeatherTint, .greetingWeatherSculpt, .greetingWeatherSculptLift, .journeyDaily, .journeyMist, .journeyForest, .journeySummit, .auroraCalm, .auroraDusk, .auroraEmber: true
    default: false
    }
  }
}

enum HomeHeroStyleGroup: String, CaseIterable, Identifiable {
  case recommended
  case weather
  case journey
  case aurora
  case experimental

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .recommended: "Recomendado"
    case .weather: "Clima"
    case .journey: "Jornada"
    case .aurora: "Aurora"
    case .experimental: "Experimental"
    }
  }

  /// Grupos ainda oferecidos em Aparência.
  static var pickerGroups: [HomeHeroStyleGroup] {
    [.recommended, .weather, .journey]
  }

  var isAvailableInPicker: Bool {
    Self.pickerGroups.contains(self)
  }
}

extension HomeHeroStyle {
  var pickerGroup: HomeHeroStyleGroup {
    switch self {
    case .dayRail, .masthead, .horizonTone, .classic:
      return .recommended
    case .greetingWeather, .greetingWeatherTinted, .greetingWeatherPremium, .greetingWeatherPremiumOpen,
         .greetingWeatherPremiumScene, .greetingWeatherPremiumSceneOpen,
         .greetingWeatherPremiumSceneMono, .greetingWeatherPremiumSceneMonoOpen,
         .greetingWeatherMinimal,
         .greetingWeatherMinimalOpen, .greetingWeatherRefined, .greetingWeatherRefinedOpen, .greetingWeatherTint, .greetingWeatherTintOpen,
         .greetingWeatherSculpt, .greetingWeatherSculptOpen,
         .greetingWeatherSculptLift, .greetingWeatherSculptLiftOpen:
      return .weather
    case .journeyDaily, .journeyMist, .journeyForest, .journeySummit:
      return .journey
    case .auroraCalm, .auroraDusk, .auroraEmber:
      return .aurora
    default:
      return .experimental
    }
  }

  /// Aurora e Experimental saíram do seletor; estilos legados caem no padrão.
  var isAvailableInPicker: Bool {
    pickerGroup.isAvailableInPicker
  }

  static func styles(in group: HomeHeroStyleGroup) -> [HomeHeroStyle] {
    guard group.isAvailableInPicker else { return [] }
    let styles = allCases.filter { $0.pickerGroup == group && !HomeHeroStyleStorage.isHidden($0) }
    guard group == .recommended else { return styles }
    let preferred: [HomeHeroStyle] = [.dayRail, .masthead, .horizonTone, .classic]
    let head = preferred.filter { styles.contains($0) }
    let tail = styles.filter { !preferred.contains($0) }
    return head + tail
  }

  /// Estilos que ainda podem ser ocultados pelo usuário (não remove o padrão).
  var canHideFromPicker: Bool {
    self != .dayRail && self != .classic && isAvailableInPicker
  }
}

enum HomeHeroStyleStorage {
  static let key = "homeHeroStyle"
  static let hiddenKey = "homeHeroStyleHidden"

  static var defaultStyle: HomeHeroStyle { .dayRail }
  static var defaultRawValue: String { defaultStyle.rawValue }

  static func style(from rawValue: String) -> HomeHeroStyle {
    let style = HomeHeroStyle(rawValue: rawValue) ?? defaultStyle
    if !style.isAvailableInPicker || isHidden(style) { return defaultStyle }
    return style
  }

  static func isHidden(_ style: HomeHeroStyle) -> Bool {
    hiddenRawValues().contains(style.rawValue)
  }

  static func hide(_ style: HomeHeroStyle) {
    guard style.canHideFromPicker else { return }
    var set = hiddenRawValues()
    set.insert(style.rawValue)
    UserDefaults.standard.set(Array(set).sorted().joined(separator: ","), forKey: hiddenKey)
  }

  static func unhide(_ style: HomeHeroStyle) {
    guard style.isAvailableInPicker else { return }
    var set = hiddenRawValues()
    set.remove(style.rawValue)
    UserDefaults.standard.set(Array(set).sorted().joined(separator: ","), forKey: hiddenKey)
  }

  static func hiddenStyles() -> [HomeHeroStyle] {
    hiddenRawValues()
      .compactMap(HomeHeroStyle.init(rawValue:))
      .filter(\.isAvailableInPicker)
      .sorted { $0.displayName < $1.displayName }
  }

  /// Se a preferência apontar para estilo aposentado/oculto, grava o padrão (Trilho).
  @discardableResult
  static func migrateRetiredSelectionIfNeeded() -> Bool {
    let raw = UserDefaults.standard.string(forKey: key) ?? defaultRawValue
    let resolved = style(from: raw)
    if resolved.rawValue != raw {
      UserDefaults.standard.set(resolved.rawValue, forKey: key)
      return true
    }
    return false
  }

  private static func hiddenRawValues() -> Set<String> {
    let raw = UserDefaults.standard.string(forKey: hiddenKey) ?? ""
    guard !raw.isEmpty else { return [] }
    return Set(raw.split(separator: ",").map(String.init))
  }
}

enum HomeTimeOfDay {
  case morning
  case afternoon
  case night

  static var current: HomeTimeOfDay { at(Date()) }

  static func at(_ date: Date) -> HomeTimeOfDay {
    let hour = Calendar.current.component(.hour, from: date)
    if hour < 12 { return .morning }
    if hour < 18 { return .afternoon }
    return .night
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
    case .masthead, .horizonTone, .dayRuler, .dayRail:
      return HomeHeroMetrics(
        phraseSize: 13,
        nameSize: 27,
        statusSize: 13,
        orbitalArtSize: 48,
        cardPaddingH: 14,
        cardPaddingV: 12,
        rowSpacing: 14,
        focusTitleSize: 16,
        focusSubtitleSize: 13,
        capsuleStatusSize: 11,
        openVerticalPadding: 6,
        dividerTopPadding: 12
      )
    case .orbitalOpen, .streakOpen, .streakOpenCentered, .greetingWeatherPremiumOpen, .greetingWeatherPremiumSceneOpen, .greetingWeatherPremiumSceneMonoOpen, .greetingWeatherMinimalOpen, .greetingWeatherRefinedOpen, .greetingWeatherTintOpen, .greetingWeatherSculptOpen, .greetingWeatherSculptLiftOpen:
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
         .greetingWeatherPremium, .greetingWeatherPremiumScene, .greetingWeatherPremiumSceneMono, .greetingWeatherMinimal, .greetingWeatherRefined, .greetingWeatherTint, .greetingWeatherSculpt, .greetingWeatherSculptLift,
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
