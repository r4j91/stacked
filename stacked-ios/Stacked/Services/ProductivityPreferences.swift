import Foundation

enum ProductivityPreferences {
  static let quickAddDescriptionKey = "productivity_quick_add_description"
  /// Notas no detail via painel ancorado (estilo menu de meta). Off = campo inline atual.
  static let anchoredDetailNotesKey = "productivity_anchored_detail_notes"

  static var quickAddDescriptionEnabled: Bool {
    get {
      UserDefaults.standard.object(forKey: quickAddDescriptionKey) as? Bool ?? true
    }
    set {
      UserDefaults.standard.set(newValue, forKey: quickAddDescriptionKey)
    }
  }

  static var anchoredDetailNotesEnabled: Bool {
    get {
      UserDefaults.standard.object(forKey: anchoredDetailNotesKey) as? Bool ?? true
    }
    set {
      UserDefaults.standard.set(newValue, forKey: anchoredDetailNotesKey)
    }
  }
}
