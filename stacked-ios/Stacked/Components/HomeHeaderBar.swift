import SwiftUI

// Paridade home_screen.dart _buildHeader + header_liquid_pill.dart
struct HomeHeaderBar: View {
  @Environment(ThemeManager.self) private var theme
  @State private var store = HomeStore.shared
  @Binding var showProductivity: Bool
  @Binding var showNotifications: Bool
  @Binding var showSettings: Bool

  var body: some View {
    let c = theme.colors

    HStack(spacing: 12) {
      Button {
        showProductivity = true
      } label: {
        LiquidGlass.headerPill(navBarColor: c.navBar, textPrimary: c.textPrimary) {
          UserAvatarView(
            url: store.avatarURL,
            initials: store.avatarInitials,
            size: AppLayout.headerAvatarSize
          )
          .frame(width: AppLayout.headerControlSize, height: AppLayout.headerControlSize)
        }
      }
      .buttonStyle(PressableStyle(cornerRadius: AppLayout.headerControlSize / 2))
      .accessibilityLabel("Relatório de produtividade")

      Spacer()

      LiquidGlass.headerPill(navBarColor: c.navBar, textPrimary: c.textPrimary) {
        HStack(spacing: 0) {
          headerIconButton(.notifications) { showNotifications = true }
          Rectangle()
            .fill(c.textTertiary.opacity(0.2))
            .frame(width: 1, height: AppLayout.headerControlSize * 0.5)
          headerIconButton(.settings) { showSettings = true }
        }
        .padding(.horizontal, 2)
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 8)
    .padding(.bottom, 10)
  }

  private func headerIconButton(_ icon: StackedIconKey, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      StackedIcons.image(icon)
        .font(.system(size: AppLayout.headerIconSize, weight: .medium))
        .foregroundStyle(theme.colors.textSecondary)
        .frame(width: AppLayout.headerControlSize, height: AppLayout.headerControlSize)
    }
    .buttonStyle(PressableStyle(cornerRadius: AppLayout.headerControlSize / 2))
  }
}
