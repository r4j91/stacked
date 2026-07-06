import SwiftUI

// Paridade home_screen.dart _buildHeader + header_liquid_pill.dart
struct HomeHeaderBar: View {
  @Environment(ThemeManager.self) private var theme
  @State private var store = HomeStore.shared
  @Binding var showProductivity: Bool
  @Binding var showNotifications: Bool
  @Binding var showSettings: Bool

  var body: some View {
    HStack(spacing: 12) {
      HomeHeaderLeading(showProductivity: $showProductivity)
      Spacer()
      HomeHeaderTrailing(
        showNotifications: $showNotifications,
        showSettings: $showSettings
      )
    }
    .padding(.horizontal, 20)
    .padding(.top, 8)
    .padding(.bottom, 10)
  }
}

/// Header na toolbar nativa — pré-estabelece a navbar para push fluido sem padding extra na lista.
struct HomeHeaderToolbar: ToolbarContent {
  @Binding var showProductivity: Bool
  @Binding var showNotifications: Bool
  @Binding var showSettings: Bool

  var body: some ToolbarContent {
    ToolbarItem(id: "stacked-home-leading", placement: .topBarLeading) {
      HomeHeaderLeading(showProductivity: $showProductivity)
    }
    .sharedBackgroundVisibility(.hidden)

    ToolbarItem(id: "stacked-home-trailing", placement: .topBarTrailing) {
      HomeHeaderTrailing(
        showNotifications: $showNotifications,
        showSettings: $showSettings
      )
    }
    .sharedBackgroundVisibility(.hidden)
  }
}

private struct HomeHeaderLeading: View {
  @Environment(ThemeManager.self) private var theme
  @State private var store = HomeStore.shared
  @Binding var showProductivity: Bool

  var body: some View {
    let c = theme.colors
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
  }
}

private struct HomeHeaderTrailing: View {
  @Environment(ThemeManager.self) private var theme
  @Binding var showNotifications: Bool
  @Binding var showSettings: Bool

  var body: some View {
    let c = theme.colors
    LiquidGlass.headerPill(navBarColor: c.navBar, textPrimary: c.textPrimary) {
      HStack(spacing: 0) {
        HomeHeaderIconButton(icon: .notifications, label: "Notificações") {
          showNotifications = true
        }
        Rectangle()
          .fill(c.textTertiary.opacity(0.2))
          .frame(width: 1, height: AppLayout.headerControlSize * 0.5)
        HomeHeaderIconButton(icon: .settings, label: "Configurações") {
          showSettings = true
        }
      }
      .padding(.horizontal, 2)
    }
  }
}

private struct HomeHeaderIconButton: View {
  @Environment(ThemeManager.self) private var theme
  let icon: StackedIconKey
  let label: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      StackedIcons.image(icon)
        .font(.system(size: AppLayout.headerIconSize, weight: .medium))
        .foregroundStyle(theme.colors.textSecondary)
        .frame(width: AppLayout.headerControlSize, height: AppLayout.headerControlSize)
    }
    .buttonStyle(PressableStyle(cornerRadius: AppLayout.headerControlSize / 2))
    .accessibilityLabel(label)
  }
}
