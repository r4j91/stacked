import SwiftUI

// Fase 3 — estilo "Ilha Expansível" (mockup D · Dynamic Island).
struct IslandNavBar: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(MobileChromeController.self) private var chrome
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @AppStorage(FabIntegratedInIslandStorage.key) private var fabIntegratedInIsland = true
  @Binding var selectedTab: NavTab

  private let tabs = NavTab.allCases

  private var fabIntegrated: Bool { fabIntegratedInIsland }

  private var navDimmed: Bool {
    fabIntegrated && chrome.fabOpen
  }

  var body: some View {
    // live/frozen no IslandNavGlassShell/DockNavTrackShell — pai não lê isContentScrolling.
    islandTrack
  }

  // MARK: - Track

  private var islandTrack: some View {
    let c = theme.colors
    let isExpanded = chrome.islandNavExpanded

    return GeometryReader { geo in
      let trackWidth = geo.size.width
      let pillWidth = IslandNavLayout.pillWidth(
        trackWidth: trackWidth,
        expanded: isExpanded,
        fabIntegrated: fabIntegrated
      )

      HStack(spacing: 0) {
        Spacer(minLength: 0)
        islandPillBody(colors: c, isExpanded: isExpanded, pillWidth: pillWidth)
          .frame(width: pillWidth, height: IslandNavMetrics.pillHeight)
        Spacer(minLength: 0)
      }
      .animation(islandAnimation, value: isExpanded)
      .animation(islandAnimation, value: fabIntegrated)
    }
    .frame(height: IslandNavMetrics.pillHeight)
    .padding(ChromeLayout.pillInnerPadding)
    .onAppear {
      syncExpandedItemsOpacity(isExpanded: isExpanded, animated: false)
    }
    .onChange(of: chrome.islandNavExpanded) { _, expanded in
      syncExpandedItemsOpacity(isExpanded: expanded, animated: true)
    }
  }

  @ViewBuilder
  private func islandPillBody(
    colors: AppThemeColors,
    isExpanded: Bool,
    pillWidth: CGFloat
  ) -> some View {
    HStack(spacing: 0) {
      Group {
        if isExpanded {
          expandedItems(colors: colors)
            .opacity(expandedItemsOpacity)
        } else {
          collapsedSummary(colors: colors, tab: selectedTab)
        }
      }
      .frame(maxWidth: .infinity)
      .animation(nil, value: isExpanded)
      .opacity(navDimmed ? IslandNavMetrics.fabMenuDimOpacity : 1)
      .animation(AppMotion.smooth(reduceMotion: reduceMotion), value: navDimmed)

      if fabIntegrated {
        islandFabSegment(colors: colors)
      }
    }
    .frame(width: pillWidth, height: IslandNavMetrics.pillHeight)
    .clipped()
    // Isola o conteúdo da ilha — sem isso o glass/live backdrop “arrasta” o scroll por baixo.
    .compositingGroup()
    .background {
      IslandNavGlassShell(colors: colors)
    }
    .allowsHitTesting(false)
  }

  private func collapsedSummary(colors: AppThemeColors, tab: NavTab) -> some View {
    HStack(spacing: 8) {
      StackedIcons.icon(tab.stackedIcon, size: tab.navIconSize, color: colors.accent)
        .frame(width: IslandNavMetrics.iconBoxSize, height: IslandNavMetrics.iconBoxSize)

      Text(tab.label)
        .font(.system(size: IslandNavMetrics.collapsedLabelSize, weight: .semibold))
        .foregroundStyle(colors.textPrimary)
        .lineLimit(1)
        .minimumScaleFactor(0.85)

      Spacer(minLength: 4)

      HStack(spacing: 3) {
        ForEach(0..<3, id: \.self) { _ in
          Circle()
            .fill(colors.textTertiary)
            .frame(width: 3, height: 3)
        }
      }
      .accessibilityHidden(true)
    }
    .padding(.horizontal, IslandNavMetrics.collapsedHorizontalPadding)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .id(tab)
    .animation(nil, value: selectedTab)
  }

  private func islandFabSegment(colors: AppThemeColors) -> some View {
    HStack(spacing: 0) {
      Rectangle()
        .fill(colors.textPrimary.opacity(0.08))
        .frame(width: IslandNavLayout.fabDividerWidth, height: 28)

      // SUBSTITUIDO_TEMAS_JADE: .foregroundStyle(colors.accent)
      StackedIcons.image(.plus)
        .font(.system(size: 20, weight: .medium))
        .foregroundStyle(colors.actionAccent)
        .rotationEffect(.degrees(chrome.fabOpen ? 45 : 0))
        .animation(AppMotion.bouncy(reduceMotion: reduceMotion), value: chrome.fabOpen)
        .frame(width: IslandNavLayout.fabSegmentWidth, height: IslandNavMetrics.pillHeight)
        .accessibilityLabel(chrome.fabOpen ? "Fechar menu de ações" : "Criar novo")
    }
  }

  private func expandedItems(colors: AppThemeColors) -> some View {
    HStack(spacing: 0) {
      ForEach(tabs) { tab in
        IslandNavExpandedItem(
          tab: tab,
          selected: tab == selectedTab,
          colors: colors
        )
        .frame(maxWidth: .infinity)
      }
    }
    .padding(.horizontal, IslandNavMetrics.expandedHorizontalPadding)
  }

  @State private var expandedItemsOpacity: CGFloat = 0

  private var islandAnimation: Animation? {
    if reduceMotion {
      return .easeInOut(duration: 0.2)
    }
    return AppMotion.islandNavSpring
  }

  private func syncExpandedItemsOpacity(isExpanded: Bool, animated: Bool) {
    guard isExpanded else {
      // Fecha: some o conteúdo expandido na hora — evita ícones “fantasma” atrás do glass.
      expandedItemsOpacity = 0
      return
    }
    if reduceMotion || !animated {
      expandedItemsOpacity = 1
      return
    }
    expandedItemsOpacity = 0
    withAnimation(
      .easeIn(duration: IslandNavMetrics.itemsFadeInDuration)
        .delay(IslandNavMetrics.itemsFadeInDelay)
    ) {
      expandedItemsOpacity = 1
    }
  }
}

