import SwiftUI

// Fase 2 — estilo "Expandida" (mockup C · Ativo Expandido, referência Linear/Arc).
struct ExpandedNavBar: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @Binding var selectedTab: NavTab

  @Namespace private var capsuleNamespace

  private let tabs = NavTab.allCases
  private let pillShape = RoundedRectangle(cornerRadius: 32)

  var body: some View {
    if reduceTransparency {
      solidPillBody
    } else {
      glassShellPillBody
    }
  }

  // MARK: - Conteúdo (cápsula ativa + itens)

  private func pillContent(colors: AppThemeColors) -> some View {
    GeometryReader { geo in
      let widths = slotWidths(totalWidth: geo.size.width, selected: selectedTab)

      ZStack {
        HStack(spacing: 0) {
          ForEach(tabs) { tab in
            Color.clear
              .frame(width: widths[tab] ?? 0)
              .background {
                if tab == selectedTab {
                  activeCapsule(colors: colors)
                }
              }
          }
        }
        .animation(expandedNavAnimation, value: selectedTab)
        .allowsHitTesting(false)

        HStack(spacing: 0) {
          ForEach(tabs) { tab in
            ExpandedNavItem(
              tab: tab,
              selected: tab == selectedTab,
              slotWidth: widths[tab] ?? 0,
              colors: colors
            )
          }
        }
        .animation(expandedNavAnimation, value: selectedTab)
      }
    }
    .frame(height: AppLayout.bottomNavPillHeight)
  }

  private func slotWidths(totalWidth: CGFloat, selected: NavTab) -> [NavTab: CGFloat] {
    ExpandedNavLayout.slotWidths(totalWidth: totalWidth, selected: selected)
  }

  @ViewBuilder
  private func activeCapsule(colors: AppThemeColors) -> some View {
    Group {
      if reduceTransparency {
        Capsule()
          .fill(activeCapsuleSolidFill(colors: colors))
          .overlay {
            Capsule().strokeBorder(
              activeCapsuleStrokeColor(colors: colors),
              lineWidth: LiquidGlass.navSelectionStrokeWidth
            )
          }
      } else {
        Capsule()
          .fill(.clear)
          .glassEffect(.regular.interactive(), in: Capsule())
      }
    }
    .padding(.horizontal, ExpandedNavMetrics.capsuleHorizontalInset)
    .padding(.vertical, ExpandedNavMetrics.capsuleVerticalInset)
    .matchedGeometryEffect(id: "expandedActiveCapsule", in: capsuleNamespace)
  }

  private func activeCapsuleSolidFill(colors: AppThemeColors) -> Color {
    colors.isDark ? colors.surfaceVariant : colors.background
  }

  private func activeCapsuleStrokeColor(colors: AppThemeColors) -> Color {
    if colors.isDark {
      return colors.textPrimary.opacity(LiquidGlass.navBlobStrokeOpacity)
    }
    return colors.textSecondary.opacity(LiquidGlass.navBlobStrokeOpacity * 1.2)
  }

  private var expandedNavAnimation: Animation? {
    if reduceMotion {
      return .easeInOut(duration: 0.2)
    }
    return AppMotion.expandedNavSpring
  }

  // MARK: - Shell glass (paridade BottomNavPill — não recriar tratamento)

  private var glassShellPillBody: some View {
    let c = theme.colors

    return pillContent(colors: c)
      .padding(ChromeLayout.pillInnerPadding)
      .compositingGroup()
      .background {
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
          .allowsHitTesting(false)
      }
  }

  private var solidPillBody: some View {
    let c = theme.colors

    return pillContent(colors: c)
      .padding(ChromeLayout.pillInnerPadding)
      .background {
        pillShape
          .fill(c.navBar)
          .allowsHitTesting(false)
      }
  }
}

// MARK: - Métricas

private enum ExpandedNavMetrics {
  /// Ativo ~2.4× largura de um inativo (mockup C) — ver ExpandedNavLayout.activeWidthMultiplier.
  static let activeWidthMultiplier: CGFloat = ExpandedNavLayout.activeWidthMultiplier
  static let capsuleHorizontalInset: CGFloat = 2
  static let capsuleVerticalInset: CGFloat = 4
  static let iconBoxSize: CGFloat = 24
  static let activeIconLabelSpacing: CGFloat = 6
  static let activeHorizontalPadding: CGFloat = 12
  static let minTouchSize: CGFloat = 44
  static let activeLabelSize: CGFloat = 12
  static let pressScale: CGFloat = 0.96
  static let labelFadeInDelay: TimeInterval = 0.08
  static let labelFadeInDuration: TimeInterval = 0.18
  static let labelFadeOutDuration: TimeInterval = 0.12
}

// MARK: - Item

private struct ExpandedNavItem: View {
  @Environment(MobileChromeController.self) private var chrome
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let tab: NavTab
  let selected: Bool
  let slotWidth: CGFloat
  let colors: AppThemeColors

  @State private var labelOpacity: CGFloat = 0
  @State private var bounceScale: CGFloat = 1

  private var isPressed: Bool { chrome.pressedTab == tab }

  var body: some View {
    Group {
      if selected {
        HStack(spacing: ExpandedNavMetrics.activeIconLabelSpacing) {
          iconView(accent: true)
          Text(tab.label)
            .font(.system(size: ExpandedNavMetrics.activeLabelSize, weight: .semibold))
            .foregroundStyle(colors.accent)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .opacity(labelOpacity)
        }
        .padding(.horizontal, ExpandedNavMetrics.activeHorizontalPadding)
      } else {
        iconView(accent: false)
          .frame(maxWidth: .infinity)
      }
    }
    .frame(width: max(slotWidth, ExpandedNavMetrics.minTouchSize))
    .frame(minHeight: ExpandedNavMetrics.minTouchSize)
    .frame(height: AppLayout.bottomNavPillHeight)
    .scaleEffect(isPressed && !reduceMotion ? ExpandedNavMetrics.pressScale : 1)
    .animation(AppMotion.press(reduceMotion: reduceMotion), value: isPressed)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(tab.label)
    .accessibilityAddTraits(selected ? .isSelected : [])
    .onAppear { syncLabelOpacity(animated: false) }
    .onChange(of: selected) { _, isSelected in
      syncLabelOpacity(animated: true)
      if isSelected { runIconBounce() }
    }
  }

  @ViewBuilder
  private func iconView(accent: Bool) -> some View {
    StackedIcons.icon(
      tab.stackedIcon,
      size: tab.navIconSize,
      color: accent ? colors.accent : colors.textSecondary
    )
    .frame(width: ExpandedNavMetrics.iconBoxSize, height: ExpandedNavMetrics.iconBoxSize)
    .scaleEffect(bounceScale)
  }

  private func syncLabelOpacity(animated: Bool) {
    guard selected else {
      labelOpacity = 0
      return
    }
    if reduceMotion || !animated {
      labelOpacity = 1
      return
    }
    labelOpacity = 0
    withAnimation(.easeIn(duration: ExpandedNavMetrics.labelFadeInDuration).delay(ExpandedNavMetrics.labelFadeInDelay)) {
      labelOpacity = 1
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
