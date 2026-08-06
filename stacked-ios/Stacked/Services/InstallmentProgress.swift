import Foundation

/// Detecta parcelas geradas (`titulo … / Parcela N`) e resume progresso + valor restante.
enum InstallmentProgress {
  static let titleMarker = " / Parcela "

  struct Snapshot: Equatable {
    let done: Int
    let total: Int
    /// Soma do `valor` das parcelas ainda não pagas. `nil` se nenhuma parcela tem valor.
    let remainingValor: Double?

    var fraction: Double {
      guard total > 0 else { return 0 }
      return Double(done) / Double(total)
    }

    var label: String {
      let count = "\(done)/\(total) pagas"
      guard let remainingValor else { return count }
      if remainingValor <= 0 {
        return done >= total ? "\(done)/\(total) pagas" : count
      }
      return "\(count) · \(CurrencyFormat.brl(remainingValor)) restante"
    }
  }

  static func isInstallmentTitle(_ title: String) -> Bool {
    title.contains(titleMarker)
  }

  /// `nil` se a tarefa não parece um parcelamento (≥2 subtarefas com o marcador).
  static func snapshot(
    from subtasks: [Subtask],
    isDone: (Subtask) -> Bool = { $0.done }
  ) -> Snapshot? {
    let parcels = subtasks.filter { isInstallmentTitle($0.title) }
    guard parcels.count >= 2 else { return nil }

    let done = parcels.reduce(into: 0) { count, sub in
      if isDone(sub) { count += 1 }
    }
    let unpaidValores = parcels.compactMap { sub -> Double? in
      guard !isDone(sub), let valor = sub.valor else { return nil }
      return valor
    }
    let anyValor = parcels.contains { $0.valor != nil }
    let remaining: Double? = anyValor ? unpaidValores.reduce(0, +) : nil

    return Snapshot(done: done, total: parcels.count, remainingValor: remaining)
  }
}
