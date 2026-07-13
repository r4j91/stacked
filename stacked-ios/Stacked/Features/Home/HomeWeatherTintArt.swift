import SwiftUI

/// Ícone de clima refinado com tom de cor sutil — sombras suaves, detalhes premium.
struct HomeWeatherTintArt: View {
  @Environment(ThemeManager.self) private var theme

  let style: HomeHeroInsights.WeatherSnapshot.Style
  var isNight: Bool = false

  private let size: CGFloat = 80

  private var imageName: String {
    HomeHeroWeatherTintImages.assetName(for: style.resolved(isNight: isNight), isNight: isNight)
  }

  private var accent: Color {
    style.resolved(isNight: isNight).tintAccent
  }

  var body: some View {
    let c = theme.colors

    ZStack {
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .fill(c.surfaceVariant)

      // Bloom de cor bem sutil atrás do ícone
      RadialGradient(
        colors: [accent.opacity(c.isDark ? 0.14 : 0.1), .clear],
        center: .center,
        startRadius: 4,
        endRadius: size * 0.55
      )
      .allowsHitTesting(false)

      Image(imageName)
        .resizable()
        .interpolation(.high)
        .antialiased(true)
        .scaledToFill()
        .frame(width: size, height: size)
        .clipped()
        .accessibilityHidden(true)

      // Sombra interna suave
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .fill(
          RadialGradient(
            colors: [.clear, c.background.opacity(c.isDark ? 0.28 : 0.16)],
            center: .init(x: 0.5, y: 0.62),
            startRadius: size * 0.15,
            endRadius: size * 0.78
          )
        )
        .allowsHitTesting(false)

      // Destaque superior (vidro)
      VStack {
        LinearGradient(
          colors: [c.textPrimary.opacity(c.isDark ? 0.08 : 0.06), .clear],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: size * 0.4)
        Spacer(minLength: 0)
      }
      .allowsHitTesting(false)
    }
    .frame(width: size, height: size)
    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .strokeBorder(
          LinearGradient(
            colors: [
              accent.opacity(c.isDark ? 0.22 : 0.16),
              c.textPrimary.opacity(c.isDark ? 0.06 : 0.04),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 1
        )
    }
    .shadow(color: accent.opacity(c.isDark ? 0.12 : 0.08), radius: 10, y: 4)
    .shadow(color: c.background.opacity(c.isDark ? 0.35 : 0.1), radius: 6, y: 2)
  }
}
