import SwiftUI

/// Fase 1 — barra clássica. Fase 4 CORREÇÃO — esqueleto BottomNavPill + lente glass.
struct ClassicNavBar: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @Binding var selectedTab: NavTab

  @Namespace private var blobNamespace
  @Namespace private var glassNamespace

  private let tabs = NavTab.allCases
  private let indicatorInset: CGFloat = ClassicNavGlassLayout.indicatorInset
  private let pillShape = RoundedRectangle(cornerRadius: 32)
  private let indicatorCornerRadius: CGFloat = ClassicNavGlassLayout.indicatorCornerRadius

  var body: some View {
    if reduceTransparency {
      solidPillBody
    } else {
      glassShellPillBody
    }
  }

  // MARK: - Indicador (lente glass ou blob sólido em reduce transparency)

  private func selectionFill(colors: AppThemeColors) -> Color {
    colors.isDark ? colors.surfaceVariant : colors.background
  }

  private func selectionStrokeColor(colors: AppThemeColors) -> Color {
    if colors.isDark {
      return colors.textPrimary.opacity(LiquidGlass.navBlobStrokeOpacity)
    }
    return colors.textSecondary.opacity(LiquidGlass.navBlobStrokeOpacity * 1.2)
  }

  /// Blob sólido — fallback reduce transparency (paridade BottomNavPill).
  @ViewBuilder
  private func selectionBlobSolid(colors: AppThemeColors) -> some View {
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
      .matchedGeometryEffect(id: ClassicNavGlassLayout.blobGeometryID, in: blobNamespace)
  }

  @ViewBuilder
  private func selectionIndicator(colors: AppThemeColors) -> some View {
    if reduceTransparency {
      selectionBlobSolid(colors: colors)
    } else {
      ClassicNavBarGlassIndicator(
        morphEnabled: ClassicNavGlassPhase.morphEnabled,
        blobNamespace: blobNamespace,
        glassNamespace: glassNamespace
      )
    }
  }

  /// Camada 2 — indicador isolado (GlassEffectContainer só aqui na Etapa 2).
  @ViewBuilder
  private func indicatorLayer(colors: AppThemeColors) -> some View {
    // AJUSTADO_SPACING_CORRECAO
    let row = HStack(spacing: 1) {
      ForEach(tabs) { tab in
        Color.clear
          .frame(maxWidth: .infinity)
          .background {
            if tab == selectedTab {
              selectionIndicator(colors: colors)
            }
          }
      }
    }
    .animation(indicatorLayerAnimation, value: selectedTab)
    .allowsHitTesting(false)

    if ClassicNavGlassPhase.morphEnabled, !reduceTransparency {
      GlassEffectContainer(spacing: ClassicNavGlassLayout.containerSpacing) {
        row
      }
    } else {
      row
    }
  }

  private var indicatorLayerAnimation: Animation? {
    if reduceMotion {
      return .easeInOut(duration: 0.2)
    }
    if ClassicNavGlassPhase.morphEnabled {
      return .bouncy(duration: 0.45)
    }
    return AppMotion.navMorph(reduceMotion: false)
  }

  /// Esqueleto comprovado BottomNavPill: indicador abaixo, ícones acima.
  private func pillContent(colors: AppThemeColors) -> some View {
    ZStack {
      indicatorLayer(colors: colors)

      HStack(spacing: 0) {
        ForEach(tabs) { tab in
          ClassicNavPillItem(
            tab: tab,
            selected: tab == selectedTab
          )
          .frame(maxWidth: .infinity)
        }
      }
    }
    .frame(height: AppLayout.bottomNavPillHeight)
  }

  // MARK: - Shell glass (trilho — paridade BottomNavPill)

  private var glassShellPillBody: some View {
    let c = theme.colors

    return pillContent(colors: c)
      .padding(ChromeLayout.pillInnerPadding)
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

// MARK: - Fase 4 gating

private enum ClassicNavGlassPhase {
  /// Etapa 1 (CORREÇÃO): `false` — lente + matchedGeometryEffect, sem container/id morph.
  /// Etapa 2: `true` — GlassEffectContainer só na camada do indicador + glassEffectID.
  // SUBSTITUIDO_A1_ETAPA1 — static let morphEnabled = true
  static let morphEnabled = false
}

// MARK: - Item de aba (paridade BottomNavPill / NavPillItem)

private enum ClassicNavPillMetrics {
  static let iconBoxSize: CGFloat = 24
  static let iconBouncePeak: CGFloat = 1.14
  static let pressScale: CGFloat = 0.96
  static let labelSize: CGFloat = 10.5
  static let labelLineHeight: CGFloat = 1.1
}

private struct ClassicNavPillItem: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(MobileChromeController.self) private var chrome
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let tab: NavTab
  let selected: Bool

  @State private var bounceScale: CGFloat = 1

  private var isPressed: Bool { chrome.pressedTab == tab }

  var body: some View {
    let c = theme.colors
    let labelHeight = ClassicNavPillMetrics.labelSize * ClassicNavPillMetrics.labelLineHeight
    let iconColor = selected ? c.accent : c.textSecondary

    VStack(spacing: 2) {
      StackedIcons.icon(tab.stackedIcon, size: tab.navIconSize, color: iconColor)
        .frame(width: ClassicNavPillMetrics.iconBoxSize, height: ClassicNavPillMetrics.iconBoxSize)
        .scaleEffect(bounceScale)
      Text(tab.label)
        .font(selected ? AppTypography.navLabelSelected : AppTypography.navLabel)
        .foregroundStyle(selected ? c.accent : c.textSecondary)
        .contentTransition(.interpolate)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(height: labelHeight)
    }
    .animation(AppMotion.navMorph(reduceMotion: reduceMotion), value: selected)
    .scaleEffect(isPressed && !reduceMotion ? ClassicNavPillMetrics.pressScale : 1)
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
      bounceScale = ClassicNavPillMetrics.iconBouncePeak
      AppMotion.animate(AppMotion.iconBounceSpring, reduceMotion: reduceMotion) {
        bounceScale = 1
      }
    }
  }
}

// SUBSTITUIDO_FASE1 — composição direta sem lente glass:
// struct ClassicNavBar: View {
//   @Binding var selectedTab: NavTab
//   var body: some View { BottomNavPill(selectedTab: $selectedTab) }
// }

// SUBSTITUIDO_CORRECAO — reescrita Fase 4 (glassEffectID/container envolvendo ZStack inteiro,
// matchedGeometryEffect ausente, animação .bouncy condicional):
// - pillContentInner com GlassEffectContainer { ZStack { blob + ícones } }
// - activeTabIndicator sem matchedGeometryEffect(id: "navBlob")
// - tabSelectionAnimation: nil / .bouncy(0.45) em vez de AppMotion.navMorph
