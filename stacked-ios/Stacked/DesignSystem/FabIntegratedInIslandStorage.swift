import Foundation

// FAB_INTEGRADO_ETAPA1 — persistência do toggle em Aparência.
enum FabIntegratedInIslandStorage {
  static let key = "fabIntegratedInIsland"

  static var isEnabled: Bool {
    UserDefaults.standard.object(forKey: key) as? Bool ?? false
  }
}
