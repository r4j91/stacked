import Foundation

/// Pares de arte editorial para variantes do hero Jornada.
enum HomeHeroJourneyArt: String, CaseIterable, Identifiable {
  case daily
  case mist
  case forest
  case summit

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .daily: "Jornada diária"
    case .mist: "Jornada neblina"
    case .forest: "Jornada floresta"
    case .summit: "Jornada cume"
    }
  }

  var subtitle: String {
    switch self {
    case .daily: "Ilustração editorial com trilha e status do dia"
    case .mist: "Vale enevoado com temperatura ao vivo"
    case .forest: "Trilha na mata com clima em tempo real"
    case .summit: "Crista montanhosa com condições do dia"
    }
  }

  var showsWeather: Bool {
    switch self {
    case .daily: false
    case .mist, .forest, .summit: true
    }
  }

  func clearAssetName() -> String {
    switch self {
    case .daily: "HeroJourneyClear"
    case .mist: "HeroJourneyMistClear"
    case .forest: "HeroJourneyForestClear"
    case .summit: "HeroJourneySummitClear"
    }
  }

  func overdueAssetName() -> String {
    switch self {
    case .daily: "HeroJourneyOverdue"
    case .mist: "HeroJourneyMistOverdue"
    case .forest: "HeroJourneyForestOverdue"
    case .summit: "HeroJourneySummitOverdue"
    }
  }
}
