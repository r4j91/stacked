import SwiftUI

/// Ícone de clima em relevo/escultura — estilo clay neumórfico no squircle escuro.
struct HomeWeatherSculptArt: View {
  @Environment(ThemeManager.self) private var theme

  let style: HomeHeroInsights.WeatherSnapshot.Style
  var isNight: Bool = false
  var size: CGFloat = 80

  private var cornerRadius: CGFloat { size * 0.25 }

  private var imageName: String {
    HomeHeroWeatherSculptImages.assetName(for: style.resolved(isNight: isNight), isNight: isNight)
  }

  private var accent: Color {
    style.resolved(isNight: isNight).tintAccent
  }

  var body: some View {
    let c = theme.colors

    ZStack {
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(c.surfaceVariant)

      RadialGradient(
        colors: [accent.opacity(c.isDark ? 0.12 : 0.08), .clear],
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

      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(
          RadialGradient(
            colors: [.clear, c.background.opacity(c.isDark ? 0.26 : 0.14)],
            center: .init(x: 0.5, y: 0.62),
            startRadius: size * 0.15,
            endRadius: size * 0.78
          )
        )
        .allowsHitTesting(false)

      VStack {
        LinearGradient(
          colors: [c.textPrimary.opacity(c.isDark ? 0.07 : 0.05), .clear],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: size * 0.4)
        Spacer(minLength: 0)
      }
      .allowsHitTesting(false)
    }
    .frame(width: size, height: size)
    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .strokeBorder(
          LinearGradient(
            colors: [
              accent.opacity(c.isDark ? 0.2 : 0.14),
              c.textPrimary.opacity(c.isDark ? 0.06 : 0.04),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 1
        )
    }
    .shadow(color: accent.opacity(c.isDark ? 0.1 : 0.07), radius: size > 90 ? 14 : 10, y: size > 90 ? 5 : 4)
    .shadow(color: c.background.opacity(c.isDark ? 0.32 : 0.1), radius: 6, y: 2)
  }
}
