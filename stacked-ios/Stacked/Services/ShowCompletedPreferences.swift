import Foundation

// Paridade lib/screens/* — preferência de "mostrar concluídas" por tela, não global.
enum ShowCompletedPreferences {
  static let todayKey = "today_show_completed"
  static let inboxKey = "inbox_show_completed"

  static func projectKey(projectId: String) -> String {
    "proj_detail_show_completed_\(projectId)"
  }

  static func savedFilterKey(filterId: String) -> String {
    "saved_filter_show_completed_\(filterId)"
  }

  /// `default` só aplica quando a chave ainda não foi gravada.
  static func value(forKey key: String, default defaultValue: Bool) -> Bool {
    guard UserDefaults.standard.object(forKey: key) != nil else { return defaultValue }
    return UserDefaults.standard.bool(forKey: key)
  }

  static func set(_ value: Bool, forKey key: String) {
    UserDefaults.standard.set(value, forKey: key)
  }
}
