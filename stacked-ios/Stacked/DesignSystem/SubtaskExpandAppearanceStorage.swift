import Foundation

/// Aparência — anel de progresso no lugar do contador 0/N (expand continua igual).
enum SubtaskProgressRingStorage {
  static let key = "appearance.subtaskProgressRing"
  static let defaultEnabled = true

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

/// Aparência — progresso de parcelas na linha (no lugar do anel, só em tarefas parceladas).
enum InstallmentProgressStorage {
  static let key = "appearance.installmentProgressOnCard"
  /// Off por padrão — opção experimental pra testar.
  static let defaultEnabled = false

  static var isEnabled: Bool {
    UserDefaults.standard.object(forKey: key) as? Bool ?? defaultEnabled
  }
}
