import Foundation

enum HomeHeroWeatherMinimalImages {
  static func assetName(for style: HomeHeroInsights.WeatherSnapshot.Style, isNight: Bool) -> String {
    if style == .sunny, isNight {
      return "HeroMinimalWeatherClear"
    }
    switch style {
    case .sunny: return "HeroMinimalWeatherSunny"
    case .partlyCloudy: return "HeroMinimalWeatherPartlyCloudy"
    case .cloudy: return "HeroMinimalWeatherCloudy"
    case .rainy: return "HeroMinimalWeatherRainy"
    case .stormy: return "HeroMinimalWeatherStormy"
    case .snowy: return "HeroMinimalWeatherSnowy"
    case .foggy: return "HeroMinimalWeatherFoggy"
    case .clear: return "HeroMinimalWeatherClear"
    }
  }
}
