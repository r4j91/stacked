import SwiftUI

// Navbar mobile — shell glass iOS 26; blob sólido estilo Todoist (sem halo de glass no indicador).
struct BottomNavPill: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @Binding var selectedTab: NavTab

  @State private var trackWidth: CGFloat = 0

  private let tabs = NavTab.allCases
  private let indicatorInset: CGFloat = 4
  private let pillShape = RoundedRectangle(cornerRadius: 32)
  private let indicatorShape = RoundedRectangle(cornerRadius: 26)

  var body: some View {
    if reduceTransparency {
      solidPillBody
    } else {
      glassShellPillBody
    }
  }

  // MARK: - Shell glass + blob sólido (Todoist)

  private func selectionFill(colors: AppThemeColors) -> Color {
    colors.isDark ? colors.surfaceVariant : colors.background
  }

  private func selectionStrokeColor(colors: AppThemeColors) -> Color {
    if colors.isDark {
      return colors.textPrimary.opacity(LiquidGlass.navSelectionStrokeOpacity)
    }
    return colors.textSecondary.opacity(LiquidGlass.navSelectionStrokeOpacity * 1.25)
  }

  private func selectionCapsule(
    width: CGFloat,
    height: CGFloat,
    fill: Color,
    stroke: Color,
    offsetX: CGFloat,
    offsetY: CGFloat
  ) -> some View {
    ZStack {
      indicatorShape.fill(fill)
      indicatorShape.strokeBorder(stroke, lineWidth: LiquidGlass.navSelectionStrokeWidth)
    }
    .frame(width: width, height: height)
    .clipShape(indicatorShape)
    .offset(x: offsetX, y: offsetY)
  }

  private var glassShellPillBody: some View {
    let c = theme.colors
    let selectedIndex = tabs.firstIndex(of: selectedTab) ?? 0
    let slotWidth = trackWidth / CGFloat(tabs.count)
    let indicatorWidth = max(0, slotWidth - indicatorInset * 2)
    let indicatorHeight = AppLayout.bottomNavPillHeight - indicatorInset * 2
    let innerPad = ChromeLayout.pillInnerPadding
    let blobOffsetX = innerPad + CGFloat(selectedIndex) * slotWidth + indicatorInset
    let blobOffsetY = innerPad + indicatorInset

    return tabRow
      .frame(height: AppLayout.bottomNavPillHeight)
      .onGeometryChange(for: CGFloat.self) { proxy in
        proxy.size.width
      } action: { newWidth in
        trackWidth = newWidth
      }
      .padding(innerPad)
      .background {
        ZStack(alignment: .topLeading) {
          pillShape
            .fill(.clear)
            .glassEffect(
              .regular.tint(c.navBar.opacity(LiquidGlass.navTrackTintOpacity)),
              in: pillShape
            )
            .clipShape(pillShape)
            .overlay {
              pillShape.strokeBorder(
                c.textPrimary.opacity(LiquidGlass.navSelectionStrokeOpacity),
                lineWidth: LiquidGlass.navSelectionStrokeWidth
              )
            }

          if slotWidth > 0 {
            selectionCapsule(
              width: indicatorWidth,
              height: indicatorHeight,
              fill: selectionFill(colors: c),
              stroke: selectionStrokeColor(colors: c),
              offsetX: blobOffsetX,
              offsetY: blobOffsetY
            )
          }
        }
        .allowsHitTesting(false)
        .animation(AppMotion.navMorph(reduceMotion: reduceMotion), value: selectedTab)
      }
  }

  // MARK: - Fallback sólido (reduce transparency)

  private var solidPillBody: some View {
    let c = theme.colors
    let selectedIndex = tabs.firstIndex(of: selectedTab) ?? 0
    let slotWidth = trackWidth / CGFloat(tabs.count)
    let blobX = CGFloat(selectedIndex) * slotWidth + indicatorInset
    let blobY = indicatorInset
    let indicatorWidth = max(0, slotWidth - indicatorInset * 2)
    let indicatorHeight = AppLayout.bottomNavPillHeight - indicatorInset * 2

    return tabRow
      .frame(height: AppLayout.bottomNavPillHeight)
      .onGeometryChange(for: CGFloat.self) { proxy in
        proxy.size.width
      } action: { newWidth in
        trackWidth = newWidth
      }
      .background(alignment: .topLeading) {
        if slotWidth > 0 {
          selectionCapsule(
            width: indicatorWidth,
            height: indicatorHeight,
            fill: selectionFill(colors: c),
            stroke: selectionStrokeColor(colors: c),
            offsetX: blobX,
            offsetY: blobY
          )
          .allowsHitTesting(false)
          .animation(AppMotion.navMorph(reduceMotion: reduceMotion), value: selectedTab)
        }
      }
      .padding(ChromeLayout.pillInnerPadding)
      .background {
        pillShape
          .fill(c.navBar)
          .allowsHitTesting(false)
      }
  }

  private var tabRow: some View {
    HStack(spacing: 0) {
      ForEach(tabs) { tab in
        NavPillItem(
          tab: tab,
          selected: tab == selectedTab
        )
        .frame(maxWidth: .infinity)
      }
    }
  }
}

private enum NavPillMetrics {
  static let iconBoxSize: CGFloat = 24
  static let labelSize: CGFloat = 10.5
  static let labelLineHeight: CGFloat = 1.1
}

private struct NavPillItem: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let tab: NavTab
  let selected: Bool

  @State private var bounceScale: CGFloat = 1

  var body: some View {
    let c = theme.colors
    let labelHeight = NavPillMetrics.labelSize * NavPillMetrics.labelLineHeight

    VStack(spacing: 2) {
      StackedIcons.icon(tab.stackedIcon, size: tab.navIconSize, color: selected ? c.accent : c.textSecondary)
        .frame(width: NavPillMetrics.iconBoxSize, height: NavPillMetrics.iconBoxSize)
        .scaleEffect(bounceScale)
        .animation(AppMotion.navMorph(reduceMotion: reduceMotion), value: selected)
      Text(tab.label)
        .font(.system(size: NavPillMetrics.labelSize, weight: selected ? .semibold : .regular))
        .foregroundStyle(selected ? c.accent : c.textSecondary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(height: labelHeight)
        .animation(AppMotion.navMorph(reduceMotion: reduceMotion), value: selected)
    }
    .frame(maxWidth: .infinity)
    .frame(height: AppLayout.bottomNavPillHeight)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(tab.label)
    .accessibilityAddTraits(selected ? .isSelected : [])
    .onChange(of: selected) { wasSelected, isSelected in
      guard !wasSelected, isSelected else { return }
      bounceScale = 1.12
      AppMotion.animate(AppMotion.iconBounceSpring, reduceMotion: reduceMotion) {
        bounceScale = 1
      }
    }
  }
}
