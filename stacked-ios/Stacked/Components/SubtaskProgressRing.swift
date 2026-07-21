import SwiftUI

/// Anel de progresso das subtarefas (Aparência) — só visual do botão/contador.
struct SubtaskProgressRing: View {
  @Environment(ThemeManager.self) private var theme
  let done: Int
  let total: Int
  var size: CGFloat = 22
  var lineWidth: CGFloat = 2.5

  private var progress: CGFloat {
    guard total > 0 else { return 0 }
    return min(1, CGFloat(done) / CGFloat(total))
  }

  var body: some View {
    let c = theme.colors
    ZStack {
      Circle()
        .stroke(c.textTertiary.opacity(0.28), lineWidth: lineWidth)
      Circle()
        .trim(from: 0, to: progress)
        .stroke(
          c.accent,
          style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
      Text("\(min(done, total))")
        .font(.system(size: size * 0.38, weight: .bold))
        .foregroundStyle(c.textSecondary)
        .monospacedDigit()
    }
    .frame(width: size, height: size)
    .accessibilityHidden(true)
  }
}
