import Foundation

/// Arte abstrata estilo Aurora Minimal — gradientes premium, não realista.
enum HomeHeroAuroraArt: String, CaseIterable, Identifiable {
  case calm
  case dusk
  case ember

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .calm: "Aurora teal"
    case .dusk: "Aurora violeta"
    case .ember: "Aurora titanium"
    }
  }

  var subtitle: String {
    switch self {
    case .calm: "Ondas teal suaves como no conceito"
    case .dusk: "Ribbons violeta e roxo premium"
    case .ember: "Brilho titanium cinza monocromático"
    }
  }

  func clearAssetName() -> String {
    switch self {
    case .calm: "HeroAuroraCalmClear"
    case .dusk: "HeroAuroraDuskClear"
    case .ember: "HeroAuroraEmberClear"
    }
  }

  func overdueAssetName() -> String {
    switch self {
    case .calm: "HeroAuroraCalmOverdue"
    case .dusk: "HeroAuroraDuskOverdue"
    case .ember: "HeroAuroraEmberOverdue"
    }
  }

  var overdueAccent: UInt32 {
    switch self {
    case .calm: 0x5A9E8C
    case .dusk: 0x9B6FD4
    case .ember: 0x8A8D94
    }
  }

  var overdueAccentDeep: UInt32 {
    switch self {
    case .calm: 0x3D5A52
    case .dusk: 0x5A4578
    case .ember: 0x4A4D54
    }
  }
}
