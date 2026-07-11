import Foundation
import SwiftUI

enum HomeHeroInsights {
  struct FocusTask {
    let title: String
    let time: String?
  }

  struct StreakSnapshot {
    let days: Int
    /// Segunda → domingo da semana civil atual.
    let weekCompleted: [Bool]
  }

  struct QueueLine: Identifiable, Equatable {
    let id: String
    let title: String
    let scope: Scope

    enum Scope: Equatable {
      case overdue
      case today
    }
  }

  static func resolveFocusTask(from tasks: [Task], now: Date = Date()) -> FocusTask? {
    let todayStart = Calendar.current.startOfDay(for: now)
    let pending = tasks.filter { !$0.done }
    guard !pending.isEmpty else { return nil }

    let todayPool = pending.filter { task in
      guard let due = task.dueDate else { return true }
      return due >= todayStart
    }
    let pool = todayPool.isEmpty ? pending : todayPool

    let timed = pool.filter { !($0.time ?? "").isEmpty }
    let pick = timed.first ?? pool.first!
    return FocusTask(title: pick.title, time: pick.timeDisplay)
  }

  static func resolvePrimaryOverdue(from tasks: [Task], now: Date = Date()) -> FocusTask? {
    let overdue = TaskMapper.splitTodayPending(tasks, now: now).overdue
    guard let first = overdue.first else { return nil }
    return FocusTask(title: first.title, time: first.timeDisplay)
  }

  static func resolveQueueLines(from tasks: [Task], limit: Int = 2, now: Date = Date()) -> [QueueLine] {
    let split = TaskMapper.splitTodayPending(tasks, now: now)
    var lines: [QueueLine] = []
    for task in split.overdue.prefix(limit) {
      lines.append(QueueLine(id: task.id, title: task.title, scope: .overdue))
    }
    if lines.count < limit {
      for task in split.today.prefix(limit - lines.count) {
        lines.append(QueueLine(id: task.id, title: task.title, scope: .today))
      }
    }
    return lines
  }

  static func streak(from completionDates: [Date], now: Date = Date()) -> StreakSnapshot {
    let cal = Calendar.current
    let completedDays = Set(completionDates.map { cal.startOfDay(for: $0) })
    let today = cal.startOfDay(for: now)

    var streak = 0
    var cursor = today
    if !completedDays.contains(cursor), let yesterday = cal.date(byAdding: .day, value: -1, to: cursor) {
      cursor = yesterday
    }
    while completedDays.contains(cursor) {
      streak += 1
      guard let previous = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
      cursor = previous
    }

    let weekday = cal.component(.weekday, from: today)
    let daysFromMonday = (weekday + 5) % 7
    let monday = cal.date(byAdding: .day, value: -daysFromMonday, to: today)!
    let weekCompleted = (0..<7).map { offset in
      guard let day = cal.date(byAdding: .day, value: offset, to: monday) else { return false }
      return completedDays.contains(day)
    }

    return StreakSnapshot(days: streak, weekCompleted: weekCompleted)
  }

  struct WeatherSnapshot: Equatable {
    let temperatureC: Int
    let condition: String
    let windKmh: Int
    let humidityPercent: Int
    let style: Style
    var isLive: Bool = false

    enum Style: Equatable {
      case sunny
      case partlyCloudy
      case cloudy
      case rainy
      case stormy
      case snowy
      case foggy
      case clear
    }

    var tintAccent: Color {
      switch style {
      case .sunny: AppColors.priorityMedium
      case .partlyCloudy, .cloudy: AppColors.priorityLow
      case .rainy, .stormy: AppColors.priorityLow
      case .snowy: AppColors.priorityLow
      case .foggy: AppColors.textTertiary
      case .clear: AppColors.tagPurple
      }
    }
  }

  static func formattedLongDate(from date: Date = Date()) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "pt_BR")
    formatter.dateFormat = "EEEE, d 'de' MMMM"
    let raw = formatter.string(from: date)
    guard let first = raw.first else { return raw }
    return first.uppercased() + raw.dropFirst()
  }

  static func placeholderWeather(for timeOfDay: HomeTimeOfDay) -> WeatherSnapshot {
    switch timeOfDay {
    case .morning:
      return WeatherSnapshot(temperatureC: 22, condition: "Ensolarado", windKmh: 8, humidityPercent: 45, style: .sunny)
    case .afternoon:
      return WeatherSnapshot(temperatureC: 24, condition: "Parcialmente nublado", windKmh: 12, humidityPercent: 52, style: .partlyCloudy)
    case .night:
      return WeatherSnapshot(temperatureC: 18, condition: "Céu limpo", windKmh: 6, humidityPercent: 58, style: .clear)
    }
  }

  static func portugueseCondition(for style: WeatherSnapshot.Style) -> String {
    switch style {
    case .sunny: "Ensolarado"
    case .partlyCloudy: "Parcialmente nublado"
    case .cloudy: "Nublado"
    case .rainy: "Chuvoso"
    case .stormy: "Tempestade"
    case .snowy: "Neve"
    case .foggy: "Neblina"
    case .clear: "Céu limpo"
    }
  }

  static func style(fromWMOCode code: Int) -> WeatherSnapshot.Style {
    switch code {
    case 0: return .sunny
    case 1, 2: return .partlyCloudy
    case 3: return .cloudy
    case 45, 48: return .foggy
    case 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82: return .rainy
    case 71, 73, 75, 77, 85, 86: return .snowy
    case 95, 96, 99: return .stormy
    default: return .partlyCloudy
    }
  }

  @available(*, deprecated, renamed: "placeholderWeather(for:)")
  static func weather(for timeOfDay: HomeTimeOfDay) -> WeatherSnapshot {
    placeholderWeather(for: timeOfDay)
  }
}
