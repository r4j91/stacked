import SwiftUI

// Paridade lib/widgets/responsive_layout.dart _LiquidGlassPill
struct BottomNavPill: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
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

<<<<<<< HEAD
    if reduceTransparency {
      solidNavPill(
        navBarColor: c.navBar,
        indicatorColor: indicatorColor,
        selectedIndex: selectedIndex
      )
    } else {
      morphGlassNavPill(
        navBarColor: c.navBar,
        indicatorColor: indicatorColor,
        selectedIndex: selectedIndex
      )
    }
  }

  // MARK: - FASE6 morph glass (shell + indicador no mesmo GlassEffectContainer)

  @ViewBuilder
  private func morphGlassNavPill(
    navBarColor: Color,
    indicatorColor: Color,
    selectedIndex: Int
  ) -> some View {
    // SUBSTITUIDO_FASE7A: GeometryReader na raiz sem navBarPill — expandia à altura da tela
    // (parent .frame(maxHeight: .infinity) em MobileShell) e deslocava navbar/FAB.
    LiquidGlass.navBarPill(navBarColor: navBarColor) {
      GeometryReader { geo in
        let slotWidth = geo.size.width / CGFloat(tabs.count)

        ZStack(alignment: .topLeading) {
          GlassEffectContainer(spacing: glassMergeSpacing) {
            navGlassIndicator(indicatorColor: indicatorColor, height: geo.size.height)
          }

          navItemsRow(slotWidth: slotWidth)
        }
        .onAppear {
          syncMetrics(slotWidth: slotWidth, selectedIndex: selectedIndex)
        }
        .onChange(of: geo.size.width) { _, newWidth in
          let w = newWidth / CGFloat(tabs.count)
          itemWidth = w
          indicatorX = CGFloat(tabs.firstIndex(of: selectedTab) ?? 0) * w
        }
        .onChange(of: selectedTab) { old, tab in
          guard old != tab else { return }
          guard let idx = tabs.firstIndex(of: tab), itemWidth > 0 else { return }
          let targetX = CGFloat(idx) * itemWidth
          guard abs(indicatorX - targetX) > 0.5 else { return }
          animateIndicator(toIndex: idx) {}
        }
      }
      .frame(height: AppLayout.bottomNavPillHeight)
      .padding(.horizontal, 4)
      .padding(.vertical, 4)
    }
  }

  @ViewBuilder
  private func navGlassIndicator(indicatorColor: Color, height: CGFloat) -> some View {
    let indicatorShape = RoundedRectangle(cornerRadius: 26)
    let baseWidth = max(0, itemWidth - inset * 2)
    let indicatorHeight = height - inset * 2

    // SUBSTITUIDO_FASE6: RoundedRectangle.fill(indicatorColor) sólido transladando
    indicatorShape
      .fill(.clear)
      .frame(width: baseWidth, height: indicatorHeight)
      .scaleEffect(x: indicatorStretchX, y: 1, anchor: .center)
      .glassEffect(
        .regular.interactive().tint(indicatorColor),
        in: indicatorShape
      )
      .glassEffectID("nav-tab-indicator", in: navGlassNamespace)
      .offset(x: indicatorX + inset, y: inset)
      .allowsHitTesting(false)
  }

  @ViewBuilder
  private func navItemsRow(slotWidth: CGFloat) -> some View {
    HStack(spacing: 0) {
      ForEach(tabs) { tab in
        NavPillItem(
          tab: tab,
          selected: tab == selectedTab,
          onSelect: { selectTab(tab) }
        )
        .frame(width: slotWidth)
      }
    }
  }

  // MARK: - Fallback sólido (reduce-transparency — paridade Fase 1A)

  @ViewBuilder
  private func solidNavPill(
    navBarColor: Color,
    indicatorColor: Color,
    selectedIndex: Int
  ) -> some View {
    LiquidGlass.navBarPill(navBarColor: navBarColor) {
=======
    LiquidGlass.navBarPill(navBarColor: c.navBar) {
>>>>>>> parent of b50852f (fix: morphliquid)
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
          // SUBSTITUIDO_FASE2: withAnimation(AppMotion.navIndicatorSpring) { indicatorX = ... }
          AppMotion.animate(AppMotion.navIndicatorSpring, reduceMotion: reduceMotion) {
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
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
      // SUBSTITUIDO_FASE2: withAnimation(AppMotion.iconBounceSpring) { bounceScale = 1 }
      AppMotion.animate(AppMotion.iconBounceSpring, reduceMotion: reduceMotion) {
        bounceScale = 1
      }
    }
  }
}
