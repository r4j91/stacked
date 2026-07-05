import SwiftUI

/// Miniatura estática para o seletor em Aparência (Parte B — Fase 3).
struct NavBarStylePreview: View {
  let style: NavBarStyle
  let colors: AppThemeColors
  var selected: Bool = false

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8)
        .fill(colors.surfaceVariant)
      previewContent
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
    }
    .frame(width: 56, height: 36)
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .overlay {
      RoundedRectangle(cornerRadius: 8)
        .strokeBorder(
          selected ? colors.accent : Color.white.opacity(0.08),
          lineWidth: selected ? 1.5 : 1
        )
    }
  }

  @ViewBuilder
  private var previewContent: some View {
    switch style {
    case .classic:
      classicPreview
    case .expanded:
      expandedPreview
    case .island:
      islandPreview
    }
  }

  private var classicPreview: some View {
    HStack(spacing: 3) {
      ForEach(0..<5, id: \.self) { i in
        Circle()
          .fill(i == 0 ? colors.accent : colors.textTertiary.opacity(0.55))
          .frame(width: 4, height: 4)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 2)
    .background(Capsule().fill(colors.navBar.opacity(0.5)))
  }

  private var expandedPreview: some View {
    HStack(spacing: 2) {
      Capsule()
        .fill(colors.accent.opacity(0.35))
        .frame(width: 14, height: 8)
      ForEach(0..<4, id: \.self) { _ in
        Circle()
          .fill(colors.textTertiary.opacity(0.55))
          .frame(width: 3.5, height: 3.5)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 2)
    .background(Capsule().fill(colors.navBar.opacity(0.5)))
  }

  private var islandPreview: some View {
    Capsule()
      .fill(colors.navBar.opacity(0.55))
      .overlay {
        HStack(spacing: 2) {
          Circle().fill(colors.accent).frame(width: 4, height: 4)
          RoundedRectangle(cornerRadius: 1)
            .fill(colors.textSecondary.opacity(0.7))
            .frame(width: 10, height: 3)
          HStack(spacing: 1) {
            ForEach(0..<3, id: \.self) { _ in
              Circle().fill(colors.textTertiary).frame(width: 1.5, height: 1.5)
            }
          }
        }
        .padding(.horizontal, 6)
      }
      .frame(width: 28, height: 10)
      .frame(maxWidth: .infinity)
  }
}
