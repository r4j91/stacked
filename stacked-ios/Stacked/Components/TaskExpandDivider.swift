import SwiftUI

/// Paridade `lib/widgets/task_expand_divider.dart`
enum TaskExpandDividerStyle {
  static let thickness: CGFloat = 0.5
  static let alpha: CGFloat = 0.12
  /// Peso do hairline Lista+ / Lista premium (pai e entre subtarefas).
  static let listHairlineAlpha: CGFloat = 0.045
  static let listHairlineThickness: CGFloat = 1

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
  /// `true` = mesma tinta/traço do hairline Lista+/premium (`Rectangle` + textPrimary).
  /// Evita o `Divider()` do sistema, que fica mais forte mesmo com overlay fraco.
  var usePrimaryTint: Bool = false

  var body: some View {
    let c = theme.colors
    Group {
      if usePrimaryTint {
        Rectangle()
          .fill(c.textPrimary.opacity(colorAlpha))
          .frame(height: TaskExpandDividerStyle.listHairlineThickness)
      } else {
        Divider()
          .overlay(c.textTertiary.opacity(colorAlpha))
          .frame(height: AppLayout.pixelSnap(TaskExpandDividerStyle.thickness))
      }
    }
    .padding(.leading, indent)
  }
}
