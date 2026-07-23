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
  /// Lista organizada: gutter 16pt (paridade cards), hairline só no header.
  case listComfort

  /// AppStorage compartilhado (projeto + Inbox/Hoje/…).
  static let storageKey = "display_mode"
  /// Balões+ — modo mais usado; padrão novo / chave ausente.
  static let defaultRawValue = ProjectDisplayMode.listComfort.rawValue

  var label: String {
    switch self {
    case .cards: "Balões"
    case .cardsRefined: "Balões+"
    case .cardsLight: "Halo"
    case .list: "Lista"
    case .listPremium: "Lista premium"
    case .listComfort: "Lista+"
    }
  }

  var usesCardStyle: Bool {
    switch self {
    case .cards, .cardsRefined, .cardsLight: true
    case .list, .listPremium, .listComfort: false
    }
  }

  var flatSubtaskQueue: Bool {
    self == .cardsRefined
  }

  var taskRowStyle: TaskRowStyle {
    switch self {
    case .cards, .cardsRefined: .card
    case .cardsLight: .cardLight
    case .list: .list
    case .listPremium: .listPremium
    case .listComfort: .listComfort
    }
  }

  /// Insets da List — card modes respiram; listas variam de flush a confortável.
  var taskListRowInsets: EdgeInsets {
    switch self {
    case .cards, .cardsRefined, .cardsLight:
      EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
    case .list:
      EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    case .listPremium:
      EdgeInsets(top: 1, leading: 14, bottom: 1, trailing: 14)
    case .listComfort:
      EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16)
    }
  }

  var menuIcon: HugeiconsAsset {
    switch self {
    case .cards, .cardsRefined, .cardsLight: Hugeicons.grid
    case .list, .listPremium, .listComfort: Hugeicons.listView
    }
  }

  static func from(_ raw: String) -> ProjectDisplayMode {
    switch raw {
    case "list": .list
    case "listPremium", "listRefined": .listPremium
    case "listComfort", "listPlus": .listComfort
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
  case listComfort

  var isCardFamily: Bool {
    switch self {
    case .card, .cardLight: true
    case .list, .listPremium, .listComfort: false
    }
  }

  var isListFamily: Bool { !isCardFamily }

  /// Hairline Things-style sob o header (nunca no painel de subtarefas / UIKit panelHost).
  var showsListHairline: Bool {
    switch self {
    case .listPremium, .listComfort: true
    default: false
    }
  }

  /// Divisor indentado entre header e 1ª subtarefa (só Lista clássica).
  var showsListParentDivider: Bool {
    self == .list
  }
}
