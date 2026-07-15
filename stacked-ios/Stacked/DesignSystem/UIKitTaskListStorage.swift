import Foundation

/// Aparência — "Listas mais fluidas" (UICollectionView + SwiftUI rows).
/// Ligado por padrão; cobre Inbox, Hoje, Em breve, Projetos, Registro, Busca e filtros.
///
/// A chave UserDefaults abaixo mantém o nome histórico `experimental.*` de propósito:
/// renomear resetaria a preferência de quem já ligou/desligou. Não é mais feature experimental.
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
