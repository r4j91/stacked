import Foundation

/// Aparência — listas em UICollectionView (caminho único; SwiftUI list retired).
enum UIKitTaskListStorage {
  static let key = "experimental.uikitTaskList"
  static let defaultEnabled = true

  static func registerDefaultsIfNeeded() {
    UserDefaults.standard.set(true, forKey: key)
  }

  /// Sempre ligado — o toggle saiu do menu; não voltamos para List SwiftUI.
  static var isEnabled: Bool { true }
}
