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

/// Placeholder de linha de tarefa — altura fixa para evitar content jump no push.
struct TaskRowSkeleton: View {
  @Environment(ThemeManager.self) private var theme

  var body: some View {
    let c = theme.colors
    HStack(spacing: 12) {
      Circle()
        .fill(c.surfaceVariant.opacity(0.7))
        .frame(width: 20, height: 20)
      RoundedRectangle(cornerRadius: 4)
        .fill(c.surfaceVariant.opacity(0.5))
        .frame(height: 14)
      Spacer(minLength: 0)
    }
    .frame(height: AppLayout.taskRowHeight)
    .padding(.horizontal, 4)
    .redacted(reason: .placeholder)
  }
}

struct TaskListSkeleton: View {
  let rowCount: Int
  private let rowInsets = EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)

  var body: some View {
    Section {
      ForEach(0..<rowCount, id: \.self) { _ in
        TaskRowSkeleton()
          .listRowInsets(rowInsets)
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }
    }
  }
}

/// Section label para headers de `List` (sem padding extra).
struct ListSectionHeader: View {
  @Environment(ThemeManager.self) private var theme
  @AppStorage(AppTypeScaleStorage.key) private var typeScaleRaw = AppTypeScaleStorage.defaultRawValue
  let text: String

  var body: some View {
    let t = AppTypeScaleStorage.scale(from: typeScaleRaw).metrics
    Text(t.headerCase.apply(to: text))
      .font(t.headerFont)
      .foregroundStyle(t.headerUsesPrimaryColor ? theme.colors.textPrimary : theme.colors.textSecondary)
      .tracking(t.headerTracking)
      .textCase(nil)
      .padding(.leading, AppSpacing.xs)
  }
}

/// Section header com ação à direita — mesmo alinhamento que `ListSectionHeader`.
struct ListSectionHeaderWithTrailing<Trailing: View>: View {
  @Environment(ThemeManager.self) private var theme
  @AppStorage(AppTypeScaleStorage.key) private var typeScaleRaw = AppTypeScaleStorage.defaultRawValue
  let text: String
  @ViewBuilder var trailing: () -> Trailing

