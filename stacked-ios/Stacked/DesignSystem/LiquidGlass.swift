import SwiftUI

// Paridade lib/widgets/responsive_layout.dart _LiquidGlassPill + header_liquid_pill.dart
enum LiquidGlass {
  @ViewBuilder
  static func navBarPill<Content: View>(
    navBarColor: Color,
    @ViewBuilder content: () -> Content
  ) -> some View {
    let shape = RoundedRectangle(cornerRadius: 32)
    if #available(iOS 26.0, *) {
      content()
        .background {
          shape
            .fill(navBarColor.opacity(0.88))
            .glassEffect(.regular, in: shape)
        }
        .clipShape(shape)
    } else {
      content()
        .background {
          ZStack {
            shape.fill(.ultraThinMaterial)
            shape.fill(navBarColor.opacity(0.88))
          }
          .overlay(shape.stroke(Color.white.opacity(0.06), lineWidth: 0.8))
        }
        .clipShape(shape)
    }
  }

  @ViewBuilder
  static func headerPill<Content: View>(
    navBarColor: Color,
    textPrimary: Color,
    @ViewBuilder content: () -> Content
  ) -> some View {
    let shape = Capsule()
    if #available(iOS 26.0, *) {
      content()
        .background {
          shape
            .fill(navBarColor.opacity(0.88))
            .glassEffect(.regular, in: shape)
        }
        .clipShape(shape)
    } else {
      content()
        .background {
          ZStack {
            shape.fill(.ultraThinMaterial)
            shape.fill(navBarColor.opacity(0.88))
          }
          .overlay(shape.stroke(textPrimary.opacity(0.06), lineWidth: 0.8))
        }
        .clipShape(shape)
    }
  }

  @ViewBuilder
  static func toolbarPill(
    navBarColor: Color,
    textPrimary: Color,
    @ViewBuilder content: () -> some View
  ) -> some View {
    if #available(iOS 26.0, *) {
      content()
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background {
          Capsule()
            .fill(navBarColor.opacity(0.55))
            .glassEffect(.regular, in: .capsule)
        }
    } else {
      content()
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background {
          ZStack {
            Capsule().fill(.ultraThinMaterial)
            Capsule().fill(navBarColor.opacity(0.55))
          }
          .overlay(Capsule().stroke(textPrimary.opacity(0.08), lineWidth: 0.8))
        }
    }
  }

  @ViewBuilder
  static func sheetPanel<Content: View>(
    navBarColor: Color,
    @ViewBuilder content: () -> Content
  ) -> some View {
    let shape = UnevenRoundedRectangle(
      topLeadingRadius: 20,
      bottomLeadingRadius: 0,
      bottomTrailingRadius: 0,
      topTrailingRadius: 20
    )
    if #available(iOS 26.0, *) {
      content()
        .background {
          shape
            .fill(navBarColor.opacity(0.82))
            .glassEffect(.regular, in: shape)
        }
        .clipShape(shape)
    } else {
      content()
        .background {
          ZStack {
            shape.fill(.ultraThinMaterial)
            shape.fill(navBarColor.opacity(0.82))
          }
        }
        .clipShape(shape)
    }
  }
}

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
