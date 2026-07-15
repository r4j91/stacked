import Foundation
import Hugeicons
import SwiftUI

/// Paridade `lib/theme/project_display_mode.dart`
enum ProjectDisplayMode: String, CaseIterable {
  case cards
  case cardsRefined
  case cardsLight
  case list
  case listPremium

  /// AppStorage compartilhado (projeto + Inbox/Hoje/…).
  static let storageKey = "display_mode"
  /// Balões+ — modo mais usado; padrão novo / chave ausente.
  static let defaultRawValue = ProjectDisplayMode.cardsRefined.rawValue

  var label: String {
    switch self {
    case .cards: "Balões"
    case .cardsRefined: "Balões+"
    case .cardsLight: "Balões light"
    case .list: "Lista"
    case .listPremium: "Lista premium"
    }
  }

  var usesCardStyle: Bool {
    switch self {
    case .cards, .cardsRefined, .cardsLight: true
    case .list, .listPremium: false
    }
  }

  var flatSubtaskPanel: Bool {
    self == .cardsRefined
  }

  var taskRowStyle: TaskRowStyle {
    switch self {
    case .cards, .cardsRefined: .card
    case .cardsLight: .cardLight
    case .list: .list
    case .listPremium: .listPremium
    }
  }

  /// Insets da List — card modes respiram; list premium tem gutter leve Things-style.
  var taskListRowInsets: EdgeInsets {
    switch self {
    case .cards, .cardsRefined, .cardsLight:
      EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
    case .list:
      EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    case .listPremium:
      EdgeInsets(top: 1, leading: 12, bottom: 1, trailing: 12)
    }
  }

  var menuIcon: HugeiconsAsset {
    switch self {
    case .cards, .cardsRefined, .cardsLight: Hugeicons.grid
    case .list, .listPremium: Hugeicons.listView
    }
  }

  static func from(_ raw: String) -> ProjectDisplayMode {
    switch raw {
    case "list": .list
    case "listPremium", "listRefined": .listPremium
    case "cardsRefined": .cardsRefined
    case "cardsLight": .cardsLight
    case "cards": .cards
    case "folders", "hybrid": .cards
    default: .cards
    }
  }
}

/// Estilos visuais da TaskRow (ligado a `ProjectDisplayMode`).
enum TaskRowStyle {
  case card
  case cardLight
  case list
  case listPremium

  var isCardFamily: Bool {
    switch self {
    case .card, .cardLight: true
    case .list, .listPremium: false
    }
  }
}

