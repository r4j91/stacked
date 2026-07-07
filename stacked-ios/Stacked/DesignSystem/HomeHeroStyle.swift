import SwiftUI

enum HomeHeroStyle: String, CaseIterable, Identifiable {
  case classic
  case orbital
  case horizon
  case capsule
  case openType
  case focus

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .classic: "Clássico"
    case .orbital: "Orbital"
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
