import Foundation

/// Aparência — listas fluidas via UICollectionView + SwiftUI rows.
/// Ligado por padrão; cobre Inbox, Hoje, Em breve, Projetos, Registro, Busca e filtros.
enum UIKitTaskListStorage {
  static let key = "experimental.uikitTaskList"
  static let defaultEnabled = true

  static func registerDefaultsIfNeeded() {
    UserDefaults.standard.register(defaults: [key: defaultEnabled])
  }

  static var isEnabled: Bool {
    UserDefaults.standard.bool(forKey: key)
  }
}
