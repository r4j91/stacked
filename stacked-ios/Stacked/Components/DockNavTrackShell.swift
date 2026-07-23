import SwiftUI

/// Trilho do dock: glass ao vivo, quieto, fosco ou sólido.
///
/// Resolve o modo aqui (não na NavBar pai) — troca de preferência só re-renderiza o shell.
struct DockNavTrackShell<S: InsettableShape>: View {
  let shape: S
  let colors: AppThemeColors

  @Environment(MobileChromeController.self) private var chrome
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @AppStorage(ChromeGlassModeStorage.key) private var chromeGlassModeRaw = ChromeGlassModeStorage.defaultRawValue

  private var chromeMode: ChromeGlassMode {
    ChromeGlassModeStorage.mode(from: chromeGlassModeRaw)
  }

  private var mode: DockGlassMode {
    chrome.dockGlassMode(
      reduceTransparency: reduceTransparency,
      mode: chromeMode
    )
  }

  var body: some View {
    switch mode {
    case .solid:
      shape.fill(colors.navBar)
    case .live:
      liveGlassLayer
    case .frozen:
      if chromeMode == .frosted {
        frostedFillLayer
      } else {
        frozenFillLayer
      }
    }
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

  private var frostedFillLayer: some View {
    LiquidGlass.frostedFill(shape: shape, tint: colors.navBar)
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
