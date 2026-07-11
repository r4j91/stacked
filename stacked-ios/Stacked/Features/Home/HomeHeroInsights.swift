import Foundation

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
}
