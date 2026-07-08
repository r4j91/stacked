import Foundation
import Hugeicons

/// Paridade `lib/theme/project_display_mode.dart`
enum ProjectDisplayMode: String, CaseIterable {
  case cards
  case cardsRefined
  case list

  var label: String {
    switch self {
    case .cards: "Balões"
    case .cardsRefined: "Balões+"
    case .list: "Lista"
    }
  }

  var usesCardStyle: Bool {
    self == .cards || self == .cardsRefined
  }

  var flatSubtaskPanel: Bool {
    self == .cardsRefined
  }

  var menuIcon: HugeiconsAsset {
    switch self {
    case .cards: Hugeicons.grid
    case .cardsRefined: Hugeicons.grid
    case .list: Hugeicons.listView
    }
  }

  static func from(_ raw: String) -> ProjectDisplayMode {
    switch raw {
    case "list", "listRefined": .list
    case "cardsRefined": .cardsRefined
    case "cards": .cards
    case "folders", "hybrid": .cards
    default: .cards
    }
  }
}
