import Foundation

enum HomeHeroWeatherRefinedImages {
  static func assetName(for style: HomeHeroInsights.WeatherSnapshot.Style, isNight: Bool) -> String {
    if style == .sunny, isNight {
      return "HeroRefinedWeatherClear"
    }
    switch style {
    case .sunny: return "HeroRefinedWeatherSunny"
    case .partlyCloudy: return "HeroRefinedWeatherPartlyCloudy"
    case .cloudy: return "HeroRefinedWeatherCloudy"
    case .rainy: return "HeroRefinedWeatherRainy"
    case .stormy: return "HeroRefinedWeatherStormy"
    case .snowy: return "HeroRefinedWeatherSnowy"
    case .foggy: return "HeroRefinedWeatherFoggy"
    case .clear: return "HeroRefinedWeatherClear"
    }
  }
}
