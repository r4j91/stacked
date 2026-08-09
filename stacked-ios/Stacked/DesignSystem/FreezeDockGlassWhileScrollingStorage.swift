import Foundation

/// Modo do chrome translúcido (dock, FAB, headers, pills).
/// Só Ao vivo / Fosco — Quieto e Opaco foram removidos (migram para Fosco).
enum ChromeGlassMode: String, CaseIterable, Identifiable {
  case live
  case frosted

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .live: "Ao vivo"
    case .frosted: "Fosco"
    }
  }

  var subtitle: String {
    switch self {
    case .live: "Animação na barra"
    case .frosted: "Vidro com desfoque"
    }
  }
}

enum ChromeGlassModeStorage {
  static let key = "chromeGlassMode"
  static let defaultMode: ChromeGlassMode = .frosted
  static var defaultRawValue: String { defaultMode.rawValue }

  /// Migra toggles antigos e coerção Quiet/Opaco → Fosco.
  static func migrateIfNeeded() {
    let ud = UserDefaults.standard
    if ud.object(forKey: key) == nil {
      let mode: ChromeGlassMode
      if ud.bool(forKey: DisableAllGlassStorage.legacyKey)
        || ud.bool(forKey: AlwaysStaticGlassStorage.legacyKey)
      {
        mode = .frosted
      } else if let frosted = ud.object(forKey: StaticFrostedGlassStorage.legacyKey) as? Bool {
        mode = frosted ? .frosted : .live
      } else {
        mode = defaultMode
      }
      ud.set(mode.rawValue, forKey: key)
      return
    }

    coerceRetiredModesIfNeeded()
  }

  /// Quieto / Opaco gravados em builds antigos → Fosco.
  static func coerceRetiredModesIfNeeded() {
    let ud = UserDefaults.standard
    guard let raw = ud.string(forKey: key) else { return }
    if raw == "quiet" || raw == "solid" {
      ud.set(defaultMode.rawValue, forKey: key)
    }
  }

  static var current: ChromeGlassMode {
    migrateIfNeeded()
    let raw = UserDefaults.standard.string(forKey: key) ?? defaultRawValue
    return mode(from: raw)
  }

  static func mode(from rawValue: String) -> ChromeGlassMode {
    if let mode = ChromeGlassMode(rawValue: rawValue) { return mode }
    if rawValue == "quiet" || rawValue == "solid" {
      UserDefaults.standard.set(defaultMode.rawValue, forKey: key)
      return defaultMode
    }
    return defaultMode
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

  /// Opaco só por acessibilidade (Reduce Transparency) — modo Opaco foi removido.
  static func prefersSolid(reduceTransparency: Bool, mode: ChromeGlassMode? = nil) -> Bool {
    _ = mode
    return reduceTransparency
  }

  static func prefersFrosted(mode: ChromeGlassMode? = nil) -> Bool {
    (mode ?? ChromeGlassModeStorage.current) == .frosted
  }

  static func prefersNoLiveGlass(mode: ChromeGlassMode? = nil) -> Bool {
    (mode ?? ChromeGlassModeStorage.current) != .live
  }

  /// Fosco: pills estáticas custom. Ao vivo: glass nativo com morph.
  static func prefersStaticToolbarPills(mode: ChromeGlassMode? = nil) -> Bool {
    prefersFrosted(mode: mode)
  }
}
