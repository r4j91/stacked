import SwiftUI

// Fase 3 — estilo "Ilha Expansível" (mockup D · Dynamic Island).
struct IslandNavBar: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(MobileChromeController.self) private var chrome
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @Binding var selectedTab: NavTab

  private let tabs = NavTab.allCases
  private let pillShape = Capsule()

  var body: some View {
    if reduceTransparency {
      islandTrack(useGlass: false)
    } else {
      islandTrack(useGlass: true)
    }
  }

  // MARK: - Track

  private func islandTrack(useGlass: Bool) -> some View {
    let c = theme.colors
    let isExpanded = chrome.islandNavExpanded

    return GeometryReader { geo in
      let trackWidth = geo.size.width
      let pillWidth = isExpanded ? trackWidth : trackWidth * IslandNavMetrics.compactWidthRatio

      HStack(spacing: 0) {
        Spacer(minLength: 0)
        islandPillBody(colors: c, isExpanded: isExpanded, pillWidth: pillWidth, useGlass: useGlass)
          .frame(width: pillWidth, height: IslandNavMetrics.pillHeight)
        Spacer(minLength: 0)
      }
      .animation(islandAnimation, value: isExpanded)
      // REMOVIDO_SELECTED_TAB_ANIM — .animation(islandAnimation, value: selectedTab)
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
    pillWidth: CGFloat,
    useGlass: Bool
  ) -> some View {
    ZStack {
      collapsedSummary(colors: colors, tab: selectedTab)
        .opacity(isExpanded ? 0 : 1)

      expandedItems(colors: colors)
        .opacity(expandedItemsOpacity)
    }
    .frame(width: pillWidth, height: IslandNavMetrics.pillHeight)
    .clipped()
    .background {
      if useGlass {
        pillShape
          .fill(.clear)
          .glassEffect(
            .regular.tint(colors.navBar.opacity(LiquidGlass.navTrackTintOpacity)),
            in: pillShape
          )
          .clipShape(pillShape)
          .overlay {
            pillShape.strokeBorder(
              colors.textPrimary.opacity(LiquidGlass.navSelectionStrokeOpacity),
              lineWidth: LiquidGlass.navSelectionStrokeWidth
            )
          }
      } else {
        pillShape
          .fill(colors.navBar)
      }
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
        .contentTransition(.opacity) // AJUSTADO_CONTENT_TRANSITION
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
  }

  private func expandedItems(colors: AppThemeColors) -> some View {
    HStack(spacing: 0) {
      ForEach(tabs) { tab in
        IslandNavExpandedItem(
          tab: tab,
          selected: tab == selectedTab,
          colors: colors,
          itemsVisible: expandedItemsOpacity > 0.01
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
      expandedItemsOpacity = 0
      return
    }
    if reduceMotion || !animated {
      expandedItemsOpacity = 1
      return
    }
    expandedItemsOpacity = 0
    withAnimation(.easeIn(duration: IslandNavMetrics.itemsFadeInDuration).delay(IslandNavMetrics.itemsFadeInDelay)) {
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
}

// MARK: - Item expandido

private struct IslandNavExpandedItem: View {
  @Environment(MobileChromeController.self) private var chrome
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let tab: NavTab
  let selected: Bool
  let colors: AppThemeColors
  let itemsVisible: Bool

  @State private var bounceScale: CGFloat = 1

  private var isPressed: Bool { chrome.pressedTab == tab }

  var body: some View {
    let labelHeight = AppTypography.navLabelSize * 1.1
    let iconColor = selected ? colors.accent : colors.textSecondary

    VStack(spacing: 2) {
      StackedIcons.icon(tab.stackedIcon, size: tab.navIconSize, color: iconColor)
        .frame(width: IslandNavMetrics.iconBoxSize, height: IslandNavMetrics.iconBoxSize)
        .scaleEffect(bounceScale)
      Text(tab.label)
        .font(selected ? AppTypography.navLabelSelected : AppTypography.navLabel)
        .foregroundStyle(selected ? colors.accent : colors.textSecondary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(height: labelHeight)
        .opacity(itemsVisible ? 1 : 0)
    }
    .frame(minHeight: IslandNavMetrics.minTouchSize)
    .frame(height: IslandNavMetrics.pillHeight)
    .scaleEffect(isPressed && !reduceMotion ? 0.96 : 1)
    .animation(AppMotion.press(reduceMotion: reduceMotion), value: isPressed)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(tab.label)
    .accessibilityAddTraits(selected ? .isSelected : [])
    .onChange(of: selected) { wasSelected, isSelected in
      guard !wasSelected, isSelected else { return }
      runIconBounce()
    }
  }

  private func runIconBounce() {
    if reduceMotion {
      bounceScale = 1
      return
    }
    _Concurrency.Task { @MainActor in
      try? await _Concurrency.Task.sleep(for: AppMotion.navIconFollowDelay)
      guard selected else { return }
      bounceScale = 1.14
      AppMotion.animate(AppMotion.iconBounceSpring, reduceMotion: reduceMotion) {
        bounceScale = 1
      }
    }
  }
}

private extension AppTypography {
  static var navLabelSize: CGFloat { 10.5 }
}
