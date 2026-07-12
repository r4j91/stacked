import Foundation

enum HomeHeroWeatherSceneImages {
  static func assetName(for style: HomeHeroInsights.WeatherSnapshot.Style) -> String {
    switch style {
    case .sunny: "HeroWeatherSunny"
    case .partlyCloudy: "HeroWeatherPartlyCloudy"
    case .cloudy: "HeroWeatherCloudy"
    case .rainy: "HeroWeatherRainy"
    case .stormy: "HeroWeatherStormy"
    case .snowy: "HeroWeatherSnowy"
    case .foggy: "HeroWeatherFoggy"
    case .clear: "HeroWeatherClear"
    }
  }
}
