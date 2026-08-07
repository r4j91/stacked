import Foundation

/// Resolve o que o widget exibe conforme o modo escolhido e o snapshot salvo.
struct WidgetPresentation {
  enum ActiveSource: Equatable {
    case today
    case upcoming
    case signedOut
    case allClear
  }

  struct StripDay: Identifiable, Equatable {
    let dayStart: Date
    let weekdayShort: String
    let dayNumber: Int
    let count: Int
    let isToday: Bool

    var id: TimeInterval { dayStart.timeIntervalSince1970 }
    var hasTasks: Bool { count > 0 }
  }

  let mode: WidgetDisplayMode
  let snapshot: WidgetSnapshot

  var activeSource: ActiveSource {
    guard snapshot.isAuthenticated else { return .signedOut }
    switch mode {
    case .today:
      return snapshot.pendingTotal > 0 ? .today : .allClear
    case .upcoming:
      return snapshot.upcomingCount > 0 ? .upcoming : .allClear
    case .smart:
      if snapshot.pendingTotal > 0 { return .today }
      if snapshot.upcomingCount > 0 { return .upcoming }
      return .allClear
    }
  }

  var headerTitle: String {
    switch mode {
    case .upcoming:
      return "Em breve"
    case .today:
      return "Hoje"
    case .smart:
      switch activeSource {
      case .upcoming: return "Em breve"
      case .today, .signedOut, .allClear: return "Hoje"
      }
    }
  }

  var primaryCount: Int {
    switch activeSource {
    case .today: snapshot.pendingTotal
    case .upcoming: snapshot.upcomingCount
    case .signedOut, .allClear: 0
    }
  }

  var countLabel: String {
    switch activeSource {
    case .today: snapshot.pendingTotal == 1 ? "pendente" : "pendentes"
    case .upcoming: snapshot.upcomingCount == 1 ? "próxima" : "próximas"
    case .signedOut, .allClear: ""
    }
  }

  var displayTasks: [WidgetTaskItem] {
    switch activeSource {
    case .today: snapshot.tasks
    case .upcoming: snapshot.upcomingTasks
    case .signedOut, .allClear: []
    }
  }

  var showsOverdueBadge: Bool {
    activeSource == .today && snapshot.overdueCount > 0
  }

  var showsTodayClearHint: Bool {
    mode == .smart && activeSource == .upcoming && snapshot.pendingTotal == 0
  }

  /// Layout calendário (opção F) — modo Em breve sempre; smart quando cai em upcoming.
  var usesCalendarLayout: Bool {
    guard snapshot.isAuthenticated else { return false }
    if mode == .upcoming { return true }
    return activeSource == .upcoming
  }

  var nextUpcomingTask: WidgetTaskItem? {
    snapshot.upcomingTasks.first
  }

  /// Linha "Amanhã · Revisar…" do small.
  var upcomingFocusLine: String? {
    guard let task = nextUpcomingTask else { return nil }
    if let label = task.dateLabel, !label.isEmpty {
      return "\(label) · \(task.title)"
    }
    return task.title
  }

  /// Label curto uppercase pra medium ("AMANHÃ", "HOJE", "SEX").
  var upcomingFocusDayLabel: String? {
    guard let label = nextUpcomingTask?.dateLabel, !label.isEmpty else { return nil }
    if label.compare("Amanhã", options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame {
      return "AMANHÃ"
    }
    if label.compare("Hoje", options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame {
      return "HOJE"
    }
    let short = label.split(separator: ",").first.map(String.init) ?? label
    return short.uppercased()
  }

  var stripDays: [StripDay] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let labels = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]

    if snapshot.dayBuckets.count == 7 {
      return snapshot.dayBuckets.map { bucket in
        let weekday = calendar.component(.weekday, from: bucket.dayStart) // 1=Dom
        return StripDay(
          dayStart: bucket.dayStart,
          weekdayShort: labels[weekday - 1],
          dayNumber: calendar.component(.day, from: bucket.dayStart),
          count: bucket.count,
          isToday: calendar.isDate(bucket.dayStart, inSameDayAs: today)
        )
      }
    }

    // Fallback se snapshot antigo / vazio: monta strip zerado.
    return (0..<7).compactMap { offset in
      guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
      let weekday = calendar.component(.weekday, from: day)
      return StripDay(
        dayStart: day,
        weekdayShort: labels[weekday - 1],
        dayNumber: calendar.component(.day, from: day),
        count: 0,
        isToday: offset == 0
      )
    }
  }

  var deepLink: URL {
    switch activeSource {
    case .upcoming: WidgetDeepLink.upcoming
    default: WidgetDeepLink.today
    }
  }
}
