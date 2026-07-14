import SwiftUI

// Paridade lib/screens/appearance_screen.dart — seções colapsáveis (menos densidade no scroll).
struct AppearanceView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var iconManager = AppIconManager.shared
  @State private var iconErrorMessage: String?
  @AppStorage(NavBarStyleStorage.key) private var navBarStyleRaw = NavBarStyleStorage.defaultRawValue
  @AppStorage(HomeHeroStyleStorage.key) private var homeHeroStyleRaw = HomeHeroStyleStorage.defaultRawValue
  @AppStorage(HomeHeroStyleStorage.hiddenKey) private var homeHeroStyleHiddenRaw = ""
  @AppStorage(FabIntegratedInIslandStorage.key) private var fabIntegratedInIsland = false
  @AppStorage(FreezeDockGlassWhileScrollingStorage.key) private var freezeDockGlassWhileScrolling = true
  @AppStorage(AlwaysFrozenDockGlassStorage.key) private var alwaysFrozenDockGlass = false
  @State private var stylePendingHide: HomeHeroStyle?
  /// Uma seção aberta por vez — accordion leve no padrão do app.
  @State private var expandedSection: AppearanceSectionID? = .theme

  private var navBarStyle: NavBarStyle {
    NavBarStyleStorage.style(from: navBarStyleRaw)
  }

  private var isIslandNavStyle: Bool {
    navBarStyle == .island
  }

  private var homeHeroStyle: HomeHeroStyle {
    HomeHeroStyleStorage.style(from: homeHeroStyleRaw)
  }

  var body: some View {
    let c = theme.colors
    let themes = AppThemeId.allCases
    let icons = AppIconId.allCases
    let navStyles = NavBarStyle.allCases
    let heroGroups = HomeHeroStyleGroup.allCases
    let hiddenStyles = HomeHeroStyleStorage.hiddenStyles()

    // ScrollView (não List): accordion custom + List brigam no resize das rows.
    ScrollView {
      VStack(spacing: 8) {
        appearancePanel(
          id: .theme,
          title: "Tema",
          summary: theme.currentId.displayName,
          footer: nil
        ) {
          ForEach(Array(themes.enumerated()), id: \.element) { index, themeId in
            themeRow(themeId)
            if index < themes.count - 1 {
              SettingsCardDivider(leadingPadding: 56)
            }
          }
        }

        appearancePanel(
          id: .navBar,
          title: "Barra de navegação",
          summary: navBarStyle.displayName,
          footer: isIslandNavStyle
            ? nil
            : "FAB integrado na ilha está disponível apenas com a navbar em Ilha."
        ) {
          ForEach(Array(navStyles.enumerated()), id: \.element) { index, style in
            navBarStyleRow(style)
            if index < navStyles.count - 1 {
              SettingsCardDivider(leadingPadding: 56)
            }
          }
          SettingsCardDivider(leadingPadding: 56)
          fabIntegratedInIslandRow()
        }

        appearancePanel(
          id: .scrollFluidity,
          title: "Fluidez do scroll",
          summary: alwaysFrozenDockGlass
            ? "Navbar sem glass"
            : (freezeDockGlassWhileScrolling ? "Glass pausado no scroll" : "Glass sempre ao vivo"),
          footer: alwaysFrozenDockGlass
            ? "Com “Navbar sem glass” ligada, o dock fica no fill estático o tempo todo — bom para comparar o visual. Desligue para voltar ao Liquid Glass."
            : "Recomendado: pausar no scroll. Parado = Liquid Glass; ao rolar = fill estático. “Navbar sem glass” remove o vidro ao vivo por completo."
        ) {
          freezeDockGlassRow()
          SettingsCardDivider(leadingPadding: 56)
          alwaysFrozenDockGlassRow()
        }

        appearancePanel(
          id: .homeHero,
          title: "Hero da Home",
          summary: homeHeroStyle.displayName,
          footer: "Em cada estilo, use o menu ⋯ para excluir só aquele card."
        ) {
          ForEach(Array(heroGroups.enumerated()), id: \.element) { groupIndex, group in
            let styles = HomeHeroStyle.styles(in: group)
            if !styles.isEmpty {
              if group != .recommended {
                Text(group.displayName)
                  .font(AppTypography.metaSmall.weight(.semibold))
                  .foregroundStyle(c.textTertiary)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding(.horizontal, SettingsChrome.rowPaddingH)
                  .padding(.top, groupIndex == 0 ? 4 : 12)
                  .padding(.bottom, 4)
              }
              ForEach(Array(styles.enumerated()), id: \.element) { index, style in
                homeHeroStyleRow(style)
                if index < styles.count - 1 {
                  SettingsCardDivider(leadingPadding: 56)
                }
              }
              if groupIndex < heroGroups.count - 1 {
                SettingsCardDivider(leadingPadding: 16)
              }
            }
          }
        }

        if !hiddenStyles.isEmpty {
          appearancePanel(
            id: .hiddenHeroes,
            title: "Estilos ocultos",
            summary: "\(hiddenStyles.count)",
            footer: "Restaure um estilo para ele voltar ao menu de cards."
          ) {
            ForEach(Array(hiddenStyles.enumerated()), id: \.element) { index, style in
              hiddenHeroStyleRow(style)
              if index < hiddenStyles.count - 1 {
                SettingsCardDivider(leadingPadding: 16)
              }
            }
          }
        }

        if iconManager.isSupported {
          appearancePanel(
            id: .appIcon,
            title: "Ícone do app",
            summary: iconManager.currentId.displayName,
            footer: "O iOS pede confirmação ao trocar o ícone na tela de início."
          ) {
            ForEach(Array(icons.enumerated()), id: \.element) { index, iconId in
              iconRow(iconId)
              if index < icons.count - 1 {
                SettingsCardDivider(leadingPadding: 56)
              }
            }
          }
        }
      }
      .padding(.horizontal, SettingsChrome.horizontalPadding)
      .padding(.top, 8)
      .padding(.bottom, 28)
    }
    .scrollIndicators(.hidden)
    .background(c.background)
    .navigationTitle("Aparência")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear { iconManager.syncFromSystem() }
    .alert(
      "Excluir este estilo?",
      isPresented: Binding(
        get: { stylePendingHide != nil },
        set: { if !$0 { stylePendingHide = nil } }
      ),
      presenting: stylePendingHide
    ) { style in
      Button("Excluir \"\(style.displayName)\"", role: .destructive) {
        hideHeroStyle(style)
      }
      Button("Cancelar", role: .cancel) {
        stylePendingHide = nil
      }
    } message: { style in
      Text("Só “\(style.displayName)” some do menu. Você pode restaurar depois em Estilos ocultos.")
    }
    .alert("Não foi possível trocar o ícone", isPresented: Binding(
      get: { iconErrorMessage != nil },
      set: { if !$0 { iconErrorMessage = nil } }
    )) {
      Button("OK", role: .cancel) { iconErrorMessage = nil }
    } message: {
      Text(iconErrorMessage ?? "")
    }
  }

  // MARK: - Accordion (ScrollView — animação de altura limpa)

  @ViewBuilder
  private func appearancePanel<Content: View>(
    id: AppearanceSectionID,
    title: String,
    summary: String,
    footer: String?,
    @ViewBuilder content: @escaping () -> Content
  ) -> some View {
    let expanded = expandedSection == id
    let c = theme.colors

    SettingsCardSurface {
      VStack(spacing: 0) {
        AppearanceSectionHeader(
          icon: id.icon,
          title: title,
          summary: summary,
          expanded: expanded
        ) {
          HapticService.selection()
          AppMotion.animate(AppMotion.snappy, reduceMotion: reduceMotion) {
            if expanded {
              expandedSection = nil
            } else {
              expandedSection = id
            }
          }
        }

        if expanded {
          VStack(spacing: 0) {
            Rectangle()
              .fill(c.surface.opacity(0.85))
              .frame(height: 1)
              .padding(.horizontal, SettingsChrome.rowPaddingH)

            content()
              .padding(.bottom, 4)

            if let footer {
              Text(footer)
                .font(AppTypography.taskPreview)
                .foregroundStyle(c.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, SettingsChrome.rowPaddingH)
                .padding(.top, 4)
                .padding(.bottom, 12)
            }
          }
          .transition(.opacity.combined(with: .move(edge: .top)))
        }
      }
    }
  }

  // MARK: - Rows

  private func freezeDockGlassRow() -> some View {
    let c = theme.colors
    let dimmed = alwaysFrozenDockGlass

    return HStack(spacing: 14) {
      VStack(alignment: .leading, spacing: 3) {
        Text("Pausar glass no scroll")
          .font(AppTypography.settingsTitle)
          .foregroundStyle(dimmed ? c.textTertiary : c.textPrimary)
        Text("Congela o vidro do dock enquanto as listas rolam.")
          .font(AppTypography.taskPreview)
          .foregroundStyle(c.textSecondary)
      }
      Spacer(minLength: 8)
      SettingsSwitchToggle(isOn: $freezeDockGlassWhileScrolling, tint: c.accent)
        .disabled(dimmed)
    }
    .frame(minHeight: 44)
    .padding(.horizontal, SettingsChrome.rowPaddingH)
    .padding(.vertical, SettingsChrome.rowPaddingV)
    .opacity(dimmed ? 0.55 : 1)
    .onChange(of: freezeDockGlassWhileScrolling) { _, _ in
      HapticService.selection()
    }
  }

  private func alwaysFrozenDockGlassRow() -> some View {
    let c = theme.colors

    return HStack(spacing: 14) {
      VStack(alignment: .leading, spacing: 3) {
        Text("Navbar sem glass")
          .font(AppTypography.settingsTitle)
          .foregroundStyle(c.textPrimary)
        Text("Mantém o dock no estilo estático, sem Liquid Glass ao vivo.")
          .font(AppTypography.taskPreview)
          .foregroundStyle(c.textSecondary)
      }
      Spacer(minLength: 8)
      SettingsSwitchToggle(isOn: $alwaysFrozenDockGlass, tint: c.accent)
    }
    .frame(minHeight: 44)
    .padding(.horizontal, SettingsChrome.rowPaddingH)
    .padding(.vertical, SettingsChrome.rowPaddingV)
    .onChange(of: alwaysFrozenDockGlass) { _, _ in
      HapticService.selection()
    }
  }

  private func themeRow(_ themeId: AppThemeId) -> some View {
    let c = theme.colors

    return Button {
      HapticService.selection()
      theme.setTheme(themeId)
    } label: {
      HStack(spacing: 14) {
        themeSwatch(themeId)
        VStack(alignment: .leading, spacing: 3) {
          Text(themeId.displayName)
            .font(AppTypography.settingsTitle)
            .foregroundStyle(c.textPrimary)
          Text(themeId.subtitle)
            .font(AppTypography.taskPreview)
            .foregroundStyle(c.textSecondary)
        }
        Spacer()
        if theme.currentId == themeId {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(c.accent)
        }
      }
      .padding(.horizontal, SettingsChrome.rowPaddingH)
      .padding(.vertical, SettingsChrome.rowPaddingV)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  private func navBarStyleRow(_ style: NavBarStyle) -> some View {
    let c = theme.colors
    let isSelected = navBarStyle == style

    return Button {
      guard !isSelected else { return }
      HapticService.selection()
      navBarStyleRaw = style.rawValue
      MobileChromeController.shared.collapseIslandNav()
    } label: {
      HStack(spacing: 14) {
        NavBarStylePreview(style: style, colors: c, selected: isSelected)
        Text(style.displayName)
          .font(AppTypography.settingsTitle)
          .foregroundStyle(c.textPrimary)
        Spacer()
        if isSelected {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(c.accent)
        }
      }
      .frame(minHeight: 44)
      .padding(.horizontal, SettingsChrome.rowPaddingH)
      .padding(.vertical, SettingsChrome.rowPaddingV)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  private func fabIntegratedInIslandRow() -> some View {
    let c = theme.colors

    return HStack(spacing: 14) {
      FabIntegratedInIslandPreview(integrated: fabIntegratedInIsland, colors: c)
      VStack(alignment: .leading, spacing: 3) {
        Text("FAB integrado na ilha")
          .font(AppTypography.settingsTitle)
          .foregroundStyle(isIslandNavStyle ? c.textPrimary : c.textTertiary)
        Text("O botão + vira um segmento da pill em vez de flutuar acima dela.")
          .font(AppTypography.taskPreview)
          .foregroundStyle(c.textSecondary)
      }
      Spacer(minLength: 8)
      SettingsSwitchToggle(isOn: $fabIntegratedInIsland, tint: c.accent)
        .disabled(!isIslandNavStyle)
    }
    .frame(minHeight: 44)
    .padding(.horizontal, SettingsChrome.rowPaddingH)
    .padding(.vertical, SettingsChrome.rowPaddingV)
    .onChange(of: fabIntegratedInIsland) { _, enabled in
      if enabled {
        HapticService.selection()
      }
    }
  }

  private func homeHeroStyleRow(_ style: HomeHeroStyle) -> some View {
    let c = theme.colors
    let isSelected = homeHeroStyle == style

    return HStack(spacing: 0) {
      Button {
        guard !isSelected else { return }
        HapticService.selection()
        homeHeroStyleRaw = style.rawValue
      } label: {
        HStack(spacing: 14) {
          HomeHeroStylePreview(style: style, colors: c, selected: isSelected)
          VStack(alignment: .leading, spacing: 3) {
            Text(style.displayName)
              .font(AppTypography.settingsTitle)
              .foregroundStyle(c.textPrimary)
            Text(style.subtitle)
              .font(AppTypography.taskPreview)
              .foregroundStyle(c.textSecondary)
          }
          Spacer(minLength: 8)
          if isSelected {
            Image(systemName: "checkmark.circle.fill")
              .foregroundStyle(c.accent)
          }
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .contextMenu {
        if style.canHideFromPicker {
          Button("Excluir \"\(style.displayName)\"", role: .destructive) {
            stylePendingHide = style
          }
        }
      } preview: {
        homeHeroStyleContextPreview(style)
      }

      if style.canHideFromPicker {
        Menu {
          Button("Excluir \"\(style.displayName)\"", role: .destructive) {
            stylePendingHide = style
          }
        } label: {
          Image(systemName: "ellipsis.circle")
            .font(.system(size: 18, weight: .regular))
            .foregroundStyle(c.textTertiary)
            .frame(width: 36, height: 44)
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
      }
    }
    .padding(.horizontal, SettingsChrome.rowPaddingH)
    .padding(.vertical, SettingsChrome.rowPaddingV)
  }

  private func homeHeroStyleContextPreview(_ style: HomeHeroStyle) -> some View {
    let c = theme.colors
    return HStack(spacing: 12) {
      HomeHeroStylePreview(style: style, colors: c, selected: false)
      VStack(alignment: .leading, spacing: 3) {
        Text(style.displayName)
          .font(AppTypography.settingsTitle)
          .foregroundStyle(c.textPrimary)
        Text(style.subtitle)
          .font(AppTypography.taskPreview)
          .foregroundStyle(c.textSecondary)
          .lineLimit(2)
      }
      Spacer(minLength: 0)
    }
    .padding(14)
    .frame(width: 280, alignment: .leading)
    .background(c.surface)
  }

  private func hiddenHeroStyleRow(_ style: HomeHeroStyle) -> some View {
    let c = theme.colors
    return Button {
      HapticService.selection()
      HomeHeroStyleStorage.unhide(style)
      homeHeroStyleHiddenRaw = UserDefaults.standard.string(forKey: HomeHeroStyleStorage.hiddenKey) ?? ""
    } label: {
      HStack(spacing: 14) {
        Text(style.displayName)
          .font(AppTypography.settingsTitle)
          .foregroundStyle(c.textPrimary)
        Spacer()
        Text("Restaurar")
          .font(AppTypography.taskPreview)
          .foregroundStyle(c.accent)
      }
      .frame(minHeight: 44)
      .padding(.horizontal, SettingsChrome.rowPaddingH)
      .padding(.vertical, SettingsChrome.rowPaddingV)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  private func hideHeroStyle(_ style: HomeHeroStyle) {
    HapticService.selection()
    HomeHeroStyleStorage.hide(style)
    homeHeroStyleHiddenRaw = UserDefaults.standard.string(forKey: HomeHeroStyleStorage.hiddenKey) ?? ""
    if homeHeroStyleRaw == style.rawValue {
      homeHeroStyleRaw = HomeHeroStyleStorage.defaultRawValue
    }
    stylePendingHide = nil
  }

  private func iconRow(_ iconId: AppIconId) -> some View {
    let c = theme.colors
    let isSelected = iconManager.currentId == iconId

    return Button {
      guard !iconManager.isChanging, !isSelected else { return }
      HapticService.selection()
      _Concurrency.Task {
        do {
          try await iconManager.setIcon(iconId)
        } catch {
          iconErrorMessage = error.localizedDescription
        }
      }
    } label: {
      HStack(spacing: 14) {
        iconPreview(iconId)
        VStack(alignment: .leading, spacing: 3) {
          Text(iconId.displayName)
            .font(AppTypography.settingsTitle)
            .foregroundStyle(c.textPrimary)
          Text(iconId.subtitle)
            .font(AppTypography.taskPreview)
            .foregroundStyle(c.textSecondary)
        }
        Spacer()
        if isSelected {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(c.accent)
        } else if iconManager.isChanging {
          ProgressView()
            .controlSize(.small)
        }
      }
      .padding(.horizontal, SettingsChrome.rowPaddingH)
      .padding(.vertical, SettingsChrome.rowPaddingV)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(iconManager.isChanging)
  }

  private func themeSwatch(_ themeId: AppThemeId) -> some View {
    let swatch = themeId.previewSwatch
    return HStack(spacing: 0) {
      swatch.background.frame(width: 14)
      swatch.surface.frame(width: 14)
      swatch.accent.frame(width: 14)
    }
    .frame(height: 36)
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08)))
  }

  private func iconPreview(_ iconId: AppIconId) -> some View {
    Image(iconId.previewAssetName)
      .resizable()
      .aspectRatio(1, contentMode: .fit)
      .frame(width: 36, height: 36)
      .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .stroke(Color.white.opacity(0.08))
      )
  }
}

// MARK: - Accordion header

private enum AppearanceSectionID: String, Hashable {
  case theme
  case navBar
  case scrollFluidity
  case homeHero
  case hiddenHeroes
  case appIcon

  var icon: StackedIconKey {
    switch self {
    case .theme: .paintbrush
    case .navBar: .grid
    case .scrollFluidity: .productivity
    case .homeHero: .sun
    case .hiddenHeroes: .list
    case .appIcon: .checkCircle
    }
  }
}

private struct AppearanceSectionHeader: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let icon: StackedIconKey
  let title: String
  let summary: String
  let expanded: Bool
  let onToggle: () -> Void

  var body: some View {
    let c = theme.colors
    Button(action: onToggle) {
      HStack(spacing: 14) {
        ZStack {
          RoundedRectangle(cornerRadius: 11, style: .continuous)
            .fill(expanded ? c.accent.opacity(0.16) : c.surface)
          RoundedRectangle(cornerRadius: 11, style: .continuous)
            .strokeBorder(
              expanded ? c.accent.opacity(0.28) : Color.white.opacity(0.06),
              lineWidth: 1
            )
          StackedIcons.icon(icon, size: 17, color: expanded ? c.accent : c.textSecondary)
        }
        .frame(width: 40, height: 40)

        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(AppTypography.settingsTitle)
            .foregroundStyle(c.textPrimary)
          Text(summary)
            .font(AppTypography.taskPreview)
            .foregroundStyle(c.textSecondary)
            .lineLimit(1)
            .opacity(expanded ? 0.62 : 1)
        }

        Spacer(minLength: 8)

        ZStack {
          Circle()
            .fill(expanded ? c.accent.opacity(0.14) : c.surface)
          StackedIcons.image(.chevronDown)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(expanded ? c.accent : c.textTertiary)
            .rotationEffect(.degrees(expanded ? 0 : -90))
        }
        .frame(width: 28, height: 28)
        .animation(AppMotion.snappy(reduceMotion: reduceMotion), value: expanded)
      }
      .padding(.horizontal, SettingsChrome.rowPaddingH)
      .padding(.vertical, 13)
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(expanded ? "Recolher \(title)" : "Expandir \(title)")
    .accessibilityValue(summary)
    .accessibilityHint(expanded ? "Toque para recolher" : "Toque para expandir as opções")
  }
}
