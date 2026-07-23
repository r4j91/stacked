import SwiftUI

enum NavBarStyle: String, CaseIterable, Identifiable {
  case classic
  case expanded
  case island

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .classic: "Clássica"
    case .expanded: "Expandida"
    case .island: "Ilha"
    }
  }
}

// MARK: - Persistência (@AppStorage)

enum NavBarStyleStorage {
  static let key = "navBarStyle"

  static var defaultRawValue: String { NavBarStyle.island.rawValue }

  static func style(from rawValue: String) -> NavBarStyle {
    NavBarStyle(rawValue: rawValue) ?? .island
  }
}
