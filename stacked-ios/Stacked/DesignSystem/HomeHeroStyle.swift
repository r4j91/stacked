import SwiftUI

enum HomeHeroStyle: String, CaseIterable, Identifiable {
  case classic
  case orbital
  case orbitalOpen
  case horizon
  case capsule
  case openType
  case focus

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
    case .orbitalOpen:
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
        dividerTopPadding: 12
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
