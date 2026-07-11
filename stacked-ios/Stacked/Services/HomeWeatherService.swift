import CoreLocation
import Foundation

@MainActor
final class HomeWeatherService: NSObject {
  static let shared = HomeWeatherService()

  private let manager = CLLocationManager()
  private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
  private var cachedSnapshot: HomeHeroInsights.WeatherSnapshot?
  private var cacheExpiry: Date?

  private override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyKilometer
  }

  func snapshot(fallbackTimeOfDay: HomeTimeOfDay) async -> HomeHeroInsights.WeatherSnapshot {
    if let cachedSnapshot, let cacheExpiry, cacheExpiry > Date() {
      return cachedSnapshot
    }

    guard let location = await requestLocation() else {
      return HomeHeroInsights.placeholderWeather(for: fallbackTimeOfDay)
    }

    let resolved = await fetchOpenMeteo(location: location)
      ?? HomeHeroInsights.placeholderWeather(for: fallbackTimeOfDay)

    cachedSnapshot = resolved
    cacheExpiry = Date().addingTimeInterval(30 * 60)
    return resolved
  }

  private func requestLocation() async -> CLLocation? {
    switch manager.authorizationStatus {
    case .notDetermined:
      return await withCheckedContinuation { continuation in
        locationContinuation = continuation
        manager.requestWhenInUseAuthorization()
      }
    case .authorizedWhenInUse, .authorizedAlways:
      return await withCheckedContinuation { continuation in
        locationContinuation = continuation
        manager.requestLocation()
      }
    default:
      return nil
    }
  }

  private func fetchOpenMeteo(location: CLLocation) async -> HomeHeroInsights.WeatherSnapshot? {
    let lat = location.coordinate.latitude
    let lon = location.coordinate.longitude
    var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
    components.queryItems = [
      URLQueryItem(name: "latitude", value: String(lat)),
      URLQueryItem(name: "longitude", value: String(lon)),
      URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m"),
      URLQueryItem(name: "wind_speed_unit", value: "kmh"),
      URLQueryItem(name: "timezone", value: "auto"),
    ]
    guard let url = components.url else { return nil }

    do {
      let (data, response) = try await URLSession.shared.data(from: url)
      guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
      let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
      let style = HomeHeroInsights.style(fromWMOCode: decoded.current.weather_code)
      return HomeHeroInsights.WeatherSnapshot(
        temperatureC: Int(decoded.current.temperature_2m.rounded()),
        condition: HomeHeroInsights.portugueseCondition(for: style),
        windKmh: Int(decoded.current.wind_speed_10m.rounded()),
        humidityPercent: decoded.current.relative_humidity_2m,
        style: style,
        isLive: true
      )
    } catch {
      return nil
    }
  }
}

extension HomeWeatherService: CLLocationManagerDelegate {
  nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    _Concurrency.Task { @MainActor in
      let status = manager.authorizationStatus
      if status == .authorizedWhenInUse || status == .authorizedAlways {
        manager.requestLocation()
      } else if status == .denied || status == .restricted {
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
      }
    }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    _Concurrency.Task { @MainActor in
      locationContinuation?.resume(returning: locations.first)
      locationContinuation = nil
    }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    _Concurrency.Task { @MainActor in
      locationContinuation?.resume(returning: nil)
      locationContinuation = nil
    }
  }
}

private struct OpenMeteoResponse: Decodable {
  struct Current: Decodable {
    let temperature_2m: Double
    let relative_humidity_2m: Int
    let weather_code: Int
    let wind_speed_10m: Double
  }

  let current: Current
}
