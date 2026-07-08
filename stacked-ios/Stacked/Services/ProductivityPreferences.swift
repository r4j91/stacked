import Foundation

enum ProductivityPreferences {
  static let quickAddDescriptionKey = "productivity_quick_add_description"

  static var quickAddDescriptionEnabled: Bool {
    get {
      UserDefaults.standard.object(forKey: quickAddDescriptionKey) as? Bool ?? false
    }
    set {
      UserDefaults.standard.set(newValue, forKey: quickAddDescriptionKey)
    }
  }
}
