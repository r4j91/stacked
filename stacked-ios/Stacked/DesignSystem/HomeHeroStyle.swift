import SwiftUI

/// Card de saudação no topo da Home. Só duas âncoras de orientação sobraram —
/// os conceitos antigos (clima, jornada, aurora, cards unificados) foram removidos.
enum HomeHeroStyle: String, CaseIterable, Identifiable {
  case dayRail
  case masthead

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .dayRail: "Trilho do dia"
    case .masthead: "Manchete"
    }
  }

  var subtitle: String {
    switch self {
    case .dayRail: "Trilho compacto com posição atual"
    case .masthead: "Tipografia aberta, sem card"
    }
  }

  /// Estilos aposentados caem no padrão via `HomeHeroStyleStorage.style(from:)`.
  var isAvailableInPicker: Bool { true }

  static var pickerStyles: [HomeHeroStyle] {
    allCases.filter { !HomeHeroStyleStorage.isHidden($0) }
  }

  /// O padrão nunca some do seletor.
  var canHideFromPicker: Bool {
    self != HomeHeroStyleStorage.defaultStyle
  }
}

// MARK: - Moldura

/// Como o card do topo se encaixa na Home: aberto (tipografia solta, como sempre foi)
/// ou dentro de um card, acompanhando ou não o estilo das seções.
enum HomeHeroFrame: String, CaseIterable, Identifiable {
  case open
  case matchHome
  case bordered
  case plain

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .open: "Aberto"
    case .matchHome: "Seguir a Home"
    case .bordered: "Card com borda"
    case .plain: "Card sem borda"
    }
  }

  var subtitle: String {
    switch self {
    case .open: "Sem card, como está hoje"
    case .matchHome: "Acompanha o agrupamento das seções"
    case .bordered: "Sempre em card com contorno"
    case .plain: "Sempre em card, sem contorno"
    }
  }

  func resolved(sectionStyle: HomeSectionStyle) -> HomeHeroFrameResolution {
    switch self {
    case .open:
      return .open
    case .bordered:
      return .card(bordered: true)
    case .plain:
      return .card(bordered: false)
    case .matchHome:
      switch sectionStyle {
      case .classic: return .open
      case .container, .capsule: return .card(bordered: true)
      case .quiet, .quietEdge: return .card(bordered: false)
      }
    }
  }
}

enum HomeHeroFrameResolution: Equatable {
  case open
  case card(bordered: Bool)

  var isCard: Bool {
    if case .card = self { return true }
    return false
  }
}

// MARK: - Storage

enum HomeHeroStyleStorage {
  static let key = "homeHeroStyle"
  static let hiddenKey = "homeHeroStyleHidden"

  static var defaultStyle: HomeHeroStyle { .dayRail }
  static var defaultRawValue: String { defaultStyle.rawValue }

  static func style(from rawValue: String) -> HomeHeroStyle {
    let style = HomeHeroStyle(rawValue: rawValue) ?? defaultStyle
    if isHidden(style) { return defaultStyle }
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
    var set = hiddenRawValues()
    set.remove(style.rawValue)
    UserDefaults.standard.set(Array(set).sorted().joined(separator: ","), forKey: hiddenKey)
  }

  static func hiddenStyles() -> [HomeHeroStyle] {
    hiddenRawValues()
      .compactMap(HomeHeroStyle.init(rawValue:))
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

enum HomeHeroFrameStorage {
  static let key = "homeHeroFrame"

  static var defaultFrame: HomeHeroFrame { .open }
  static var defaultRawValue: String { defaultFrame.rawValue }

  static func frame(from rawValue: String) -> HomeHeroFrame {
    HomeHeroFrame(rawValue: rawValue) ?? defaultFrame
  }
}

// MARK: - Tempo e métricas

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

/// Escala tipográfica do hero — acompanha o "Tamanho dos títulos" para o card não
/// ficar miúdo quando o resto do app cresce. `classic` reproduz os tokens de sempre.
struct HomeHeroMetrics {
  let phraseSize: CGFloat
  let nameSize: CGFloat
  let statusSize: CGFloat
  /// Dateline e a linha de data/clima.
  let metaSize: CGFloat
  /// Clima compacto da Manchete.
  let weatherSize: CGFloat
  /// Relógio do Trilho.
  let clockSize: CGFloat
  let openVerticalPadding: CGFloat
  let dividerTopPadding: CGFloat

  static func forScale(_ scale: AppTypeScale) -> HomeHeroMetrics {
    switch scale {
    case .classic:
      return HomeHeroMetrics(
        phraseSize: 13,
        nameSize: 27,
        statusSize: 13,
        metaSize: 11,
        weatherSize: 11.5,
        clockSize: 12.5,
        openVerticalPadding: 6,
        dividerTopPadding: 12
      )
    case .eyebrow:
      return HomeHeroMetrics(
        phraseSize: 13.5,
        nameSize: 28,
        statusSize: 13.5,
        metaSize: 11.5,
        weatherSize: 12,
        clockSize: 13,
        openVerticalPadding: 6,
        dividerTopPadding: 12
      )
    case .large:
      return HomeHeroMetrics(
        phraseSize: 14.5,
        nameSize: 30,
        statusSize: 14.5,
        metaSize: 12.5,
        weatherSize: 13,
        clockSize: 14,
        openVerticalPadding: 7,
        dividerTopPadding: 13
      )
    }
  }
}
