import Foundation

/// Aparência — lista experimental UIKit (UICollectionView + SwiftUI rows).
/// Desligado por padrão; cobre Inbox / Hoje / Em breve / Projetos. Desligar = SwiftUI List.
enum UIKitTaskListStorage {
  static let key = "experimental.uikitTaskList"

  static var isEnabled: Bool {
    UserDefaults.standard.bool(forKey: key)
  }
}
