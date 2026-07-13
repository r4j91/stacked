import CoreLocation
import Foundation

@MainActor
final class HomeWeatherService: NSObject {
  static let shared = HomeWeatherService()

  private let manager = CLLocationManager()
  private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
  private var cachedSnapshot: HomeHeroInsights.WeatherSnapshot?
  private var cacheExpiry: Date?

  private static let persistedSnapshotKey = "homeWeatherPersistedSnapshot"
  private static let persistedExpiryKey = "homeWeatherPersistedExpiry"

  private override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyKilometer
    restorePersistedCache()
  }

  /// Snapshot síncrono para evitar flash de placeholder na abertura.
  func startupSnapshot(fallbackTimeOfDay: HomeTimeOfDay) -> HomeHeroInsights.WeatherSnapshot {
    if let cachedSnapshot, let cacheExpiry, cacheExpiry > Date() {
      return cachedSnapshot
    }
    return HomeHeroInsights.placeholderWeather(for: fallbackTimeOfDay)
  }

  func snapshot(fallbackTimeOfDay: HomeTimeOfDay) async -> HomeHeroInsights.WeatherSnapshot {
    if let cachedSnapshot, let cacheExpiry, cacheExpiry > Date() {
      return cachedSnapshot
    }

    guard let location = await requestLocation(timeout: 5) else {
      return cachedSnapshot ?? HomeHeroInsights.placeholderWeather(for: fallbackTimeOfDay)
    }

    let resolved = await fetchOpenMeteo(location: location)
      ?? cachedSnapshot
      ?? HomeHeroInsights.placeholderWeather(for: fallbackTimeOfDay)

    storeCache(resolved)
    return resolved
  }

  private func storeCache(_ snapshot: HomeHeroInsights.WeatherSnapshot) {
    cachedSnapshot = snapshot
    let expiry = Date().addingTimeInterval(15 * 60)
    cacheExpiry = expiry
    persistCache(snapshot: snapshot, expiry: expiry)
  }

  private func restorePersistedCache() {
    guard
      let data = UserDefaults.standard.data(forKey: Self.persistedSnapshotKey),
      let snapshot = try? JSONDecoder().decode(HomeHeroInsights.WeatherSnapshot.self, from: data)
    else { return }

    let expiry = UserDefaults.standard.object(forKey: Self.persistedExpiryKey) as? Date
    guard let expiry, expiry > Date() else {
      clearPersistedCache()
      return
    }

    cachedSnapshot = snapshot
    cacheExpiry = expiry
  }

  private func persistCache(snapshot: HomeHeroInsights.WeatherSnapshot, expiry: Date) {
    guard let data = try? JSONEncoder().encode(snapshot) else { return }
    UserDefaults.standard.set(data, forKey: Self.persistedSnapshotKey)
    UserDefaults.standard.set(expiry, forKey: Self.persistedExpiryKey)
  }

  private func clearPersistedCache() {
    UserDefaults.standard.removeObject(forKey: Self.persistedSnapshotKey)
    UserDefaults.standard.removeObject(forKey: Self.persistedExpiryKey)
  }

  private func requestLocation(timeout seconds: TimeInterval) async -> CLLocation? {
    await withTaskGroup(of: CLLocation?.self) { group in
      group.addTask { @MainActor in
        await self.requestLocation()
      }
      group.addTask {
        let ns = UInt64(max(seconds, 0.1) * 1_000_000_000)
        try? await _Concurrency.Task.sleep(nanoseconds: ns)
        return nil
      }
      let result = await group.next() ?? nil
      group.cancelAll()
      locationContinuation?.resume(returning: nil)
      locationContinuation = nil
      return result
    }
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
