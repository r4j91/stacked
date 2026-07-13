import Foundation

enum HomeHeroWeatherSculptImages {
  static func assetName(
    for style: HomeHeroInsights.WeatherSnapshot.Style,
    isNight: Bool
  ) -> String {
    let resolved = style.resolved(isNight: isNight)
    if resolved == .clear || (style == .sunny && isNight) {
      return "HeroSculptWeatherClear"
    }
    switch resolved {
    case .sunny: return "HeroSculptWeatherSunny"
    case .partlyCloudy: return "HeroSculptWeatherPartlyCloudy"
    case .cloudy: return "HeroSculptWeatherCloudy"
    case .rainy: return "HeroSculptWeatherRainy"
    case .stormy: return "HeroSculptWeatherStormy"
    case .snowy: return "HeroSculptWeatherSnowy"
    case .foggy: return "HeroSculptWeatherFoggy"
    case .clear: return "HeroSculptWeatherClear"
    }
  }
}
