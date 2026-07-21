import Foundation

/// Aparência — anel de progresso no lugar do contador 0/N (expand continua igual).
enum SubtaskProgressRingStorage {
  static let key = "appearance.subtaskProgressRing"
  static let defaultEnabled = false

  static var isEnabled: Bool {
    UserDefaults.standard.object(forKey: key) as? Bool ?? defaultEnabled
  }
}

/// Aparência — trilho/galho à esquerda na lista expandida de subtarefas.
enum SubtaskBranchStorage {
  static let key = "appearance.subtaskBranch"
  static let defaultEnabled = false

  static var isEnabled: Bool {
    UserDefaults.standard.object(forKey: key) as? Bool ?? defaultEnabled
  }
}
