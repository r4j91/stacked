import SwiftUI

/// Ícone de clima minimalista — arte raster estilo !Weather.
struct HomeWeatherMinimalArt: View {
  @Environment(ThemeManager.self) private var theme

  let style: HomeHeroInsights.WeatherSnapshot.Style
  var isNight: Bool = false

  private let size: CGFloat = 76

  private var imageName: String {
    HomeHeroWeatherMinimalImages.assetName(for: style, isNight: isNight)
  }

  var body: some View {
    let c = theme.colors

    ZStack {
      Image(imageName)
        .resizable()
        .interpolation(.high)
        .antialiased(true)
        .scaledToFill()
        .frame(width: size, height: size)
        .clipped()
        .accessibilityHidden(true)

      // Destaque superior sutil (vidro) — integra com o card escuro
      VStack {
        LinearGradient(
          colors: [c.textPrimary.opacity(c.isDark ? 0.05 : 0.04), .clear],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: size * 0.38)
        Spacer(minLength: 0)
      }
      .allowsHitTesting(false)
    }
    .frame(width: size, height: size)
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .strokeBorder(c.textPrimary.opacity(c.isDark ? 0.08 : 0.06), lineWidth: 1)
    }
  }
}
