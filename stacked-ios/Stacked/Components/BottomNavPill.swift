import SwiftUI

// Navbar mobile — shell glass iOS 26; blob sólido (Todoist) atrás dos ícones + matchedGeometryEffect.
struct BottomNavPill: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(MobileChromeController.self) private var chrome
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @AppStorage(ChromeGlassModeStorage.key) private var chromeGlassModeRaw = ChromeGlassModeStorage.defaultRawValue
  @Binding var selectedTab: NavTab

  @Namespace private var blobNamespace

  private let tabs = NavTab.allCases
  private let indicatorInset: CGFloat = 2
  private let pillShape = RoundedRectangle(cornerRadius: 24)
  private let indicatorCornerRadius: CGFloat = 28

  private var useSolidChrome: Bool {
    GlassChromePreference.prefersSolid(
      reduceTransparency: reduceTransparency,
      mode: ChromeGlassModeStorage.mode(from: chromeGlassModeRaw)
    )
  }

  var body: some View {
    if useSolidChrome {
      solidPillBody
    } else {
      glassShellPillBody
    }
  }

  // MARK: - Blob sólido (sempre atrás dos ícones)

  private func selectionFill(colors: AppThemeColors) -> Color {
    colors.isDark ? colors.surfaceVariant : colors.background
  }

  private func selectionStrokeColor(colors: AppThemeColors) -> Color {
    if colors.isDark {
      return colors.textPrimary.opacity(LiquidGlass.navBlobStrokeOpacity)
    }
    return colors.textSecondary.opacity(LiquidGlass.navBlobStrokeOpacity * 1.2)
  }

  @ViewBuilder
  private func selectionBlob(colors: AppThemeColors) -> some View {
    RoundedRectangle(cornerRadius: indicatorCornerRadius)
      .fill(selectionFill(colors: colors))
      .overlay {
        RoundedRectangle(cornerRadius: indicatorCornerRadius)
          .strokeBorder(
            selectionStrokeColor(colors: colors),
            lineWidth: LiquidGlass.navSelectionStrokeWidth
          )
      }
      .padding(indicatorInset)
      .matchedGeometryEffect(id: "navBlob", in: blobNamespace)
  }

  /// Blob numa camada separada — ícones ficam sempre por cima (glassEffectID cobria os ícones).
  private func pillContent(colors: AppThemeColors) -> some View {
    ZStack {
      HStack(spacing: 0) {
        ForEach(tabs) { tab in
          Color.clear
            .frame(maxWidth: .infinity)
            .background {
              if tab == selectedTab {
                selectionBlob(colors: colors)
              }
            }
        }
      }
      .animation(AppMotion.navMorph(reduceMotion: reduceMotion), value: selectedTab)
      .allowsHitTesting(false)

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
    .frame(height: AppLayout.bottomNavPillHeight)
  }

  // MARK: - Shell glass

  private var glassShellPillBody: some View {
    let c = theme.colors

    return pillContent(colors: c)
      .padding(ChromeLayout.pillInnerPadding)
      .background {
        DockNavTrackShell(shape: pillShape, colors: c)
          .allowsHitTesting(false)
      }
  }

  // MARK: - Fallback sólido (reduce transparency)

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

private enum NavPillMetrics {
  static let iconBoxSize: CGFloat = 24
  static let iconBouncePeak: CGFloat = 1.14
  static let pressScale: CGFloat = 0.96
  static let labelSize: CGFloat = 10.5
  static let labelLineHeight: CGFloat = 1.1
}

private struct NavPillItem: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(MobileChromeController.self) private var chrome
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @AppStorage(AppTypeScaleStorage.key) private var typeScaleRaw = AppTypeScaleStorage.defaultRawValue
  let tab: NavTab
  let selected: Bool

  @State private var bounceScale: CGFloat = 1

  private var isPressed: Bool { chrome.pressedTab == tab }

  var body: some View {
    let c = theme.colors
    let labelHeight = NavPillMetrics.labelSize * NavPillMetrics.labelLineHeight
    let iconColor = selected ? c.accent : c.textSecondary
    let t = AppTypeScaleStorage.scale(from: typeScaleRaw).metrics
    let iconBox = NavPillMetrics.iconBoxSize + t.navIconBoxDelta

    return VStack(spacing: 2) {
      StackedIcons.icon(tab.stackedIcon, size: tab.navIconSize + t.navIconDelta, color: iconColor)
        .frame(width: iconBox, height: iconBox)
        .scaleEffect(bounceScale)
      Text(tab.label)
        .font(selected ? AppTypography.navLabelSelected : AppTypography.navLabel)
        // Dock de altura fixa, com os alvos de toque posicionados no UIKit:
        // o rótulo não pode crescer sem teto. Quem quer navbar maior usa a
        // escala de tipografia do app, que sobe ícone e rótulo junto.
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .foregroundStyle(selected ? c.accent : c.textSecondary)
        .contentTransition(.interpolate)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(height: labelHeight)
    }
    .animation(AppMotion.navMorph(reduceMotion: reduceMotion), value: selected)
    .scaleEffect(isPressed && !reduceMotion ? NavPillMetrics.pressScale : 1)
    .animation(AppMotion.press(reduceMotion: reduceMotion), value: isPressed)
    .frame(maxWidth: .infinity)
    .frame(height: AppLayout.bottomNavPillHeight)
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
      bounceScale = NavPillMetrics.iconBouncePeak
      AppMotion.animate(AppMotion.iconBounceSpring, reduceMotion: reduceMotion) {
        bounceScale = 1
      }
    }
  }
}
