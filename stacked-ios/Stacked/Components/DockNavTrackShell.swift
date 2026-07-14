import SwiftUI

/// Trilho do dock: glass ao vivo, congelado no scroll, ou sólido (reduce transparency).
///
/// Resolve `mode` aqui (não na NavBar pai) — no 1º frame do scroll só este shell
/// reage a `isContentScrolling`, sem re-renderizar ícones/itens da navbar.
struct DockNavTrackShell<S: InsettableShape>: View {
  let shape: S
  let colors: AppThemeColors

  @Environment(MobileChromeController.self) private var chrome
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @AppStorage(FreezeDockGlassWhileScrollingStorage.key) private var freezeDockGlassWhileScrolling = true
  @AppStorage(AlwaysFrozenDockGlassStorage.key) private var alwaysFrozenDockGlass = false
  @AppStorage(AlwaysStaticGlassStorage.key) private var alwaysStaticGlass = false
  @AppStorage(DisableAllGlassStorage.key) private var disableAllGlass = false
  @AppStorage(DockGlassFreezeLegacyStorage.key) private var useLegacySwitch = false

  private var mode: DockGlassMode {
    chrome.dockGlassMode(
      reduceTransparency: reduceTransparency,
      freezeWhileScrolling: freezeDockGlassWhileScrolling,
      alwaysFrozen: alwaysFrozenDockGlass,
      disableAllGlass: disableAllGlass,
      alwaysStaticGlass: alwaysStaticGlass
    )
  }

  private var useFrozenOnly: Bool {
    alwaysFrozenDockGlass || alwaysStaticGlass
  }

  var body: some View {
    switch mode {
    case .solid:
      shape.fill(colors.navBar)
    case .live, .frozen:
      // Preferência "sempre estático": só o fill — sem montar glassEffect.
      if useFrozenOnly {
        frozenFillLayer
      } else if useLegacyPath {
        legacySwitchBody
      } else {
        opacityFlipBody
      }
    }
  }

  /// PERF_FASEB3_3A — path legado (switch destrói glassEffect no freeze).
  private var useLegacyPath: Bool {
    useLegacySwitch || !DockGlassFreezePhase.opacityFlipEnabled
  }

  @ViewBuilder
  private var legacySwitchBody: some View {
    // PERF_FASEB3_3A — comportamento pré-fix (teardown no gesto).
    switch mode {
    case .live:
      liveGlassLayer
    case .frozen:
      frozenFillLayer
    case .solid:
      shape.fill(colors.navBar)
    }
  }

  /// PERF_FASEB3_3A — ambos os layers sempre montados; só opacity muda (corte seco).
  private var opacityFlipBody: some View {
    ZStack {
      frozenFillLayer
        .opacity(mode == .frozen ? 1 : 0)
      liveGlassLayer
        .opacity(mode == .live ? 1 : 0)
    }
    .transaction { $0.disablesAnimations = true }
  }

  private var liveGlassLayer: some View {
    shape
      .fill(.clear)
      .glassEffect(
        .regular.tint(colors.navBar.opacity(LiquidGlass.navTrackTintOpacity)),
        in: shape
      )
      .clipShape(shape)
      .overlay {
        shape.strokeBorder(
          colors.textPrimary.opacity(LiquidGlass.navSelectionStrokeOpacity),
          lineWidth: LiquidGlass.navSelectionStrokeWidth
        )
      }
  }

  private var frozenFillLayer: some View {
    shape
      .fill(colors.navBar.opacity(LiquidGlass.frozenTrackOpacity))
      .overlay {
        shape.strokeBorder(
          colors.textPrimary.opacity(LiquidGlass.navSelectionStrokeOpacity),
          lineWidth: LiquidGlass.navSelectionStrokeWidth
        )
      }
  }
}
