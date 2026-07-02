import SwiftUI

// Paridade lib/widgets/done_circle.dart — check verde padrão global
struct DoneCircle: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let done: Bool
  var size: CGFloat = 22
  var borderWidth: CGFloat = 2
  var tickSize: CGFloat = 13
  var ringColor: Color = Color(hex: 0x6B6E76)
  var ringFillAlpha: CGFloat = 0

  @State private var fillScale: CGFloat = 1
  @State private var tickScale: CGFloat = 1
  @State private var tickOpacity: Double = 1

  private static let doneColor = AppColors.success
  private static let completeBeginScale: CGFloat = 0.6

  var body: some View {
    ZStack {
      if done {
        Circle()
          .fill(Self.doneColor.opacity(0.15))
          .overlay(
            Circle().strokeBorder(Self.doneColor, lineWidth: borderWidth)
          )
          .scaleEffect(fillScale)

        StackedIcons.icon(.check, size: tickSize, color: Self.doneColor)
          .scaleEffect(tickScale)
          .opacity(tickOpacity)
      } else {
        Circle()
          .fill(ringFillAlpha > 0 ? ringColor.opacity(ringFillAlpha) : .clear)
          .overlay(
            Circle().strokeBorder(ringColor, lineWidth: borderWidth)
          )
      }
    }
    .frame(width: size, height: size)
    .onAppear { syncVisualState(animated: false) }
    .onChange(of: done) { wasDone, isDone in
      if isDone && !wasDone {
        playCompleteAnimation()
      } else if !isDone && wasDone {
        resetVisualState()
      }
    }
  }

  private func syncVisualState(animated: Bool) {
    if done {
      fillScale = 1
      tickScale = 1
      tickOpacity = 1
    } else {
      fillScale = 1
      tickScale = 0
      tickOpacity = 0
    }
    _ = animated
  }

  private func resetVisualState() {
    fillScale = 1
    tickScale = 0
    tickOpacity = 0
  }

  private func playCompleteAnimation() {
    fillScale = Self.completeBeginScale
    tickScale = 0.5
    tickOpacity = 0
    // SUBSTITUIDO_FASE5: withAnimation(AppMotion.bouncy) sem reduceMotion
    AppMotion.animate(AppMotion.bouncy, reduceMotion: reduceMotion) {
      fillScale = 1
      tickScale = 1
      tickOpacity = 1
    }
  }
}

// SUBSTITUIDO_FASE3A: Group if/else + .animation(AppMotion.snappy(reduceMotion:), value: done)
// Group {
//   if done { Circle()... } else { Circle()... }
// }
// .animation(AppMotion.snappy(reduceMotion: reduceMotion), value: done)
