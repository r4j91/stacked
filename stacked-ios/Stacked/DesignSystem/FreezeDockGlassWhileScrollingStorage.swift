import Foundation

/// Modo único do chrome translúcido (dock, FAB, headers, pills).
/// Substitui os toggles quieto / fosco / opaco e remove pausar-ao-rolar / barra-sem-efeito.
enum ChromeGlassMode: String, CaseIterable, Identifiable {
  case live
  case quiet
  case frosted
  case solid

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .live: "Ao vivo"
    case .quiet: "Quieto"
    case .frosted: "Fosco"
    case .solid: "Opaco"
    }
  }

  var subtitle: String {
    switch self {
    case .live: "Animação na barra"
    case .quiet: "Translúcido, sem animação"
    case .frosted: "Vidro com desfoque"
    case .solid: "Sem ver o que passa atrás"
    }
  }
}

enum ChromeGlassModeStorage {
  static let key = "chromeGlassMode"
  static let defaultMode: ChromeGlassMode = .frosted
  static var defaultRawValue: String { defaultMode.rawValue }

  /// Migra toggles antigos uma vez; depois só `chromeGlassMode`.
  static func migrateIfNeeded() {
    let ud = UserDefaults.standard
    guard ud.object(forKey: key) == nil else { return }

    let mode: ChromeGlassMode
    if ud.bool(forKey: DisableAllGlassStorage.legacyKey) {
      mode = .solid
    } else if ud.bool(forKey: AlwaysStaticGlassStorage.legacyKey) {
      mode = .quiet
    } else if let frosted = ud.object(forKey: StaticFrostedGlassStorage.legacyKey) as? Bool {
      mode = frosted ? .frosted : .live
    } else {
      mode = defaultMode
    }
    ud.set(mode.rawValue, forKey: key)
  }

  static var current: ChromeGlassMode {
    migrateIfNeeded()
    let raw = UserDefaults.standard.string(forKey: key) ?? defaultRawValue
    return ChromeGlassMode(rawValue: raw) ?? defaultMode
  }

  static func mode(from rawValue: String) -> ChromeGlassMode {
    ChromeGlassMode(rawValue: rawValue) ?? defaultMode
  }
}

/// Legado — só para migração / leitores que ainda leem a chave antiga.
enum DisableAllGlassStorage {
  static let legacyKey = "disableAllGlass"
  static let key = legacyKey
}

enum AlwaysStaticGlassStorage {
  static let legacyKey = "alwaysStaticGlass"
  static let key = legacyKey
}

enum StaticFrostedGlassStorage {
  static let legacyKey = "staticFrostedGlass"
  static let key = legacyKey
}

enum GlassChromePreference {
  static func mode(rawValue: String? = nil) -> ChromeGlassMode {
    if let rawValue { return ChromeGlassModeStorage.mode(from: rawValue) }
    return ChromeGlassModeStorage.current
  }

  static func prefersSolid(reduceTransparency: Bool, mode: ChromeGlassMode? = nil) -> Bool {
    reduceTransparency || (mode ?? ChromeGlassModeStorage.current) == .solid
  }

  static func prefersQuiet(mode: ChromeGlassMode? = nil) -> Bool {
    (mode ?? ChromeGlassModeStorage.current) == .quiet
  }

  static func prefersFrosted(mode: ChromeGlassMode? = nil) -> Bool {
    (mode ?? ChromeGlassModeStorage.current) == .frosted
  }

  static func prefersNoLiveGlass(mode: ChromeGlassMode? = nil) -> Bool {
    let m = mode ?? ChromeGlassModeStorage.current
    return m != .live
  }
}
