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
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(c.surfaceVariant.opacity(c.isDark ? 0.55 : 0.7))

      Image(imageName)
        .resizable()
        .interpolation(.high)
        .antialiased(true)
        .scaledToFill()
        .frame(width: size, height: size)
        .clipped()
        .accessibilityHidden(true)

      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(
          RadialGradient(
            colors: [.clear, c.background.opacity(c.isDark ? 0.18 : 0.1)],
            center: .center,
            startRadius: size * 0.25,
            endRadius: size * 0.75
          )
        )
        .allowsHitTesting(false)

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
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .strokeBorder(c.textPrimary.opacity(c.isDark ? 0.07 : 0.06), lineWidth: 0.5)
    }
  }
}
