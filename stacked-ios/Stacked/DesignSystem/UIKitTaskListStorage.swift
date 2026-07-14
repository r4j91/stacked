import Foundation

/// Aparência — lista experimental UIKit (UICollectionView + SwiftUI rows).
/// Desligado por padrão; fácil A/B e revert sem perder o resto das opts de scroll.
enum UIKitTaskListStorage {
  static let key = "experimental.uikitTaskList"

  static var isEnabled: Bool {
    UserDefaults.standard.bool(forKey: key)
  }
}
