import SwiftUI

// Paridade lib/screens/appearance_screen.dart
struct AppearanceView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme
  @State private var iconManager = AppIconManager.shared
  @State private var iconErrorMessage: String?
  @AppStorage(NavBarStyleStorage.key) private var navBarStyleRaw = NavBarStyleStorage.defaultRawValue
  @AppStorage(HomeHeroStyleStorage.key) private var homeHeroStyleRaw = HomeHeroStyleStorage.defaultRawValue
  @AppStorage(HomeHeroStyleStorage.hiddenKey) private var homeHeroStyleHiddenRaw = ""
  @AppStorage(FabIntegratedInIslandStorage.key) private var fabIntegratedInIsland = false
  @State private var stylePendingHide: HomeHeroStyle?

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

    List {
      Section {
        SettingsCardSurface {
          VStack(spacing: 0) {
            ForEach(Array(themes.enumerated()), id: \.element) { index, themeId in
              themeRow(themeId)
              if index < themes.count - 1 {
                SettingsCardDivider(leadingPadding: 56)
              }
            }
          }
        }
        .settingsListCardRow(top: 8)
      }

      Section {
        SettingsCardSurface {
          VStack(spacing: 0) {
            ForEach(Array(navStyles.enumerated()), id: \.element) { index, style in
              navBarStyleRow(style)
              if index < navStyles.count - 1 {
                SettingsCardDivider(leadingPadding: 56)
              }
            }
            SettingsCardDivider(leadingPadding: 56)
            fabIntegratedInIslandRow()
          }
        }
        .settingsListCardRow(top: 4, bottom: 4)
      } header: {
        SettingsSectionHeader(text: "Barra de navegação")
      } footer: {
        if !isIslandNavStyle {
          Text("FAB integrado na ilha está disponível apenas com a navbar em Ilha.")
            .font(AppTypography.taskPreview)
            .foregroundStyle(theme.colors.textTertiary)
            .settingsListCardRow(top: 0, bottom: 8)
            .listRowBackground(Color.clear)
        }
      }

      ForEach(heroGroups) { group in
        let styles = HomeHeroStyle.styles(in: group)
        if !styles.isEmpty {
          Section {
            SettingsCardSurface {
              VStack(spacing: 0) {
                ForEach(Array(styles.enumerated()), id: \.element) { index, style in
                  homeHeroStyleRow(style)
                  if index < styles.count - 1 {
                    SettingsCardDivider(leadingPadding: 56)
                  }
                }
              }
            }
            .settingsListCardRow(top: group == heroGroups.first ? 4 : 0, bottom: 4)
          } header: {
            SettingsSectionHeader(text: group == .recommended ? "Hero da Home" : group.displayName)
          } footer: {
            if group == .weather {
              Text("Em cada estilo, use o menu ⋯ para excluir só aquele card.")
                .font(AppTypography.taskPreview)
                .foregroundStyle(theme.colors.textTertiary)
                .settingsListCardRow(top: 0, bottom: 4)
                .listRowBackground(Color.clear)
            }
          }
        }
      }

      let hiddenStyles = HomeHeroStyleStorage.hiddenStyles()
      if !hiddenStyles.isEmpty {
        Section {
          SettingsCardSurface {
            VStack(spacing: 0) {
              ForEach(Array(hiddenStyles.enumerated()), id: \.element) { index, style in
                hiddenHeroStyleRow(style)
                if index < hiddenStyles.count - 1 {
                  SettingsCardDivider(leadingPadding: 16)
                }
              }
            }
          }
          .settingsListCardRow(top: 0, bottom: 4)
        } header: {
          SettingsSectionHeader(text: "Estilos ocultos")
        } footer: {
          Text("Restaure um estilo para ele voltar ao menu de cards.")
            .font(AppTypography.taskPreview)
            .foregroundStyle(theme.colors.textTertiary)
            .settingsListCardRow(top: 0, bottom: 8)
            .listRowBackground(Color.clear)
        }
      }

      if iconManager.isSupported {
        Section {
          SettingsCardSurface {
            VStack(spacing: 0) {
              ForEach(Array(icons.enumerated()), id: \.element) { index, iconId in
                iconRow(iconId)
                if index < icons.count - 1 {
                  SettingsCardDivider(leadingPadding: 56)
                }
              }
            }
          }
          .settingsListCardRow(top: 4, bottom: 4)
        } header: {
          SettingsSectionHeader(text: "Ícone do app")
        }

        Section {
          Text("O iOS pede confirmação ao trocar o ícone na tela de início. O ícone padrão permanece o configurado no Xcode.")
            .font(AppTypography.taskPreview)
            .foregroundStyle(c.textTertiary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .settingsListCardRow(top: 0, bottom: 8)
            .listRowBackground(Color.clear)
        }
      }
    }
    .settingsDrillDownList(background: c.background)
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
