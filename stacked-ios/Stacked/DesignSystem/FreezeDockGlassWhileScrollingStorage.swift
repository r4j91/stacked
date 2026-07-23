import Foundation

/// Aparência — congela o Liquid Glass do dock durante o scroll (sem amostrar a lista ao vivo).
enum FreezeDockGlassWhileScrollingStorage {
  static let key = "freezeDockGlassWhileScrolling"

  /// Desligado por padrão (Glass fosco / chrome estático recomendado).
  static var isEnabled: Bool {
    UserDefaults.standard.object(forKey: key) as? Bool ?? false
  }
}

/// Aparência — dock sempre no fill estático (sem Liquid Glass ao vivo), para comparar visual.
enum AlwaysFrozenDockGlassStorage {
  static let key = "alwaysFrozenDockGlass"

  /// Desligado por padrão: glass ao vivo (com pausa no scroll, se configurado).
  static var isEnabled: Bool {
    UserDefaults.standard.object(forKey: key) as? Bool ?? false
  }
}

/// Aparência — desliga Liquid Glass em todo o app (dock, toolbar, FAB, headers, popovers).
enum DisableAllGlassStorage {
  static let key = "disableAllGlass"

  /// Desligado por padrão. Ligado = fill sólido (mesmo path do reduce transparency).
  static var isEnabled: Bool {
    UserDefaults.standard.object(forKey: key) as? Bool ?? false
  }
}

/// Aparência — glass “pausado” em todo o app: vê atrás, sem Liquid Glass ao vivo / morph.
enum AlwaysStaticGlassStorage {
  static let key = "alwaysStaticGlass"

  /// Desligado por padrão. Ligado = fill estático translúcido (igual freeze do dock).
  static var isEnabled: Bool {
    UserDefaults.standard.object(forKey: key) as? Bool ?? false
  }
}

/// Aparência — Material + tint em todo o chrome: visual glass sem Liquid Glass / morph ao vivo.
enum StaticFrostedGlassStorage {
  static let key = "staticFrostedGlass"

  /// Ligado por padrão: blur clássico sem morph (perfil atual do app).
  static var isEnabled: Bool {
    UserDefaults.standard.object(forKey: key) as? Bool ?? true
  }
}

enum GlassChromePreference {
  /// Sólido quando a11y pede ou o usuário desativou o glass.
  static func prefersSolid(reduceTransparency: Bool, disableAllGlass: Bool? = nil) -> Bool {
    reduceTransparency || (disableAllGlass ?? DisableAllGlassStorage.isEnabled)
  }

  /// Fill estático translúcido (sem glassEffect) — dock + botões/headers.
  static func prefersStaticFrozen(alwaysStaticGlass: Bool? = nil) -> Bool {
    alwaysStaticGlass ?? AlwaysStaticGlassStorage.isEnabled
  }

  /// Material + tint (sem glassEffect / morph) — chrome inteiro.
  static func prefersStaticFrosted(staticFrostedGlass: Bool? = nil) -> Bool {
    staticFrostedGlass ?? StaticFrostedGlassStorage.isEnabled
  }

  /// Qualquer modo que não monta Liquid Glass ao vivo.
  static func prefersNoLiveGlass(
    alwaysStaticGlass: Bool? = nil,
    staticFrostedGlass: Bool? = nil
  ) -> Bool {
    prefersStaticFrozen(alwaysStaticGlass: alwaysStaticGlass)
      || prefersStaticFrosted(staticFrostedGlass: staticFrostedGlass)
  }

  /// Pausar morph/amostragem no scroll — mesmo fill do dock congelado (chrome inteiro).
  static func prefersScrollFrozen(
    freezeWhileScrolling: Bool? = nil,
    isContentScrolling: Bool,
    alwaysStaticGlass: Bool? = nil,
    staticFrostedGlass: Bool? = nil
  ) -> Bool {
    if prefersNoLiveGlass(
      alwaysStaticGlass: alwaysStaticGlass,
      staticFrostedGlass: staticFrostedGlass
    ) {
      return true
    }
    let freeze = freezeWhileScrolling ?? FreezeDockGlassWhileScrollingStorage.isEnabled
    return freeze && isContentScrolling
  }
}
