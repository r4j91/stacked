import Foundation

/// Resolve o que o widget exibe conforme o modo escolhido e o snapshot salvo.
struct WidgetPresentation {
  enum ActiveSource: Equatable {
    case today
    case upcoming
    case signedOut
    case allClear
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
    switch activeSource {
    case .today: "Hoje"
    case .upcoming: "Em breve"
    case .signedOut, .allClear: "Hoje"
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

  var deepLink: URL {
    switch activeSource {
    case .upcoming: WidgetDeepLink.upcoming
    default: WidgetDeepLink.today
    }
  }
}
