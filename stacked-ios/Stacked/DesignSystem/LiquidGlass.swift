import SwiftUI

// Paridade lib/widgets/responsive_layout.dart _LiquidGlassPill + header_liquid_pill.dart
// FASE1: glass puro iOS 26 — uma camada `.glassEffect(.regular.tint(...))`, sem Material+fill empilhados.
enum LiquidGlass {
  /// Tint leve (~12%) preserva identidade do tema sem matar translucidez.
  static let glassTintOpacity: CGFloat = 0.12

  /// Navbar — shell em glass; blob de seleção é sólido (estilo Todoist, sem halo).
  static let navTrackTintOpacity: CGFloat = 0.12
  /// Borda do blob — paridade Flutter/Todoist (~textPrimary 6–8%).
  static let navSelectionStrokeOpacity: CGFloat = 0.08
  static let navSelectionStrokeWidth: CGFloat = 0.8

  @ViewBuilder
  static func navBarPill<Content: View>(
    navBarColor: Color,
    @ViewBuilder content: () -> Content
  ) -> some View {
    GlassSurface(
      navBarColor: navBarColor,
      shape: RoundedRectangle(cornerRadius: 32),
      content: content
    )
  }

  @ViewBuilder
  static func popoverCard<Content: View>(
    navBarColor: Color,
    cornerRadius: CGFloat = PopoverStyle.radius,
    @ViewBuilder content: () -> Content
  ) -> some View {
    GlassSurface(
      navBarColor: navBarColor,
      shape: RoundedRectangle(cornerRadius: cornerRadius),
      content: content
    )
  }

  @ViewBuilder
  static func headerPill<Content: View>(
    navBarColor: Color,
    textPrimary: Color,
    @ViewBuilder content: () -> Content
  ) -> some View {
    GlassSurface(
      navBarColor: navBarColor,
      shape: Capsule(),
      content: content
    )
  }

  @ViewBuilder
  static func toolbarPill(
    navBarColor: Color,
    textPrimary: Color,
    @ViewBuilder content: () -> some View
  ) -> some View {
    ToolbarGlassPill(navBarColor: navBarColor, content: content)
  }

  /// SUBSTITUIDO_FASE1B: usado pelo Quick Add overlay — substituído por sheet nativo iOS 26.
  // @ViewBuilder
  // static func sheetPanel<Content: View>(
  //   navBarColor: Color,
  //   @ViewBuilder content: () -> Content
  // ) -> some View {
  //   let shape = UnevenRoundedRectangle(
  //     topLeadingRadius: 20,
  //     bottomLeadingRadius: 0,
  //     bottomTrailingRadius: 0,
  //     topTrailingRadius: 20
  //   )
  //   content()
  //     .background {
  //       shape
  //         .fill(navBarColor.opacity(0.82))
  //         .glassEffect(.regular, in: shape)
  //     }
  //     .clipShape(shape)
  // }
}

// MARK: - Superfície glass centralizada (reduce-transparency fallback único)

private struct GlassSurface<S: InsettableShape, Content: View>: View {
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  let navBarColor: Color
  let shape: S
  let content: Content

  init(
    navBarColor: Color,
    shape: S,
    @ViewBuilder content: () -> Content
  ) {
    self.navBarColor = navBarColor
    self.shape = shape
    self.content = content()
  }

  var body: some View {
    if reduceTransparency {
      content
        .background(shape.fill(navBarColor))
        .clipShape(shape)
    } else {
      content
        .background {
          shape
            .fill(.clear)
            .glassEffect(
              .regular.tint(navBarColor.opacity(LiquidGlass.glassTintOpacity)),
              in: shape
            )
            .allowsHitTesting(false)
        }
        .clipShape(shape)
    }
  }
}

private struct ToolbarGlassPill<Content: View>: View {
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  let navBarColor: Color
  let content: Content

  init(navBarColor: Color, @ViewBuilder content: () -> Content) {
    self.navBarColor = navBarColor
    self.content = content()
  }

  var body: some View {
    let padded = content
      .padding(.horizontal, 14)
      .padding(.vertical, 7)

    if reduceTransparency {
      padded.background(Capsule().fill(navBarColor))
    } else {
      padded.glassEffect(
        .regular.tint(navBarColor.opacity(LiquidGlass.glassTintOpacity)),
        in: .capsule
      )
    }
  }
}

// MARK: - SUBSTITUIDO_FASE1 (referência — fallback iOS 17–25 e empilhamento Material+fill)
//
// private static let navFillOpacity: CGFloat = 0.52
// private static let popoverFillOpacity: CGFloat = 0.78
//
// navBarPill (legado):
//   ZStack { shape.fill(.ultraThinMaterial); shape.fill(navBarColor.opacity(navFillOpacity)) }
//   .overlay(shape.stroke(Color.white.opacity(0.08), lineWidth: 0.8))
//   .clipShape(shape)
//   .shadow(color: .black.opacity(0.28), radius: 24, y: 10)  // SUBSTITUIDO_FASE1
//
// popoverCard (legado):
//   idem + .overlay(shape.stroke(Color.white.opacity(0.12), lineWidth: 0.8))  // SUBSTITUIDO_FASE1
//
// headerPill / toolbarPill (legado):
//   Material + fill(0.55) + stroke textPrimary.opacity(0.06–0.08)

struct GlassPillButton<Content: View>: View {
  @Environment(ThemeManager.self) private var theme
  let action: () -> Void
  @ViewBuilder var content: () -> Content

  var body: some View {
    let c = theme.colors
    Button(action: action) {
      LiquidGlass.toolbarPill(navBarColor: c.surfaceVariant, textPrimary: c.textPrimary) {
        content()
      }
    }
    .buttonStyle(.plain)
  }
}
