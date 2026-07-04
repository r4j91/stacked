import SwiftUI

// Fase C — chrome unificado: headers, section labels, drill-down, dismiss de modais.
enum ScreenHeaderMetrics {
  static let horizontalPadding: CGFloat = 20
  static let topPadding: CGFloat = 20
  static let bottomPadding: CGFloat = 8
}

struct ScreenHeaderChrome<Trailing: View>: View {
  @Environment(ThemeManager.self) private var theme
  let title: String
  var subtitle: String?
  @ViewBuilder var trailing: () -> Trailing

  var body: some View {
    let c = theme.colors

    HStack(alignment: .top, spacing: 8) {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(AppTypography.screenTitle)
          .foregroundStyle(c.textPrimary)
          .tracking(-0.5)
        if let subtitle {
          Text(subtitle)
            .font(AppTypography.screenSubtitle)
            .foregroundStyle(c.textSecondary)
        }
      }

      Spacer(minLength: 0)
      trailing()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, ScreenHeaderMetrics.horizontalPadding)
    .padding(.top, ScreenHeaderMetrics.topPadding)
    .padding(.bottom, ScreenHeaderMetrics.bottomPadding)
  }
}

/// Section label para headers de `List` (sem padding extra).
struct ListSectionHeader: View {
  @Environment(ThemeManager.self) private var theme
  let text: String

  var body: some View {
    Text(text)
      .font(AppTypography.sectionLabel)
      .foregroundStyle(theme.colors.textTertiary)
      .tracking(0.6)
  }
}

/// Header do drill-down em Filtros (voltar + título colorido).
struct FilterDrillDownHeader: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let title: String
  let taskCount: Int
  let tint: Color
  let onBack: () -> Void

  var body: some View {
    let c = theme.colors
    let subtitle = "\(taskCount) \(taskCount == 1 ? "tarefa" : "tarefas")"

    HStack(spacing: 12) {
      Button {
        HapticService.selection()
        AppMotion.animate(AppMotion.smooth, reduceMotion: reduceMotion, onBack)
      } label: {
        Image(systemName: "chevron.left")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(c.textSecondary)
          .frame(width: 44, height: 44)
          .background(c.surfaceVariant)
          .clipShape(RoundedRectangle(cornerRadius: 10))
      }
      .buttonStyle(.plain)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(AppTypography.drillDownTitle)
          .foregroundStyle(tint)
        Text(subtitle)
          .font(AppTypography.screenSubtitle)
          .foregroundStyle(c.textSecondary)
      }

      Spacer(minLength: 0)
    }
  }
}

enum ModalChrome {
  /// Sheets de criação/edição — barra nativa.
  static func cancelToolbar(dismiss: DismissAction) -> some ToolbarContent {
    ToolbarItem(placement: .cancellationAction) {
      Button("Cancelar", action: { dismiss() })
    }
  }

  /// Sheets informativos (settings, relatórios) — texto no canto.
  static func closeTextButton(dismiss: DismissAction, accent: Color) -> some View {
    Button("Fechar", action: { dismiss() })
      .font(AppTypography.bodySemibold)
      .foregroundStyle(accent)
  }
}

// MARK: - Settings drill-down (paridade appearance_screen / labels_screen)

enum SettingsChrome {
  static let horizontalPadding: CGFloat = 16
  static let cardCornerRadius: CGFloat = 14
  static let rowPaddingH: CGFloat = 14
  static let rowPaddingV: CGFloat = 12
}

struct SettingsSectionHeader: View {
  @Environment(ThemeManager.self) private var theme
  let text: String

  var body: some View {
    Text(text.uppercased())
      .font(AppTypography.sectionLabel)
      .foregroundStyle(theme.colors.textTertiary)
      .tracking(0.6)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.leading, 4)
  }
}

struct SettingsCardSurface<Content: View>: View {
  @Environment(ThemeManager.self) private var theme
  @ViewBuilder let content: () -> Content

  var body: some View {
    let c = theme.colors
    content()
      .background(c.surfaceVariant)
      .clipShape(RoundedRectangle(cornerRadius: SettingsChrome.cardCornerRadius))
  }
}

struct SettingsCardDivider: View {
  @Environment(ThemeManager.self) private var theme
  var leadingPadding: CGFloat = 52

  var body: some View {
    Divider()
      .overlay(theme.colors.surface)
      .padding(.leading, leadingPadding)
  }
}

/// Posição da linha num card agrupado — NavigationLink precisa ser filho direto da List.
enum SettingsCardRowPosition {
  case only, first, middle, last
}

private struct SettingsGroupedRowBackground: View {
  @Environment(ThemeManager.self) private var theme
  let position: SettingsCardRowPosition

  var body: some View {
    let c = theme.colors
    let r = SettingsChrome.cardCornerRadius
    switch position {
    case .only:
      RoundedRectangle(cornerRadius: r).fill(c.surfaceVariant)
    case .first:
      UnevenRoundedRectangle(
        topLeadingRadius: r, bottomLeadingRadius: 0,
        bottomTrailingRadius: 0, topTrailingRadius: r
      )
      .fill(c.surfaceVariant)
    case .middle:
      Rectangle().fill(c.surfaceVariant)
    case .last:
      UnevenRoundedRectangle(
        topLeadingRadius: 0, bottomLeadingRadius: r,
        bottomTrailingRadius: r, topTrailingRadius: 0
      )
      .fill(c.surfaceVariant)
    }
  }
}

extension View {
  /// Lista de drill-down em Configurações — fundo escuro, margem horizontal uniforme.
  func settingsDrillDownList(background: Color) -> some View {
    self
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      .background(background)
      .contentMargins(.horizontal, SettingsChrome.horizontalPadding, for: .scrollContent)
  }

  func settingsListCardRow(
    top: CGFloat = 4,
    bottom: CGFloat = 4
  ) -> some View {
    self
      .listRowInsets(
        EdgeInsets(
          top: top,
          leading: 0,
          bottom: bottom,
          trailing: 0
        )
      )
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
  }

  /// NavigationLink como linha direta da List, visual de card agrupado.
  func settingsGroupedNavigationRow(
    position: SettingsCardRowPosition,
    showDivider: Bool = false,
    dividerLeading: CGFloat = 52
  ) -> some View {
    self
      .listRowInsets(
        EdgeInsets(
          top: position == .first || position == .only ? 4 : 0,
          leading: 0,
          bottom: position == .last || position == .only ? 4 : 0,
          trailing: 0
        )
      )
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
      .overlay(alignment: .bottom) {
        if showDivider {
          SettingsCardDivider(leadingPadding: dividerLeading)
        }
      }
  }
}

private struct StackedTabletCenteredModifier: ViewModifier {
  func body(content: Content) -> some View {
    GeometryReader { geo in
      let isTablet = geo.size.width >= AppLayout.breakpointPhone
      let contentWidth = isTablet
        ? AppLayout.tabletContentMaxWidth(screenWidth: geo.size.width)
        : geo.size.width

      content
        .frame(width: contentWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
  }
}

extension View {
  /// Centraliza conteúdo em tablet (≥600pt) com max-width 640/720.
  func stackedTabletCentered() -> some View {
    modifier(StackedTabletCenteredModifier())
  }
}
