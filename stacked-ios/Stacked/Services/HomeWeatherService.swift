import CoreLocation
import Foundation

@MainActor
final class HomeWeatherService: NSObject {
  static let shared = HomeWeatherService()

  private let manager = CLLocationManager()
  private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
  private var authorizationContinuation: CheckedContinuation<Bool, Never>?
  private var cachedSnapshot: HomeHeroInsights.WeatherSnapshot?
  private var cacheExpiry: Date?

  private var didRequestAuthorization = false

  private static let persistedSnapshotKey = "homeWeatherPersistedSnapshot"
  private static let persistedExpiryKey = "homeWeatherPersistedExpiry"
  private static let persistedLatitudeKey = "homeWeatherPersistedLatitude"
  private static let persistedLongitudeKey = "homeWeatherPersistedLongitude"
  private static let persistedLocationDateKey = "homeWeatherPersistedLocationDate"

  private static let cacheInterval: TimeInterval = 30 * 60
  private static let persistedLocationMaxAge: TimeInterval = 7 * 24 * 60 * 60
  private static let recentManagerLocationMaxAge: TimeInterval = 20 * 60
  private static let locationFixTimeout: TimeInterval = 8

  private override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyKilometer
    restorePersistedCache()
  }

  var needsRefresh: Bool {
    guard let cacheExpiry else { return true }
    return cacheExpiry <= Date()
  }

  /// Snapshot síncrono para evitar flash de placeholder na abertura.
  func startupSnapshot(fallbackTimeOfDay: HomeTimeOfDay) -> HomeHeroInsights.WeatherSnapshot {
    if let cachedSnapshot, let cacheExpiry, cacheExpiry > Date() {
      return cachedSnapshot
    }
    return HomeHeroInsights.placeholderWeather(for: fallbackTimeOfDay)
  }

  /// Atualiza o clima apenas quando o cache expirou — ideal para foreground/appear.
  func refreshIfStale(fallbackTimeOfDay: HomeTimeOfDay) async -> HomeHeroInsights.WeatherSnapshot? {
    guard needsRefresh else { return nil }
    return await snapshot(fallbackTimeOfDay: fallbackTimeOfDay)
  }

  func snapshot(fallbackTimeOfDay: HomeTimeOfDay) async -> HomeHeroInsights.WeatherSnapshot {
    if let cachedSnapshot, let cacheExpiry, cacheExpiry > Date() {
      return cachedSnapshot
    }

    if let location = await resolveLocation() {
      persistCoordinates(location)
      if let resolved = await fetchOpenMeteo(location: location) {
        storeCache(resolved)
        return resolved
      }
    }

    if let persisted = persistedLocation(),
       let resolved = await fetchOpenMeteo(location: persisted) {
      storeCache(resolved)
      return resolved
    }

    return cachedSnapshot ?? HomeHeroInsights.placeholderWeather(for: fallbackTimeOfDay)
  }

  private func storeCache(_ snapshot: HomeHeroInsights.WeatherSnapshot) {
    cachedSnapshot = snapshot
    let expiry = Date().addingTimeInterval(Self.cacheInterval)
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

  private func persistCoordinates(_ location: CLLocation) {
    UserDefaults.standard.set(location.coordinate.latitude, forKey: Self.persistedLatitudeKey)
    UserDefaults.standard.set(location.coordinate.longitude, forKey: Self.persistedLongitudeKey)
    UserDefaults.standard.set(location.timestamp, forKey: Self.persistedLocationDateKey)
  }

  private func persistedLocation() -> CLLocation? {
    guard UserDefaults.standard.object(forKey: Self.persistedLatitudeKey) != nil else { return nil }
    let lat = UserDefaults.standard.double(forKey: Self.persistedLatitudeKey)
    let lon = UserDefaults.standard.double(forKey: Self.persistedLongitudeKey)
    let savedAt = UserDefaults.standard.object(forKey: Self.persistedLocationDateKey) as? Date ?? .distantPast
    guard Date().timeIntervalSince(savedAt) <= Self.persistedLocationMaxAge else { return nil }
    return CLLocation(latitude: lat, longitude: lon)
  }

  private func resolveLocation() async -> CLLocation? {
    switch manager.authorizationStatus {
    case .authorizedWhenInUse, .authorizedAlways:
      if let recent = recentManagerLocation() {
        return recent
      }
      return await fetchLocationFix()

    case .notDetermined:
      if didRequestAuthorization {
        return nil
      }
      if persistedLocation() != nil {
        return nil
      }
      didRequestAuthorization = true
      let granted = await requestAuthorization()
      guard granted else { return nil }
      if let recent = recentManagerLocation() {
        return recent
      }
      return await fetchLocationFix()

    case .denied, .restricted:
      return nil

    @unknown default:
      return nil
    }
  }

  private func recentManagerLocation() -> CLLocation? {
    guard let location = manager.location else { return nil }
    guard abs(location.timestamp.timeIntervalSinceNow) <= Self.recentManagerLocationMaxAge else { return nil }
    return location
  }

  private func requestAuthorization() async -> Bool {
    await withCheckedContinuation { continuation in
      authorizationContinuation = continuation
      manager.requestWhenInUseAuthorization()
    }
  }

  private func fetchLocationFix() async -> CLLocation? {
    await withTaskGroup(of: CLLocation?.self) { group in
      group.addTask { @MainActor in
        await withCheckedContinuation { continuation in
          self.locationContinuation = continuation
          self.manager.requestLocation()
        }
      }
      group.addTask {
        let ns = UInt64(Self.locationFixTimeout * 1_000_000_000)
        try? await _Concurrency.Task.sleep(nanoseconds: ns)
        return nil
      }
      let result = await group.next() ?? nil
      group.cancelAll()
      resumeLocationContinuation(with: nil)
      return result
    }
  }

  private func resumeLocationContinuation(with location: CLLocation?) {
    locationContinuation?.resume(returning: location)
    locationContinuation = nil
  }

  private func resumeAuthorizationContinuation(granted: Bool) {
    authorizationContinuation?.resume(returning: granted)
    authorizationContinuation = nil
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
      switch status {
      case .authorizedWhenInUse, .authorizedAlways:
        resumeAuthorizationContinuation(granted: true)
        if locationContinuation != nil {
          manager.requestLocation()
        }
      case .denied, .restricted:
        resumeAuthorizationContinuation(granted: false)
        resumeLocationContinuation(with: nil)
      case .notDetermined:
        break
      @unknown default:
        resumeAuthorizationContinuation(granted: false)
        resumeLocationContinuation(with: nil)
      }
    }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    _Concurrency.Task { @MainActor in
      resumeLocationContinuation(with: locations.first)
    }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    _Concurrency.Task { @MainActor in
      resumeLocationContinuation(with: nil)
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
