import SwiftUI

// Paridade lib/widgets/done_circle.dart — check verde padrão global
struct DoneCircle: View {
  let done: Bool
  var size: CGFloat = 22
  var borderWidth: CGFloat = 2
  var tickSize: CGFloat = 13
  var ringColor: Color = Color(hex: 0x6B6E76)
  var ringFillAlpha: CGFloat = 0

  private static let doneColor = AppColors.success

  var body: some View {
    Group {
      if done {
        Circle()
          .fill(Self.doneColor.opacity(0.15))
          .overlay(
            Circle().strokeBorder(Self.doneColor, lineWidth: borderWidth)
          )
          .frame(width: size, height: size)
          .overlay {
            StackedIcons.icon(.check, size: tickSize, color: Self.doneColor)
          }
      } else {
        Circle()
          .fill(ringFillAlpha > 0 ? ringColor.opacity(ringFillAlpha) : .clear)
          .overlay(
            Circle().strokeBorder(ringColor, lineWidth: borderWidth)
          )
          .frame(width: size, height: size)
      }
    }
    .animation(.easeOut(duration: 0.15), value: done)
  }
}
