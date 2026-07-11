import Foundation

enum HomeMotivationQuotes {
  private static let items: [(quote: String, footnote: String)] = [
    ("Pequenas ações constantes geram grandes conquistas.", "Continue assim."),
    ("Um passo de cada vez ainda é progresso.", "Mantenha o ritmo."),
    ("Clareza vem de fazer, não só de planejar.", "Foque no próximo passo."),
    ("O que importa hoje é o que você conclui hoje.", "Um item de cada vez."),
    ("Constância supera intensidade isolada.", "Volte amanhã."),
    ("Menos ruído, mais entrega.", "Priorize o essencial."),
    ("Sua lista reflete suas escolhas.", "Escolha com intenção."),
  ]

  static func forToday(calendar: Calendar = .current) -> (quote: String, footnote: String) {
    let day = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 0
    return items[day % items.count]
  }
}
