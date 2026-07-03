import SwiftUI

/// Chrome compartilhado — Quick Add e Novo projeto (painéis ancorados ao teclado).
enum KeyboardFloatingPanelStyle {
  static let defaultCornerRadius: CGFloat = 22

  /// Fundo do painel — `surface` escurecido, menos “chapado” que `surfaceVariant` sólido.
  @ViewBuilder
  static func chrome(
    colors: AppThemeColors,
    cornerRadius: CGFloat = defaultCornerRadius
  ) -> some View {
    let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

    shape
      .fill(colors.surface)
      .overlay {
        shape.fill(colors.background.opacity(colors.isDark ? 0.28 : 0.05))
      }
      .overlay {
        shape.fill(
          LinearGradient(
            stops: [
              .init(color: colors.textPrimary.opacity(colors.isDark ? 0.04 : 0.07), location: 0),
              .init(color: .clear, location: 0.42),
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        )
      }
      .overlay {
        shape.strokeBorder(colors.textPrimary.opacity(colors.isDark ? 0.06 : 0.08), lineWidth: 0.5)
      }
      .shadow(color: .black.opacity(colors.isDark ? 0.22 : 0.10), radius: 14, y: -4)
  }

  /// Chips / linhas internas sobre o painel.
  static func chipBackground(_ colors: AppThemeColors) -> Color {
    colors.isDark
      ? colors.surfaceVariant.opacity(0.42)
      : colors.surfaceVariant.opacity(0.72)
  }
}
