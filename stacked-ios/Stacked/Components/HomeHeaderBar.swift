import SwiftUI

/// Header na toolbar nativa — pré-estabelece a navbar para push fluido sem padding extra na lista.
struct HomeHeaderToolbar: ToolbarContent {
  @Binding var showProductivity: Bool
  @Binding var showProfile: Bool
  @Binding var showNotifications: Bool
  @Binding var showSettings: Bool
  @Binding var showSearch: Bool
  @AppStorage(HomeHeaderStyleStorage.key) private var headerStyleRaw = HomeHeaderStyleStorage.defaultRawValue
  @AppStorage(HomeTopCardStorage.key) private var topCardEnabled = HomeTopCardStorage.defaultEnabled

  private var style: HomeHeaderStyle {
    HomeHeaderStyleStorage.resolved(rawValue: headerStyleRaw, topCardEnabled: topCardEnabled)
  }

  var body: some ToolbarContent {
    ToolbarItem(id: "stacked-home-leading", placement: .topBarLeading) {
      HomeHeaderLeading(
        style: style,
        showProductivity: $showProductivity,
        showProfile: $showProfile
      )
    }
    .sharedBackgroundVisibility(.hidden)

    ToolbarItem(id: "stacked-home-principal", placement: .principal) {
      if style == .search {
        HomeHeaderSearchField(showSearch: $showSearch)
      }
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
  let style: HomeHeaderStyle
  @Binding var showProductivity: Bool
  @Binding var showProfile: Bool
  @AppStorage(HomeTopCardStorage.key) private var topCardEnabled = HomeTopCardStorage.defaultEnabled
  @AppStorage(AppTypeScaleStorage.key) private var typeScaleRaw = AppTypeScaleStorage.defaultRawValue
  @AppStorage(HomeDailyGoalStorage.key) private var dailyGoalStored = HomeDailyGoalStorage.defaultGoal

  /// Sem o card de saudação o nome não aparece em lugar nenhum da Home — a pill assume ele.
  private var pillName: String {
    guard !topCardEnabled else { return "" }
    return Self.clipped(store.firstName, at: 14)
  }

  private var dailyGoal: Int {
    HomeDailyGoalStorage.goal(from: dailyGoalStored)
  }

  /// Quanto da meta do dia já foi cumprido. Passar da meta mantém o anel cheio.
  private var dayProgress: Double {
    min(1, Double(store.completedToday) / Double(max(1, dailyGoal)))
  }

  private var dayFraction: String {
    "\(store.completedToday)/\(dailyGoal)"
  }

  private var greetingLine: String {
    Self.clipped(store.greeting, at: 22)
  }

  private var metaLine: String {
    let degree = store.weatherDegreeLabel
    let date = store.formattedMediumDate
    return degree.isEmpty ? date : "\(date) · \(degree)"
  }

  /// A toolbar propõe largura apertada; o maxWidth da pill + corte por caracteres
  /// / minimumScaleFactor impedem a saudação de engolir sino e config.
  private static func clipped(_ text: String, at limit: Int) -> String {
    guard text.count > limit else { return text }
    return String(text.prefix(limit - 1)) + "…"
  }

  var body: some View {
    let c = theme.colors
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
          avatar(c)
          trailingContent(c)
        }
        // Largura intrínseca, mas limitada — texto não some nem engole o trailing.
        .fixedSize(horizontal: true, vertical: false)
      }
      .modifier(HomeHeaderQuietBorder())
      .overlay {
        if style.showsProgressRing, dayProgress >= 1 {
          Capsule()
            .strokeBorder(c.accent.opacity(0.35), lineWidth: 1)
        }
      }
    }
    .frame(maxWidth: HomeHeaderMetrics.leadingPillMaxWidth, alignment: .leading)
    .clipped()
    .buttonStyle(PressableStyle(cornerRadius: AppLayout.headerControlSize / 2))
    .accessibilityLabel(topCardEnabled ? "Relatório de produtividade" : "Perfil")
    .accessibilityValue(accessibilityValue)
  }

  private var goalMet: Bool { dayProgress >= 1 }

  private var accessibilityValue: String {
    guard style.showsProgressRing else { return "" }
    if goalMet {
      return "Meta diária concluída · \(store.completedToday) de \(dailyGoal)"
    }
    return "\(store.completedToday) de \(dailyGoal) concluídas hoje"
  }

  private func avatar(_ c: AppThemeColors) -> some View {
    UserAvatarView(
      url: store.avatarURL,
      initials: store.avatarInitials,
      size: AppLayout.headerAvatarSize
    )
    .frame(width: AppLayout.headerControlSize, height: AppLayout.headerControlSize)
    .overlay {
      if style.showsProgressRing {
        HomeHeaderProgressRing(progress: dayProgress, colors: c)
      }
    }
    // Check da meta no avatar — não disputa largura com a saudação (que
    // antes sumia ou engolia sino/config quando o check ia inline).
    .overlay(alignment: .bottomTrailing) {
      if style.showsProgressRing, goalMet {
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(c.accent)
          .background(Circle().fill(c.navBar).padding(-1))
          .offset(x: 1, y: 1)
          .accessibilityHidden(true)
      }
    }
  }

  @ViewBuilder
  private func trailingContent(_ c: AppThemeColors) -> some View {
    let t = AppTypeScaleStorage.scale(from: typeScaleRaw).metrics

    switch style {
    case .search:
      EmptyView()

    case .classic:
      if !pillName.isEmpty {
        Text(pillName)
          .font(t.rowTitleFont)
          .foregroundStyle(c.textPrimary)
          .lineLimit(1)
          .fixedSize(horizontal: true, vertical: false)
          .padding(.trailing, 16)
      }

    case .progressRing:
      if !pillName.isEmpty {
        HStack(spacing: 7) {
          Text(pillName)
            .font(t.rowTitleFont)
            .foregroundStyle(c.textPrimary)
            .lineLimit(1)
          Text(dayFraction)
            .font(.system(size: 13.5, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(goalMet ? c.accent : c.textTertiary)
        }
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
        .padding(.trailing, 16)
      }

    case .greeting:
      VStack(alignment: .leading, spacing: 1) {
        Text(greetingLine)
          .font(.system(size: 15.5, weight: .semibold))
          .foregroundStyle(c.textPrimary)
        Text(metaLine)
          .font(.system(size: 11.5))
          .foregroundStyle(c.textTertiary)
      }
      .lineLimit(1)
      .fixedSize(horizontal: true, vertical: false)
      .padding(.trailing, 16)
    }
  }
}

/// Anel de progresso do dia em volta do avatar.
private struct HomeHeaderProgressRing: View {
  let progress: Double
  let colors: AppThemeColors

  private var complete: Bool { progress >= 1 }

  var body: some View {
    ZStack {
      Circle()
        .strokeBorder(colors.textPrimary.opacity(complete ? 0.08 : 0.13), lineWidth: 2.5)
      Circle()
        .trim(from: 0, to: max(0.02, min(1, progress)))
        .stroke(colors.accent, style: StrokeStyle(lineWidth: complete ? 3 : 2.5, lineCap: .round))
        .rotationEffect(.degrees(-90))
        .padding(1.25)
      if complete {
        Circle()
          .strokeBorder(colors.accent.opacity(0.22), lineWidth: 4)
          .padding(-1.5)
          .blur(radius: 0.2)
      }
    }
    .padding(1)
    .allowsHitTesting(false)
  }
}

/// Campo de busca no vão entre as pills. Largura fixa: dentro da toolbar não há
/// proposta de largura para expandir contra.
private struct HomeHeaderSearchField: View {
  @Environment(ThemeManager.self) private var theme
  @Binding var showSearch: Bool

  var body: some View {
    let c = theme.colors
    Button {
      HapticService.selection()
      showSearch = true
    } label: {
      LiquidGlass.headerPill(navBarColor: c.navBar, textPrimary: c.textPrimary) {
        HStack(spacing: 8) {
          StackedIcons.image(.search)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(c.textSecondary)
          Text("Buscar")
            .font(.system(size: 15))
            .foregroundStyle(c.textTertiary)
            .lineLimit(1)
          Spacer(minLength: 0)
        }
        .padding(.horizontal, 15)
        .frame(
          width: HomeHeaderMetrics.searchFieldWidth,
          height: AppLayout.headerControlSize
        )
      }
      .modifier(HomeHeaderQuietBorder())
    }
    .buttonStyle(PressableStyle(cornerRadius: AppLayout.headerControlSize / 2))
    .accessibilityLabel("Buscar")
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
    // Prioridade alta: nunca cede espaço pra pill da saudação engolir o trailing.
    .layoutPriority(1)
    .fixedSize(horizontal: true, vertical: false)
  }
}

/// Contorno igual ao trilho do dock — Fosco (sem Liquid Glass ao vivo).
private struct HomeHeaderQuietBorder: ViewModifier {
  @Environment(ThemeManager.self) private var theme
  @AppStorage(ChromeGlassModeStorage.key) private var chromeGlassModeRaw = ChromeGlassModeStorage.defaultRawValue

  func body(content: Content) -> some View {
    let c = theme.colors
    let showFrosted = ChromeGlassModeStorage.mode(from: chromeGlassModeRaw) == .frosted
    // Temas claros: borda sempre — pills somem no fundo sem contorno.
    let showLightEdge = !c.isDark
    content.overlay {
      if showFrosted || showLightEdge {
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
