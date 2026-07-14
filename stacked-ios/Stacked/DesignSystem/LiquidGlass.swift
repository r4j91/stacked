import SwiftUI

// Paridade lib/widgets/responsive_layout.dart _LiquidGlassPill + header_liquid_pill.dart
// FASE1: glass puro iOS 26 — uma camada `.glassEffect(.regular.tint(...))`, sem Material+fill empilhados.
enum LiquidGlass {
  /// Tint leve (~12%) preserva identidade do tema sem matar translucidez.
  static let glassTintOpacity: CGFloat = 0.12

  /// Navbar — shell em glass; blob de seleção é sólido (estilo Todoist, sem halo).
  static let navTrackTintOpacity: CGFloat = 0.12
  /// FAB — tint um pouco mais forte para ler a cor accent através do glass.
  static let fabTintOpacity: CGFloat = 0.48
  /// Borda do shell glass (~textPrimary 6–8%).
  static let navSelectionStrokeOpacity: CGFloat = 0.07
  /// Borda do blob sólido — um pouco mais visível para separar do trilho glass.
  static let navBlobStrokeOpacity: CGFloat = 0.10
  /// Tint do blob glass — mais opaco que o trilho para ler seleção + morph líquido.
  static let navBlobTintOpacity: CGFloat = 0.32
  static let navSelectionStrokeWidth: CGFloat = 0.75
  /// Fill estático no freeze — parece glass pausado, sem amostrar a lista.
  static let frozenTrackOpacity: CGFloat = 0.88

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
    PopoverCardSurface(
      navBarColor: navBarColor,
      cornerRadius: cornerRadius,
      content: content
    )
  }

  /// Chrome estático do popover (glass + stroke + shadow) — sem conteúdo; E2 animação.
  @ViewBuilder
  static func popoverCardChrome(
    navBarColor: Color,
    cornerRadius: CGFloat = PopoverStyle.radius
  ) -> some View {
    PopoverCardSurface(navBarColor: navBarColor, cornerRadius: cornerRadius) {
      Color.clear
    }
  }

  // SUBSTITUIDO_POPOVER_E2: glass+stroke+shadow animavam junto com scale no card inteiro.

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

  /// FAB — glass com tint accent (fallback sólido com reduce transparency).
  @ViewBuilder
  static func fab<Content: View>(
    tintColor: Color,
    solidFallback: Color,
    @ViewBuilder content: () -> Content
  ) -> some View {
    FabGlassSurface(
      tintColor: tintColor,
      solidFallback: solidFallback,
      content: content
    )
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
  @AppStorage(DisableAllGlassStorage.key) private var disableAllGlass = false
  @AppStorage(AlwaysStaticGlassStorage.key) private var alwaysStaticGlass = false

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

  private var useSolid: Bool {
    GlassChromePreference.prefersSolid(
      reduceTransparency: reduceTransparency,
      disableAllGlass: disableAllGlass
    )
  }

  private var useStaticFrozen: Bool {
    GlassChromePreference.prefersStaticFrozen(alwaysStaticGlass: alwaysStaticGlass)
  }

  var body: some View {
    if useSolid {
      content
        .background(shape.fill(navBarColor))
        .clipShape(shape)
    } else if useStaticFrozen {
      // Mesmo look do dock congelado: translúcido, sem glassEffect.
      content
        .background(shape.fill(navBarColor.opacity(LiquidGlass.frozenTrackOpacity)))
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

private struct PopoverCardSurface<Content: View>: View {
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @AppStorage(DisableAllGlassStorage.key) private var disableAllGlass = false
  @AppStorage(AlwaysStaticGlassStorage.key) private var alwaysStaticGlass = false

  let navBarColor: Color
  let cornerRadius: CGFloat
  let content: Content

  init(
    navBarColor: Color,
    cornerRadius: CGFloat,
    @ViewBuilder content: () -> Content
  ) {
    self.navBarColor = navBarColor
    self.cornerRadius = cornerRadius
    self.content = content()
  }

  private var useSolid: Bool {
    GlassChromePreference.prefersSolid(
      reduceTransparency: reduceTransparency,
      disableAllGlass: disableAllGlass
    )
  }

  private var useStaticFrozen: Bool {
    GlassChromePreference.prefersStaticFrozen(alwaysStaticGlass: alwaysStaticGlass)
  }

  private var suppressShadow: Bool { useSolid || useStaticFrozen }

  var body: some View {
    GlassSurface(
      navBarColor: navBarColor,
      shape: RoundedRectangle(cornerRadius: cornerRadius),
      content: { content }
    )
    .overlay {
      RoundedRectangle(cornerRadius: cornerRadius)
        .strokeBorder(Color.white.opacity(PopoverStyle.cardStrokeOpacity), lineWidth: 0.5)
    }
    .shadow(
      color: .black.opacity(suppressShadow ? 0 : PopoverStyle.cardShadowOpacity),
      radius: suppressShadow ? 0 : PopoverStyle.cardShadowRadius,
      y: suppressShadow ? 0 : PopoverStyle.cardShadowY
    )
  }
}

private struct FabGlassSurface<Content: View>: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @AppStorage(DisableAllGlassStorage.key) private var disableAllGlass = false
  @AppStorage(AlwaysStaticGlassStorage.key) private var alwaysStaticGlass = false

  let tintColor: Color
  let solidFallback: Color
  let content: Content

  init(
    tintColor: Color,
    solidFallback: Color,
    @ViewBuilder content: () -> Content
  ) {
    self.tintColor = tintColor
    self.solidFallback = solidFallback
    self.content = content()
  }

  private var subtleBorder: Color {
    theme.colors.textPrimary.opacity(0.08)
  }

  private var useSolid: Bool {
    GlassChromePreference.prefersSolid(
      reduceTransparency: reduceTransparency,
      disableAllGlass: disableAllGlass
    )
  }

  private var useStaticFrozen: Bool {
    GlassChromePreference.prefersStaticFrozen(alwaysStaticGlass: alwaysStaticGlass)
  }

  var body: some View {
    if useSolid {
      content
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Circle().fill(solidFallback))
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(subtleBorder, lineWidth: 0.5))
    } else if useStaticFrozen {
      content
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Circle().fill(tintColor.opacity(LiquidGlass.frozenTrackOpacity)))
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(subtleBorder, lineWidth: 0.5))
    } else {
      content
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
          Circle()
            .fill(.clear)
            .glassEffect(
              .regular.tint(tintColor.opacity(LiquidGlass.fabTintOpacity)),
              in: .circle
            )
            .allowsHitTesting(false)
        }
        .compositingGroup()
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(subtleBorder, lineWidth: 0.5))
    }
  }
}

private struct ToolbarGlassPill<Content: View>: View {
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @AppStorage(DisableAllGlassStorage.key) private var disableAllGlass = false
  @AppStorage(AlwaysStaticGlassStorage.key) private var alwaysStaticGlass = false

  let navBarColor: Color
  let content: Content

  init(navBarColor: Color, @ViewBuilder content: () -> Content) {
    self.navBarColor = navBarColor
    self.content = content()
  }

  private var useSolid: Bool {
    GlassChromePreference.prefersSolid(
      reduceTransparency: reduceTransparency,
      disableAllGlass: disableAllGlass
    )
  }

  private var useStaticFrozen: Bool {
    GlassChromePreference.prefersStaticFrozen(alwaysStaticGlass: alwaysStaticGlass)
  }

  var body: some View {
    let padded = content
      .padding(.horizontal, 14)
      .padding(.vertical, 7)

    if useSolid {
      padded.background(Capsule().fill(navBarColor))
    } else if useStaticFrozen {
      padded.background(Capsule().fill(navBarColor.opacity(LiquidGlass.frozenTrackOpacity)))
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