// MARK: - Métricas

enum IslandNavMetrics {
  static let compactWidthRatio: CGFloat = 0.55
  static let pillHeight: CGFloat = 56
  static let iconBoxSize: CGFloat = 22
  static let collapsedLabelSize: CGFloat = 13
  static let collapsedHorizontalPadding: CGFloat = 14
  static let expandedHorizontalPadding: CGFloat = 4
  static let minTouchSize: CGFloat = 44
  // AJUSTADO_ISLAND_FADE
  static let itemsFadeInDelay: TimeInterval = 0.06
  static let itemsFadeInDuration: TimeInterval = 0.15
  /// FAB_INTEGRADO_ETAPA2 — opacidade dos itens de navegação com menu "+" aberto.
  static let fabMenuDimOpacity: CGFloat = 0.38
}

// MARK: - Glass shell (isolado do conteúdo animado da ilha)

private struct IslandNavGlassShell: View {
  let colors: AppThemeColors
  private let pillShape = Capsule()

  var body: some View {
    DockNavTrackShell(shape: pillShape, colors: colors)
  }
}

// MARK: - Item expandido

private struct IslandNavExpandedItem: View {
  @Environment(MobileChromeController.self) private var chrome
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let tab: NavTab
  let selected: Bool
  let colors: AppThemeColors

  private var isPressed: Bool { chrome.pressedTab == tab }

  var body: some View {
    let labelHeight = AppTypography.navLabelSize * 1.1
    let iconColor = selected ? colors.accent : colors.textSecondary

    VStack(spacing: 2) {
      StackedIcons.icon(tab.stackedIcon, size: tab.navIconSize, color: iconColor)
        .frame(width: IslandNavMetrics.iconBoxSize, height: IslandNavMetrics.iconBoxSize)
      Text(tab.label)
        .font(selected ? AppTypography.navLabelSelected : AppTypography.navLabel)
        .foregroundStyle(selected ? colors.accent : colors.textSecondary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(height: labelHeight)
    }
    .frame(minHeight: IslandNavMetrics.minTouchSize)
    .frame(height: IslandNavMetrics.pillHeight)
    .scaleEffect(isPressed && !reduceMotion ? 0.96 : 1)
    .animation(AppMotion.press(reduceMotion: reduceMotion), value: isPressed)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(tab.label)
    .accessibilityAddTraits(selected ? .isSelected : [])
  }
}

private extension AppTypography {
  static var navLabelSize: CGFloat { 10.5 }
}
