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
      LiquidGlass.fab(tintColor: c.accent, solidFallback: c.accent) {
        StackedIcons.image(.plus)
          .font(.system(size: 22, weight: .medium))
          .foregroundStyle(c.onAccent)
          .rotationEffect(.degrees(isOpen ? 45 : 0))
          .animation(AppMotion.bouncy(reduceMotion: reduceMotion), value: isOpen)
      }
      .frame(width: AppLayout.fabSize, height: AppLayout.fabSize)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(isOpen ? "Fechar menu de ações" : "Criar novo")
  }
}
