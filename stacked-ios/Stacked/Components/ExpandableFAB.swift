import SwiftUI

// Paridade lib/widgets/responsive_layout.dart _ExpandableFAB
struct ExpandableFAB: View {
  @Environment(ThemeManager.self) private var theme
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
      StackedIcons.image(.plus)
        .font(.system(size: 22, weight: .medium))
        .foregroundStyle(c.isDark ? c.background : Color(hex: 0x1A1B1E))
        .rotationEffect(.degrees(isOpen ? 45 : 0))
        .frame(width: AppLayout.fabSize, height: AppLayout.fabSize)
        .background(c.accent)
        .clipShape(Circle())
        .overlay(Circle().stroke(c.textPrimary.opacity(0.08), lineWidth: 0.8))
    }
    .buttonStyle(.plain)
    .accessibilityLabel(isOpen ? "Fechar menu de ações" : "Criar novo")
    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isOpen)
  }
}
