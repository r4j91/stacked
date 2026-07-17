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
  @AppStorage(AlwaysStaticGlassStorage.key) private var alwaysStaticGlass = false
  @AppStorage(DisableAllGlassStorage.key) private var disableAllGlass = false
  @AppStorage(UIKitTaskListStorage.key) private var useUIKitTaskList = UIKitTaskListStorage.defaultEnabled
  @State private var stylePendingHide: HomeHeroStyle?
  @State private var showMoreThemes = false
  @State private var showMoreHeroes = false
  /// Uma seção aberta por vez — accordion leve no padrão do app (tudo fechado ao entrar).
  @State private var expandedSection: AppearanceSectionID? = nil
  /// Mantém o `SubtaskExpandReveal` montado até o collapse terminar (evita ghost).
  @State private var mountedSection: AppearanceSectionID? = nil
  @State private var accordionTeardownTask: _Concurrency.Task<Void, Never>?

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
    let recommendedThemes = AppThemeId.recommended
    let moreThemes = AppThemeId.allCases.filter { !recommendedThemes.contains($0) }
    let icons = AppIconId.allCases
    let navStyles = NavBarStyle.allCases
    let heroGroups = showMoreHeroes
      ? HomeHeroStyleGroup.pickerGroups
      : [.recommended]
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
          appearanceGroupHeader("Recomendados")
          ForEach(Array(recommendedThemes.enumerated()), id: \.element) { index, themeId in
            themeRow(themeId)
            if index < recommendedThemes.count - 1 || showMoreThemes {
              SettingsCardDivider(leadingPadding: 56)
            }
          }
          if showMoreThemes {
            appearanceGroupHeader("Mais temas")
            ForEach(Array(moreThemes.enumerated()), id: \.element) { index, themeId in
              themeRow(themeId)
              if index < moreThemes.count - 1 {
                SettingsCardDivider(leadingPadding: 56)
              }
            }
          }
          moreOptionsButton(
            expanded: showMoreThemes,
            collapsedTitle: "Mostrar mais \(moreThemes.count) temas",
            expandedTitle: "Mostrar menos temas"
          ) {
            showMoreThemes.toggle()
          }
        }

        appearancePanel(
          id: .navBar,
          title: "Barra de navegação",
          summary: navBarStyle.displayName,
          footer: isIslandNavStyle
            ? nil
            : "O botão + integrado só está disponível no estilo Ilha."
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
          id: .homeHero,
          title: "Hero da Home",
          summary: homeHeroStyle.displayName,
          footer: "Recomendados: Trilho, Masthead, Horizonte e Clássico. Use ⋯ para ocultar. Clima e Jornada ficam em Mais."
        ) {
          appearanceGroupHeader("Recomendados")
          ForEach(Array(heroGroups.enumerated()), id: \.element) { groupIndex, group in
            let styles = HomeHeroStyle.styles(in: group)
            if !styles.isEmpty {
              if group == .recommended {
                Color.clear.frame(height: 2)
              } else {
                Text(group.displayName)
                  .font(AppTypography.metaSmall.weight(.semibold))
                  .foregroundStyle(c.textTertiary)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding(.horizontal, SettingsChrome.rowPaddingH)
                  .padding(.top, groupIndex == 0 ? 8 : 14)
                  .padding(.bottom, 2)
              }
              ForEach(Array(styles.enumerated()), id: \.element) { index, style in
                homeHeroStyleRow(style)
                if index < styles.count - 1 {
                  SettingsCardDivider(leadingPadding: 82)
                }
              }
            }
          }
          moreOptionsButton(
            expanded: showMoreHeroes,
            collapsedTitle: "Mostrar estilos de Clima e Jornada",
            expandedTitle: "Mostrar apenas recomendados"
          ) {
            showMoreHeroes.toggle()
          }
        }

        if iconManager.isSupported {
          appearancePanel(
            id: .appIcon,
            title: "Ícone do app",
            summary: iconManager.currentId.displayName,
            footer: "O iPhone pede confirmação antes de trocar o ícone."
          ) {
            ForEach(Array(icons.enumerated()), id: \.element) { index, iconId in
              iconRow(iconId)
              if index < icons.count - 1 {
                SettingsCardDivider(leadingPadding: 56)
              }
            }
          }
        }

        appearancePanel(
          id: .advanced,
          title: "Opções avançadas",
          summary: "Efeitos, desempenho e itens ocultos",
          footer: scrollFluidityFooter
        ) {
          appearanceGroupHeader("Barra e listas · \(scrollFluiditySummary)")
          alwaysStaticGlassRow()
          SettingsCardDivider(leadingPadding: 56)
          disableAllGlassRow()
          SettingsCardDivider(leadingPadding: 56)
          freezeDockGlassRow()
          SettingsCardDivider(leadingPadding: 56)
          alwaysFrozenDockGlassRow()
          SettingsCardDivider(leadingPadding: 56)
          uikitTaskListRow()

          if !hiddenStyles.isEmpty {
            SettingsCardDivider(leadingPadding: 16)
            appearanceGroupHeader("Estilos ocultos")
            ForEach(Array(hiddenStyles.enumerated()), id: \.element) { index, style in
              hiddenHeroStyleRow(style)
              if index < hiddenStyles.count - 1 {
                SettingsCardDivider(leadingPadding: 16)
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
    .onAppear {
      iconManager.syncFromSystem()
      if !AppThemeId.recommended.contains(theme.currentId) {
        showMoreThemes = true
      }
      if homeHeroStyle.pickerGroup != .recommended {
        showMoreHeroes = true
      }
      if HomeHeroStyleStorage.migrateRetiredSelectionIfNeeded() {
        homeHeroStyleRaw = UserDefaults.standard.string(forKey: HomeHeroStyleStorage.key)
          ?? HomeHeroStyleStorage.defaultRawValue
      }
    }
    .alert(
      "Ocultar este estilo?",
      isPresented: Binding(
        get: { stylePendingHide != nil },
        set: { if !$0 { stylePendingHide = nil } }
      ),
      presenting: stylePendingHide
    ) { style in
      Button("Ocultar \"\(style.displayName)\"", role: .destructive) {
        hideHeroStyle(style)
      }
      Button("Manter no menu", role: .cancel) {
        stylePendingHide = nil
      }
    } message: { style in
      Text("“\(style.displayName)” some do menu. Dá para restaurar depois em Estilos ocultos.")
    }
    .alert("Não foi possível trocar o ícone", isPresented: Binding(
      get: { iconErrorMessage != nil },
      set: { if !$0 { iconErrorMessage = nil } }
    )) {
      Button("Entendi", role: .cancel) { iconErrorMessage = nil }
    } message: {
      Text(iconErrorMessage ?? "")
    }
  }

  // MARK: - Accordion (altura UIKit — paridade SubtaskExpandReveal)

  @ViewBuilder
  private func appearancePanel<Content: View>(
    id: AppearanceSectionID,
    title: String,
    summary: String,
    footer: String?,
    @ViewBuilder content: @escaping () -> Content
  ) -> some View {
    let expanded = expandedSection == id
    let mounted = mountedSection == id
    let c = theme.colors

    SettingsCardSurface {
      VStack(spacing: 0) {
        AppearanceSectionHeader(
          icon: id.icon,
          title: title,
          summary: summary,
          expanded: expanded
        ) {
          toggleAppearanceSection(id)
        }

        if mounted {
          SubtaskExpandReveal(
            expanded: expanded,
            reduceMotion: reduceMotion,
            layoutPass: 0,
            contentRevision: appearancePanelRevision(id: id, summary: summary, footer: footer)
          ) {
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
          }
        }
      }
    }
  }

  private func appearancePanelRevision(id: AppearanceSectionID, summary: String, footer: String?) -> Int {
    var hasher = Hasher()
    hasher.combine(id)
    hasher.combine(summary)
    hasher.combine(footer)
    hasher.combine(showMoreThemes)
    hasher.combine(showMoreHeroes)
    hasher.combine(homeHeroStyleHiddenRaw)
    return hasher.finalize()
  }

  private func toggleAppearanceSection(_ id: AppearanceSectionID) {
    HapticService.selection()
    if expandedSection == id {
      collapseAppearanceSection(id)
      return
    }
    if let previous = expandedSection, previous != id {
      collapseAppearanceSection(previous)
    }
    openAppearanceSection(id)
  }

  private func openAppearanceSection(_ id: AppearanceSectionID) {
    accordionTeardownTask?.cancel()
    // Mesmo passo: mount + expand. Yield antigo montava o painel com
    // expanded=false/EmptyView e o SubtaskExpandReveal ficava em altura 0.
    AppMotion.animate(AppMotion.subtaskExpandSpring, reduceMotion: reduceMotion) {
      mountedSection = id
      expandedSection = id
    }
  }

  private func collapseAppearanceSection(_ id: AppearanceSectionID) {
    AppMotion.animate(AppMotion.subtaskCollapseSpring, reduceMotion: reduceMotion) {
      if expandedSection == id {
        expandedSection = nil
      }
    }
    accordionTeardownTask?.cancel()
    accordionTeardownTask = _Concurrency.Task { @MainActor in
      let delayMs = reduceMotion ? 0 : 230
      try? await _Concurrency.Task.sleep(for: .milliseconds(delayMs))
      guard !_Concurrency.Task.isCancelled else { return }
      guard expandedSection != id else { return }
      if mountedSection == id {
        mountedSection = nil
      }
    }
  }

  private var scrollFluiditySummary: String {
    if useUIKitTaskList { return "Listas mais fluidas" }
    if disableAllGlass { return "Sem translucidez" }
    if alwaysStaticGlass { return "Efeito quieto" }
    if alwaysFrozenDockGlass { return "Barra sem efeito" }
    return freezeDockGlassWhileScrolling ? "Efeito pausado ao rolar" : "Efeito ao vivo"
  }

  private var scrollFluidityFooter: String {
    if useUIKitTaskList {
      return "Listas de tarefas rolam com menos trancos. Desligue para voltar ao modo anterior."
    }
    if disableAllGlass {
      return "Barra e botões ficam opacos. Para translucidez sem animação, use Efeito quieto."
    }
    if alwaysStaticGlass {
      return "Fundo translúcido sem animação do efeito."
    }
    if alwaysFrozenDockGlass {
      return "Só a barra fica sem efeito; o restante continua ao vivo."
    }
    return "Pausar ao rolar congela a barra. Efeito quieto deixa tudo estável. Sem translucidez remove o efeito."
  }

  // MARK: - Rows

  private func appearanceGroupHeader(_ title: String) -> some View {
    Text(title)
      .font(AppTypography.metaSmall.weight(.semibold))
      .foregroundStyle(theme.colors.textTertiary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, SettingsChrome.rowPaddingH)
      .padding(.top, 10)
      .padding(.bottom, 4)
  }

  private func moreOptionsButton(
    expanded: Bool,
    collapsedTitle: String,
    expandedTitle: String,
    action: @escaping () -> Void
  ) -> some View {
    Button {
      HapticService.selection()
      AppMotion.animate(AppMotion.smooth, reduceMotion: reduceMotion, action)
    } label: {
      HStack(spacing: 8) {
        Text(expanded ? expandedTitle : collapsedTitle)
          .font(AppTypography.taskPreview.weight(.semibold))
        Spacer(minLength: 8)
        Image(systemName: expanded ? "chevron.up" : "chevron.down")
          .font(.system(size: 11, weight: .semibold))
      }
      .foregroundStyle(theme.colors.accent)
      .padding(.horizontal, SettingsChrome.rowPaddingH)
      .padding(.vertical, 12)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityValue(expanded ? "Expandido" : "Recolhido")
  }

  private func alwaysStaticGlassRow() -> some View {
    let c = theme.colors
    let dimmed = disableAllGlass

    return HStack(spacing: 14) {
      VStack(alignment: .leading, spacing: 3) {
        Text("Efeito quieto")
          .font(AppTypography.settingsTitle)
          .foregroundStyle(dimmed ? c.textTertiary : c.textPrimary)
        Text("Fundo translúcido, sem animação.")
          .font(AppTypography.taskPreview)
          .foregroundStyle(c.textSecondary)
      }
      Spacer(minLength: 8)
      SettingsSwitchToggle(isOn: $alwaysStaticGlass, tint: c.actionAccent)
        .disabled(dimmed)
    }
    .frame(minHeight: 44)
    .padding(.horizontal, SettingsChrome.rowPaddingH)
    .padding(.vertical, SettingsChrome.rowPaddingV)
    .opacity(dimmed ? 0.55 : 1)
    .onChange(of: alwaysStaticGlass) { _, isOn in
      HapticService.selection()
      if isOn { disableAllGlass = false }
    }
  }

  private func disableAllGlassRow() -> some View {
    let c = theme.colors

    return HStack(spacing: 14) {
      VStack(alignment: .leading, spacing: 3) {
        Text("Sem translucidez")
          .font(AppTypography.settingsTitle)
          .foregroundStyle(c.textPrimary)
        Text("Fundo opaco, sem mostrar o que passa atrás.")
          .font(AppTypography.taskPreview)
          .foregroundStyle(c.textSecondary)
      }
      Spacer(minLength: 8)
      SettingsSwitchToggle(isOn: $disableAllGlass, tint: c.actionAccent)
    }
    .frame(minHeight: 44)
    .padding(.horizontal, SettingsChrome.rowPaddingH)
    .padding(.vertical, SettingsChrome.rowPaddingV)
    .onChange(of: disableAllGlass) { _, isOn in
      HapticService.selection()
      if isOn { alwaysStaticGlass = false }
    }
  }

  private func freezeDockGlassRow() -> some View {
    let c = theme.colors
    let dimmed = disableAllGlass || alwaysStaticGlass || alwaysFrozenDockGlass

    return HStack(spacing: 14) {
      VStack(alignment: .leading, spacing: 3) {
        Text("Pausar efeito ao rolar")
          .font(AppTypography.settingsTitle)
          .foregroundStyle(dimmed ? c.textTertiary : c.textPrimary)
        Text("Congela o efeito da barra enquanto a lista rola.")
          .font(AppTypography.taskPreview)
          .foregroundStyle(c.textSecondary)
      }
      Spacer(minLength: 8)
      SettingsSwitchToggle(isOn: $freezeDockGlassWhileScrolling, tint: c.actionAccent)
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
    let dimmed = disableAllGlass || alwaysStaticGlass

    return HStack(spacing: 14) {
      VStack(alignment: .leading, spacing: 3) {
        Text("Barra sem efeito")
          .font(AppTypography.settingsTitle)
          .foregroundStyle(dimmed ? c.textTertiary : c.textPrimary)
        Text("Só a barra fica sem efeito; ainda dá para ver atrás.")
          .font(AppTypography.taskPreview)
          .foregroundStyle(c.textSecondary)
      }
      Spacer(minLength: 8)
      SettingsSwitchToggle(isOn: $alwaysFrozenDockGlass, tint: c.actionAccent)
        .disabled(dimmed)
    }
    .frame(minHeight: 44)
    .padding(.horizontal, SettingsChrome.rowPaddingH)
    .padding(.vertical, SettingsChrome.rowPaddingV)
    .opacity(dimmed ? 0.55 : 1)
    .onChange(of: alwaysFrozenDockGlass) { _, _ in
      HapticService.selection()
    }
  }

  private func uikitTaskListRow() -> some View {
    let c = theme.colors

    return HStack(spacing: 14) {
      VStack(alignment: .leading, spacing: 3) {
        Text("Listas mais fluidas")
          .font(AppTypography.settingsTitle)
          .foregroundStyle(c.textPrimary)
        Text("Rolagem das listas mais suave. Desligue para o modo anterior.")
          .font(AppTypography.taskPreview)
          .foregroundStyle(c.textSecondary)
      }
      Spacer(minLength: 8)
      SettingsSwitchToggle(isOn: $useUIKitTaskList, tint: c.actionAccent)
    }
    .frame(minHeight: 44)
    .padding(.horizontal, SettingsChrome.rowPaddingH)
    .padding(.vertical, SettingsChrome.rowPaddingV)
    .onChange(of: useUIKitTaskList) { _, _ in
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
        Text("Botão + na ilha")
          .font(AppTypography.settingsTitle)
          .foregroundStyle(isIslandNavStyle ? c.textPrimary : c.textTertiary)
        Text("O + fica dentro da barra, em vez de flutuar acima.")
          .font(AppTypography.taskPreview)
          .foregroundStyle(c.textSecondary)
      }
      Spacer(minLength: 8)
      SettingsSwitchToggle(isOn: $fabIntegratedInIsland, tint: c.actionAccent)
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

    return HStack(alignment: .center, spacing: 12) {
      Button {
        guard !isSelected else { return }
        HapticService.selection()
        homeHeroStyleRaw = style.rawValue
      } label: {
        HStack(alignment: .center, spacing: 12) {
          HomeHeroStylePreview(style: style, colors: c, selected: isSelected)
            .frame(width: 56, height: 36)
            .clipped()

          VStack(alignment: .leading, spacing: 3) {
            Text(style.displayName)
              .font(AppTypography.settingsTitle)
              .foregroundStyle(c.textPrimary)
              .lineLimit(1)
              .minimumScaleFactor(0.88)
            Text(style.subtitle)
              .font(AppTypography.taskPreview)
              .foregroundStyle(c.textSecondary)
              .lineLimit(2)
          }

          Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .contextMenu {
        if style.canHideFromPicker {
          Button("Ocultar \"\(style.displayName)\"", role: .destructive) {
            stylePendingHide = style
          }
        }
      } preview: {
        homeHeroStyleContextPreview(style)
      }

      if style.canHideFromPicker {
        Menu {
          Button("Ocultar \"\(style.displayName)\"", role: .destructive) {
            stylePendingHide = style
          }
        } label: {
          Image(systemName: "ellipsis.circle")
            .font(.system(size: 18, weight: .regular))
            .foregroundStyle(c.textTertiary)
            .frame(width: 36, height: 36)
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .frame(width: 36, height: 36)
      } else {
        Color.clear
          .frame(width: 36, height: 36)
      }

      Group {
        if isSelected {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(c.accent)
        } else {
          Color.clear
        }
      }
      .frame(width: 22)
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
  case homeHero
  case appIcon
  case advanced

  var icon: StackedIconKey {
    switch self {
    case .theme: .paintbrush
    case .navBar: .grid
    case .homeHero: .sun
    case .appIcon: .checkCircle
    case .advanced: .productivity
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
          SubtaskExpandChevron(expanded: expanded, size: 11)
        }
        .frame(width: 28, height: 28)
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
