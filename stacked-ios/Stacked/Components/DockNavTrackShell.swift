import SwiftUI

/// Trilho do dock: glass ao vivo, congelado no scroll, ou sólido (reduce transparency).
struct DockNavTrackShell<S: InsettableShape>: View {
  let shape: S
  let colors: AppThemeColors
  let mode: DockGlassMode
  @AppStorage(DockGlassFreezeLegacyStorage.key) private var useLegacySwitch = false
  @AppStorage(AlwaysFrozenDockGlassStorage.key) private var alwaysFrozenDockGlass = false

  var body: some View {
    switch mode {
    case .solid:
      shape.fill(colors.navBar)
    case .live, .frozen:
      // Preferência "sempre estático": só o fill — sem montar glassEffect.
      if alwaysFrozenDockGlass {
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
