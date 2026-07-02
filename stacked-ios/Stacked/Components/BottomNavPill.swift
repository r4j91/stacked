import SwiftUI

// Paridade lib/widgets/responsive_layout.dart _LiquidGlassPill
struct BottomNavPill: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @Binding var selectedTab: NavTab

  @State private var trackWidth: CGFloat = 0

  private let tabs = NavTab.allCases
  private let inset: CGFloat = 5
  private let pillShape = RoundedRectangle(cornerRadius: 32)

  var body: some View {
    let c = theme.colors
    let selectedIndex = tabs.firstIndex(of: selectedTab) ?? 0
    let slotWidth = trackWidth / CGFloat(tabs.count)
    let indicatorColor = c.isDark ? c.surfaceVariant : c.background

    HStack(spacing: 0) {
      ForEach(tabs) { tab in
        NavPillItem(
          tab: tab,
          selected: tab == selectedTab
        ) {
          selectedTab = tab
        }
        .frame(maxWidth: .infinity)
      }
    }
    .frame(height: AppLayout.bottomNavPillHeight)
    .onGeometryChange(for: CGFloat.self) { proxy in
      proxy.size.width
    } action: { newWidth in
      trackWidth = newWidth
    }
    .background(alignment: .topLeading) {
      if slotWidth > 0 {
        RoundedRectangle(cornerRadius: 26)
          .fill(indicatorColor)
          .frame(
            width: max(0, slotWidth - inset * 2),
            height: AppLayout.bottomNavPillHeight - inset * 2
          )
          .offset(x: CGFloat(selectedIndex) * slotWidth + inset, y: inset)
          .allowsHitTesting(false)
          .animation(AppMotion.navIndicatorSpring, value: selectedTab)
      }
    }
    .padding(ChromeLayout.pillInnerPadding)
    .background {
      navBarGlassBackground(navBarColor: c.navBar)
    }
  }

  @ViewBuilder
  private func navBarGlassBackground(navBarColor: Color) -> some View {
    if reduceTransparency {
      pillShape
        .fill(navBarColor)
        .allowsHitTesting(false)
    } else {
      pillShape
        .fill(.clear)
        .glassEffect(
          .regular.tint(navBarColor.opacity(LiquidGlass.glassTintOpacity)),
          in: pillShape
        )
        .allowsHitTesting(false)
    }
  }
}

private struct NavPillItem: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let tab: NavTab
  let selected: Bool
  let onSelect: () -> Void

  @State private var bounceScale: CGFloat = 1

  var body: some View {
    let c = theme.colors
    Button(action: onSelect) {
      VStack(spacing: 2) {
        StackedIcons.image(tab.stackedIcon)
          .font(.system(size: tab == .today ? 20 : 18, weight: .medium))
          .foregroundStyle(selected ? c.accent : c.textTertiary)
          .scaleEffect(bounceScale)
        Text(tab.label)
          .font(.system(size: 10.5, weight: selected ? .semibold : .regular))
          .foregroundStyle(selected ? c.accent : c.textTertiary)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
      .frame(maxWidth: .infinity)
      .frame(height: AppLayout.bottomNavPillHeight)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
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
