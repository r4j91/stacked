import Foundation

/// Aparência — trilho vertical (linha do tempo) em Hoje / Em breve.
enum TimelineRailStorage {
  static let key = "appearance.timelineRail"
  static let defaultEnabled = false

  static var isEnabled: Bool {
    UserDefaults.standard.object(forKey: key) as? Bool ?? defaultEnabled
  }
}
