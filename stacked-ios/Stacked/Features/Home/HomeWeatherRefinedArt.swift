import SwiftUI

/// Ícone de clima refinado — arte monocromática premium com profundidade.
struct HomeWeatherRefinedArt: View {
  @Environment(ThemeManager.self) private var theme

  let style: HomeHeroInsights.WeatherSnapshot.Style
  var isNight: Bool = false

  private let size: CGFloat = 80

  private var imageName: String {
    HomeHeroWeatherRefinedImages.assetName(for: style, isNight: isNight)
  }

  var body: some View {
    let c = theme.colors

    ZStack {
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .fill(c.surfaceVariant)

      Image(imageName)
        .resizable()
        .interpolation(.high)
        .antialiased(true)
        .scaledToFill()
        .frame(width: size, height: size)
        .clipped()
        .accessibilityHidden(true)

      // Vinheta interna — profundidade sutil
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .fill(
          RadialGradient(
            colors: [.clear, c.background.opacity(c.isDark ? 0.35 : 0.2)],
            center: .center,
            startRadius: size * 0.2,
            endRadius: size * 0.72
          )
        )
        .allowsHitTesting(false)

      // Destaque superior (vidro)
      VStack {
        LinearGradient(
          colors: [c.textPrimary.opacity(c.isDark ? 0.07 : 0.05), .clear],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: size * 0.42)
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
              c.textPrimary.opacity(c.isDark ? 0.14 : 0.1),
              c.textPrimary.opacity(c.isDark ? 0.05 : 0.04),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 1
        )
    }
    .shadow(color: c.background.opacity(c.isDark ? 0.45 : 0.12), radius: 8, y: 3)
  }
}
