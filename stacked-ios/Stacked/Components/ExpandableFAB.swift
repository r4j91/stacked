import SwiftUI

// Paridade lib/widgets/responsive_layout.dart _ExpandableFAB
struct ExpandableFAB: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Binding var isOpen: Bool

  var body: some View {
    let c = theme.colors

    Button {
      if isOpen {
        isOpen = false
      } else {
        HapticService.fabOpened()
        isOpen = true
      }
    } label: {
      // SUBSTITUIDO_TEMAS_JADE: LiquidGlass.fab(tintColor: c.accent, solidFallback: c.accent) + onAccent
      LiquidGlass.fab(
        tintColor: c.actionAccent,
        solidFallback: c.actionAccent,
        gradientStart: c.fabGradientStart,
        gradientEnd: c.fabGradientEnd
      ) {
        StackedIcons.image(.plus)
          .font(.system(size: 22, weight: .medium))
          .foregroundStyle(c.onActionAccent)
          .rotationEffect(.degrees(isOpen ? 45 : 0))
          .animation(AppMotion.bouncy(reduceMotion: reduceMotion), value: isOpen)
      }
      .frame(width: AppLayout.fabSize, height: AppLayout.fabSize)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(isOpen ? "Fechar menu de ações" : "Criar novo")
  }
}
