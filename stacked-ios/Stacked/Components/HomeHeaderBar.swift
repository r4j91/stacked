import SwiftUI

// Paridade home_screen.dart _buildHeader + header_liquid_pill.dart
struct HomeHeaderBar: View {
  @Environment(ThemeManager.self) private var theme
  @State private var store = HomeStore.shared
  @Binding var showProductivity: Bool
  @Binding var showProfile: Bool
  @Binding var showNotifications: Bool
  @Binding var showSettings: Bool

  var body: some View {
    HStack(spacing: 12) {
      HomeHeaderLeading(showProductivity: $showProductivity, showProfile: $showProfile)
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
  @Binding var showProfile: Bool
  @Binding var showNotifications: Bool
  @Binding var showSettings: Bool

  var body: some ToolbarContent {
    ToolbarItem(id: "stacked-home-leading", placement: .topBarLeading) {
      HomeHeaderLeading(showProductivity: $showProductivity, showProfile: $showProfile)
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
  @Binding var showProfile: Bool
  @AppStorage(HomeTopCardStorage.key) private var topCardEnabled = HomeTopCardStorage.defaultEnabled
  @AppStorage(AppTypeScaleStorage.key) private var typeScaleRaw = AppTypeScaleStorage.defaultRawValue

  /// Sem o card de saudação o nome não aparece em lugar nenhum da Home — a pill assume ele.
  private var pillName: String {
    guard !topCardEnabled else { return "" }
    let name = store.firstName
    guard name.count > 14 else { return name }
    return String(name.prefix(13)) + "…"
  }

  var body: some View {
    let c = theme.colors
    let name = pillName
    Button {
      // Sem o card, Relatórios já está exposto nos atalhos — a pill fica livre
      // para o perfil, que é o que o avatar sugere. Com o card, ela é o único
      // caminho para os relatórios e mantém esse destino.
      if topCardEnabled {
        showProductivity = true
      } else {
        showProfile = true
      }
    } label: {
      LiquidGlass.headerPill(navBarColor: c.navBar, textPrimary: c.textPrimary) {
        HStack(spacing: 6) {
          UserAvatarView(
            url: store.avatarURL,
            initials: store.avatarInitials,
            size: AppLayout.headerAvatarSize
          )
          .frame(width: AppLayout.headerControlSize, height: AppLayout.headerControlSize)

          if !name.isEmpty {
            Text(name)
              .font(AppTypeScaleStorage.scale(from: typeScaleRaw).metrics.rowTitleFont)
              .foregroundStyle(c.textPrimary)
              .lineLimit(1)
              // A toolbar propõe largura apertada e comeria o nome inteiro;
              // o corte em 14 caracteres acima já garante que a pill não estoure.
              .fixedSize(horizontal: true, vertical: false)
              .padding(.trailing, 16)
          }
        }
      }
      .modifier(HomeHeaderQuietBorder())
    }
    .buttonStyle(PressableStyle(cornerRadius: AppLayout.headerControlSize / 2))
    .accessibilityLabel(topCardEnabled ? "Relatório de produtividade" : "Perfil")
  }
}

private struct HomeHeaderTrailing: View {
  @Environment(ThemeManager.self) private var theme
  @State private var notifications = NotificationService.shared
  @Binding var showNotifications: Bool
  @Binding var showSettings: Bool

  var body: some View {
    let c = theme.colors
    LiquidGlass.headerPill(navBarColor: c.navBar, textPrimary: c.textPrimary) {
      HStack(spacing: 0) {
        HomeHeaderIconButton(
          icon: .notifications,
          label: "Notificações",
          showsDot: notifications.hasImminentReminders
        ) {
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
    .modifier(HomeHeaderQuietBorder())
  }
}

/// Contorno igual ao trilho do dock — Quieto / Fosco (sem Liquid Glass ao vivo).
private struct HomeHeaderQuietBorder: ViewModifier {
  @Environment(ThemeManager.self) private var theme
  @AppStorage(ChromeGlassModeStorage.key) private var chromeGlassModeRaw = ChromeGlassModeStorage.defaultRawValue

  func body(content: Content) -> some View {
    let c = theme.colors
    let mode = ChromeGlassModeStorage.mode(from: chromeGlassModeRaw)
    let showQuiet = mode == .quiet || mode == .frosted
    // Temas claros: borda sempre — pills somem no fundo sem contorno.
    let showLightEdge = !c.isDark
    content.overlay {
      if showQuiet || showLightEdge {
        Capsule()
          .strokeBorder(
            c.isDark
              ? c.textPrimary.opacity(LiquidGlass.navSelectionStrokeOpacity)
              : Color.black.opacity(0.12),
            lineWidth: c.isDark ? LiquidGlass.navSelectionStrokeWidth : 1
          )
      }
    }
  }
}

private struct HomeHeaderIconButton: View {
  @Environment(ThemeManager.self) private var theme
  let icon: StackedIconKey
  let label: String
  var showsDot = false
  let action: () -> Void

  var body: some View {
    let c = theme.colors
    Button(action: action) {
      StackedIcons.image(icon)
        .font(.system(size: AppLayout.headerIconSize, weight: .medium))
        .foregroundStyle(c.textSecondary)
        .overlay(alignment: .topTrailing) {
          if showsDot {
            Circle()
              .fill(c.accent)
              .frame(width: 6, height: 6)
              .offset(x: 3.5, y: -1)
          }
        }
        .frame(width: AppLayout.headerControlSize, height: AppLayout.headerControlSize)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
    .accessibilityValue(showsDot ? "Lembretes agendados para as próximas horas" : "")
  }
}
