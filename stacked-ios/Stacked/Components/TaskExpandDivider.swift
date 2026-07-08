import SwiftUI

/// Paridade `lib/widgets/task_expand_divider.dart`
enum TaskExpandDividerStyle {
  static let thickness: CGFloat = 0.5
  static let alpha: CGFloat = 0.12

  static let cardParentInset: CGFloat = 48
  static let cardSubtaskInset: CGFloat = 60
  static let listParentInset: CGFloat = 50

  static func listSubtaskInset(rowLeading: CGFloat) -> CGFloat {
    rowLeading + DoneCircle.listRowCircleSize
  }
}

struct TaskExpandDivider: View {
  @Environment(ThemeManager.self) private var theme

  let indent: CGFloat
  var colorAlpha: CGFloat = TaskExpandDividerStyle.alpha

  var body: some View {
    let c = theme.colors
    Divider()
      .overlay(c.textTertiary.opacity(colorAlpha))
      .frame(height: TaskExpandDividerStyle.thickness)
      .padding(.leading, indent)
  }
}
