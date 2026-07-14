import Foundation

/// Aparência — congela o Liquid Glass do dock durante o scroll (sem amostrar a lista ao vivo).
enum FreezeDockGlassWhileScrollingStorage {
  static let key = "freezeDockGlassWhileScrolling"

  /// Ligado por padrão: modo fluido recomendado. Desligar compara com glass ao vivo.
  static var isEnabled: Bool {
    UserDefaults.standard.object(forKey: key) as? Bool ?? true
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
