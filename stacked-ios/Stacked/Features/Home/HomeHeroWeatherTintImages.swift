import Foundation

enum HomeHeroWeatherTintImages {
  static func assetName(for style: HomeHeroInsights.WeatherSnapshot.Style, isNight: Bool) -> String {
    if style == .sunny, isNight {
      return "HeroTintWeatherClear"
    }
    switch style {
    case .sunny: return "HeroTintWeatherSunny"
    case .partlyCloudy: return "HeroTintWeatherPartlyCloudy"
    case .cloudy: return "HeroTintWeatherCloudy"
    case .rainy: return "HeroTintWeatherRainy"
    case .stormy: return "HeroTintWeatherStormy"
    case .snowy: return "HeroTintWeatherSnowy"
    case .foggy: return "HeroTintWeatherFoggy"
    case .clear: return "HeroTintWeatherClear"
    }
  }
}
