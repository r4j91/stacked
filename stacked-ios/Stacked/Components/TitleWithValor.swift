import SwiftUI

/// Título + valor em accent do tema (parcelas / subtarefas com `valor`).
struct TitleWithValor: View {
  let title: String
  let valor: Double?
  let titleFont: Font
  let titleColor: Color
  let accent: Color
  var done: Bool = false
  var lineLimit: Int = 2
  var valorFont: Font? = nil

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 6) {
      Text(title)
        .font(titleFont)
        .foregroundStyle(titleColor)
        .strikethrough(done)
        .lineLimit(lineLimit)
        .truncationMode(.tail)
        .layoutPriority(1)
      if let valor {
        Text(CurrencyFormat.brl(valor))
          .font(valorFont ?? titleFont)
          .foregroundStyle(done ? accent.opacity(0.45) : accent)
          .monospacedDigit()
          .lineLimit(1)
          .fixedSize(horizontal: true, vertical: false)
      }
    }
  }
}