  var body: some View {
    let t = AppTypeScaleStorage.scale(from: typeScaleRaw).metrics
    HStack(alignment: .center, spacing: 8) {
      Text(t.headerCase.apply(to: text))
        .font(t.headerFont)
        .foregroundStyle(t.headerUsesPrimaryColor ? theme.colors.textPrimary : theme.colors.textSecondary)
        .tracking(t.headerTracking)
        .textCase(nil)
      Spacer(minLength: 0)
      trailing()
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

// MARK: - Toolbar pills (Fosco) vs glass nativo (Ao vivo)

/// Texto na toolbar (Fechar / Salvar / Ordenar).
/// Fosco: pill estática com label completo. Ao vivo: botão glass nativo.
struct StackedToolbarTextButton: View {
  @Environment(ThemeManager.self) private var theme
  @AppStorage(ChromeGlassModeStorage.key) private var chromeGlassModeRaw = ChromeGlassModeStorage.defaultRawValue

  let title: String
  var accent: Bool = false
  var enabled: Bool = true
  let action: () -> Void

  private var useStaticPill: Bool {
    GlassChromePreference.prefersStaticToolbarPills(
      mode: ChromeGlassModeStorage.mode(from: chromeGlassModeRaw)
    )
  }

  var body: some View {
    let c = theme.colors
    let labelColor = accent ? c.accent : c.textPrimary
    if useStaticPill {
      Button(action: action) {
        // Capsule própria (não LiquidGlass.toolbarPill): a toolbar iOS 26
        // espremia cancellationAction e "Fechar" virava "F" numa bolha.
        Text(title)
          .font(AppTypography.body)
          .foregroundStyle(labelColor)
          .lineLimit(1)
          .fixedSize(horizontal: true, vertical: false)
          .padding(.horizontal, 14)
          .padding(.vertical, 7)
          .background {
            LiquidGlass.frostedFill(
              shape: Capsule(),
              tint: c.isDark ? c.surfaceVariant : c.surface
            )
          }
      }
      .buttonStyle(PressableStyle(cornerRadius: 20))
      .disabled(!enabled)
      .fixedSize(horizontal: true, vertical: false)
    } else {
      Button(title, action: action)
        .font(AppTypography.body)
        .foregroundStyle(labelColor)
        .disabled(!enabled)
    }
  }
}

/// Ícone na toolbar — mesmo split Fosco/Ao vivo que `StackedToolbarTextButton`.
struct StackedToolbarIconButton: View {
  @Environment(ThemeManager.self) private var theme
  @AppStorage(ChromeGlassModeStorage.key) private var chromeGlassModeRaw = ChromeGlassModeStorage.defaultRawValue

  let icon: StackedIconKey
  var accessibilityLabel: String
  var accent: Bool = false
  let action: () -> Void

  private var useStaticPill: Bool {
    GlassChromePreference.prefersStaticToolbarPills(
      mode: ChromeGlassModeStorage.mode(from: chromeGlassModeRaw)
    )
  }

  var body: some View {
    let c = theme.colors
    let tint = accent ? c.accent : c.textPrimary
    if useStaticPill {
      Button(action: action) {
        LiquidGlass.toolbarPill(navBarColor: c.surfaceVariant, textPrimary: c.textPrimary) {
          StackedIcons.image(icon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(tint)
        }
      }
      .buttonStyle(PressableStyle(cornerRadius: 20))
      .accessibilityLabel(accessibilityLabel)
    } else {
      Button(action: action) {
        StackedIcons.image(icon)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(tint)
      }
      .accessibilityLabel(accessibilityLabel)
    }
  }
}

extension ToolbarContent {
  /// No Fosco isola o item do morph glass compartilhado; no Ao vivo deixa o sistema cuidar.
  @ToolbarContentBuilder
  func stackedToolbarGlassIsolation(_ isolate: Bool) -> some ToolbarContent {
    if isolate {
      self.sharedBackgroundVisibility(.hidden)
    } else {
      self
    }
  }
}

// MARK: - Form / editor sheets (handle + presentation)

struct SheetDragHandle: View {
  @Environment(ThemeManager.self) private var theme

  var body: some View {
    Capsule()
      .fill(theme.colors.textTertiary.opacity(0.35))
      .frame(width: 36, height: 4)
      .padding(.top, 10)
      .padding(.bottom, 6)
      .frame(maxWidth: .infinity)
      .accessibilityHidden(true)
  }
}

extension View {
  /// Fundo sólido, cantos arredondados e handle próprio (esconde o indicador nativo duplicado).
  func stackedEditableSheetPresentation(background: Color) -> some View {
    presentationDragIndicator(.hidden)
      .presentationBackground(background)
      .presentationCornerRadius(20)
  }
}

// MARK: - Settings drill-down (paridade appearance_screen / labels_screen)

enum SettingsChrome {
  static let horizontalPadding: CGFloat = 16
  static let cardCornerRadius: CGFloat = 14
  static let rowPaddingH: CGFloat = 14
  static let rowPaddingV: CGFloat = 12
}

/// Toggle nativo (.switch) — padrão dos ajustes (ex.: FAB integrado na ilha).
struct SettingsSwitchToggle: View {
  @Binding var isOn: Bool
  let tint: Color

  var body: some View {
    Toggle("", isOn: $isOn)
      .labelsHidden()
      .toggleStyle(.switch)
      .tint(tint)
  }
}

struct SettingsSectionHeader: View {
  @Environment(ThemeManager.self) private var theme
  let text: String

  var body: some View {
    Text(text.uppercased())
      .font(AppTypography.sectionLabel)
      .foregroundStyle(theme.colors.textSecondary)
      .tracking(0.2)
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
    // Sem GeometryReader envolvendo o List — consulta pontual da largura da janela.
    let screenWidth = ScreenMetrics.bounds.width
    let maxContentWidth: CGFloat = screenWidth >= AppLayout.breakpointPhone
      ? AppLayout.tabletContentMaxWidth(screenWidth: screenWidth)
      : .infinity

    content
      .frame(maxWidth: maxContentWidth)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }
}

extension View {
  /// Centraliza conteúdo em tablet (≥600pt) com max-width 640/720.
  func stackedTabletCentered() -> some View {
    modifier(StackedTabletCenteredModifier())
  }

  /// Toolbar + título inline no drill-down — sem fundo sólido (iOS 26 glass + scroll edge nativos).
  func stackedDrillDownNavChrome(title: String, background _: Color) -> some View {
    navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar(.visible, for: .navigationBar)
      .toolbarBackground(.hidden, for: .navigationBar)
  }

  /// Esconde o voltar nativo — use com `DrillDownBackToolbarItem` na toolbar.
  func stackedDrillDownGlassBackButton() -> some View {
    navigationBarBackButtonHidden(true)
      .background(InteractivePopGestureEnabler())
  }

  /// SEMPRE volta custom (pill) — nos 4 modos, inclusive Ao vivo.
  /// BUG_GHOST_VOLTAR: em Ao vivo, o voltar nativo (UIKit) e o leading item da
  /// Home (avatar) dividem o mesmo slot `.topBarLeading`; o sistema aplica um
  /// "materialize"/morph de glass automático no botão voltar nativo assim que
  /// a tela assenta, que ainda brilha sozinho (sem toque) uns ~300ms depois
  /// do push — some só ao voltar. O pill custom (`ToolbarGlassPill`) já usa
  /// `.glassEffect` real em Ao vivo, mas por fora da máquina nativa de morph
  /// do botão voltar, então não herda esse artefato.
  func stackedAdaptiveDrillDownBack() -> some View {
    modifier(StackedAdaptiveDrillDownBackModifier())
  }
}

private struct StackedAdaptiveDrillDownBackModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .stackedDrillDownGlassBackButton()
      .toolbar { DrillDownBackToolbarItem() }
  }
}

// SUBSTITUIDO_BUG_GHOST_VOLTAR — gating por modo (Fosco: pill custom; Ao vivo:
// nativo com morph glass). Nativo em Ao vivo tinha o glow espontâneo:
//
// private struct StackedAdaptiveDrillDownBackModifier: ViewModifier {
//   @AppStorage(ChromeGlassModeStorage.key) private var chromeGlassModeRaw = ChromeGlassModeStorage.defaultRawValue
//   private var useStaticPill: Bool {
//     GlassChromePreference.prefersStaticToolbarPills(mode: ChromeGlassModeStorage.mode(from: chromeGlassModeRaw))
//   }
//   func body(content: Content) -> some View {
//     if useStaticPill {
//       content.stackedDrillDownGlassBackButton().toolbar { DrillDownBackToolbarItem() }
//     } else {
//       content
//     }
//   }
// }

// MARK: - Drill-down toolbar (glass back — padrão projeto/filtros)

struct DrillDownGlassIconButton: View {
  @Environment(ThemeManager.self) private var theme
  let icon: StackedIconKey
  var accessibilityLabel: String = "Voltar"
  let action: () -> Void

  var body: some View {
    let c = theme.colors
    Button(action: action) {
      LiquidGlass.toolbarPill(navBarColor: c.surfaceVariant, textPrimary: c.textPrimary) {
        StackedIcons.image(icon)
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(c.textPrimary)
      }
    }
    .buttonStyle(PressableStyle(cornerRadius: 20))
    .accessibilityLabel(accessibilityLabel)
  }
}

/// Slots vazios de navbar numa tela-raiz que não mostra nada na barra.
///
/// BUG_TREMIDA_PUSH: saindo de uma barra sem nenhum item, o push tem que
/// materializar leading/principal/trailing do drill-down do zero e os itens
/// entram em passos irregulares (~30fps) enquanto o conteúdo da tela desliza
/// liso a 60fps. Com os slots já existindo na origem, a barra só translada o
/// que já está montado. É o mesmo motivo do `HomeHeaderToolbar` ("pré-estabelece
/// a navbar para push fluido") — lá os itens são reais, aqui são invisíveis.
struct StackedNavBarPrimerToolbar: ToolbarContent {
  var body: some ToolbarContent {
    ToolbarItem(id: "stacked-navbar-primer-leading", placement: .topBarLeading) {
      NavBarPrimerSlot()
    }
    .sharedBackgroundVisibility(.hidden)

    ToolbarItem(id: "stacked-navbar-primer-principal", placement: .principal) {
      NavBarPrimerSlot()
    }
    .sharedBackgroundVisibility(.hidden)

    ToolbarItem(id: "stacked-navbar-primer-trailing", placement: .topBarTrailing) {
      NavBarPrimerSlot()
    }
    .sharedBackgroundVisibility(.hidden)
  }
}

private struct NavBarPrimerSlot: View {
  /// Altura do pill de drill-down (ícone 16pt + 7pt de padding vertical). Abaixo
  /// dos 44pt da barra inline, então priming não muda a altura da navbar.
  private static let pillHeight: CGFloat = 34

  var body: some View {
    Color.clear
      .frame(width: 1, height: Self.pillHeight)
      .accessibilityHidden(true)
  }
}

struct DrillDownBackToolbarItem: ToolbarContent {
  @Environment(\.dismiss) private var dismiss

  var body: some ToolbarContent {
    ToolbarItem(id: "stacked-drilldown-back", placement: .topBarLeading) {
      DrillDownGlassIconButton(icon: .arrowLeft) {
        dismiss()
      }
    }
    .sharedBackgroundVisibility(.hidden)
  }
}

/// Título de drill-down com tipografia do projeto (bold + tracking).
/// Pareie com slots leading/trailing de **mesma largura** — aí o `.principal`
/// do UIKit cai no centro do vão, sem offset óptico (que o anti-colisão
/// remarcaria e cortava títulos longos tipo “Financeiro”).
struct DrillDownProjectNavTitle: View {
  let title: String
  var textColor: Color
  var maxWidth: CGFloat = .infinity

  var body: some View {
    Text(title)
      .font(.system(size: 17, weight: .bold))
      .tracking(-0.3)
      .foregroundStyle(textColor)
      .lineLimit(1)
      .minimumScaleFactor(0.78)
      .frame(maxWidth: maxWidth)
      .accessibilityAddTraits(.isHeader)
  }
}
