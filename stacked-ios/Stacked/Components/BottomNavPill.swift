import SwiftUI

// Paridade lib/widgets/responsive_layout.dart _LiquidGlassPill
struct BottomNavPill: View {
  @Environment(ThemeManager.self) private var theme
  let selectedTab: NavTab
  let onSelect: (NavTab) -> Void

  @State private var itemWidth: CGFloat = 0
  @State private var indicatorX: CGFloat = 0

  private let tabs = NavTab.allCases
  private let inset: CGFloat = 5

  var body: some View {
    let c = theme.colors
    let selectedIndex = tabs.firstIndex(of: selectedTab) ?? 0
    let indicatorColor = c.isDark ? c.surfaceVariant : c.background

    LiquidGlass.navBarPill(navBarColor: c.navBar) {
      GeometryReader { geo in
        let width = geo.size.width / CGFloat(tabs.count)

        ZStack(alignment: .topLeading) {
          RoundedRectangle(cornerRadius: 26)
            .fill(indicatorColor)
            .frame(width: max(0, itemWidth - inset * 2), height: geo.size.height - inset * 2)
            .offset(x: indicatorX + inset, y: inset)

          HStack(spacing: 0) {
            ForEach(tabs) { tab in
              NavPillItem(
                tab: tab,
                selected: tab == selectedTab,
                onSelect: { onSelect(tab) }
              )
              .frame(width: width)
            }
          }
        }
        .onAppear {
          itemWidth = width
          indicatorX = CGFloat(selectedIndex) * width
        }
        .onChange(of: geo.size.width) { _, newWidth in
          let w = newWidth / CGFloat(tabs.count)
          itemWidth = w
          indicatorX = CGFloat(selectedIndex) * w
        }
        .onChange(of: selectedTab) { _, tab in
          guard let idx = tabs.firstIndex(of: tab) else { return }
          withAnimation(AppMotion.navIndicatorSpring) {
            indicatorX = CGFloat(idx) * itemWidth
          }
        }
      }
      .frame(height: AppLayout.bottomNavPillHeight)
      .padding(.horizontal, 4)
      .padding(.vertical, 4)
    }
  }
}

private struct NavPillItem: View {
  @Environment(ThemeManager.self) private var theme
  let tab: NavTab
  let selected: Bool
  let onSelect: () -> Void

  @State private var bounceScale: CGFloat = 1

  var body: some View {
    let c = theme.colors
    Button {
      onSelect()
    } label: {
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
      withAnimation(AppMotion.iconBounceSpring) {
        bounceScale = 1
      }
    }
  }
}
