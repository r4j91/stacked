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
    // Abismo: `background` no overlay escurecia demais o painel e os chips
    // (surfaceVariant@opacity) viravam bolhas mais escuras que a barra.
    let dimOpacity: Double = {
      if ThemeManager.shared.usesAtmosphericBackground {
        return colors.isDark ? 0.10 : 0.05
      }
      return colors.isDark ? 0.28 : 0.05
    }()

    shape
      .fill(colors.surface)
      .overlay {
        shape.fill(colors.background.opacity(dimOpacity))
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
    // Abismo: surfaceVariant compostado no painel vira círculo mais escuro.
    // Lift branco sutil — mesmo contraste relativo dos outros temas.
    if ThemeManager.shared.usesAtmosphericBackground {
      return colors.textPrimary.opacity(colors.isDark ? 0.07 : 0.05)
    }
    return colors.isDark
      ? colors.surfaceVariant.opacity(0.42)
      : colors.surfaceVariant.opacity(0.72)
  }
}
