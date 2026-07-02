import SwiftUI

/// Placeholder até Fase 2+ — paridade das telas Flutter.
struct TabPlaceholderView: View {
  @Environment(ThemeManager.self) private var theme
  let tab: NavTab

  var body: some View {
    let c = theme.colors

    VStack(alignment: .leading, spacing: 8) {
      Text(tab.label)
        .font(AppTypography.screenTitle)
        .foregroundStyle(c.textPrimary)

      if let subtitle = tab.subtitle {
        Text(subtitle)
          .font(AppTypography.taskPreview)
          .foregroundStyle(c.textSecondary)
      }

      Spacer()

      Text("Fase 2 — lista de tarefas")
        .font(AppTypography.meta)
        .foregroundStyle(c.textTertiary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .padding(.horizontal, 20)
    .padding(.top, 8)
    .background(c.background)
  }
}
