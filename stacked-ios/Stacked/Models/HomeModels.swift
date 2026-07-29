import Foundation

struct HomeTaskSummary {
  let todayTotal: Int
  let todayDone: Int
  let todayPending: Int
  let overdueCount: Int
}

struct HomeProject: Identifiable, Equatable, Codable {
  let id: String
  let name: String
  let colorHex: String?
  let iconKey: String?
  let taskCount: Int
}

/// Snapshot leve da Home — cold start sem ProgressView (stale-while-revalidate).
struct HomeDashboardSnapshot: Codable, Equatable {
  var overdueCount: Int
  var todayPending: Int
  var todayDone: Int
  var todayTotal: Int
  var inboxCount: Int
  var upcomingCount: Int
  var projects: [HomeProject]
  var focusTaskTitle: String?
  var focusTaskTime: String?
  var primaryOverdueTitle: String?
  var primaryOverdueTime: String?
  var queueLines: [HomeHeroInsights.QueueLine]
  var completionStreak: Int
  var streakWeekCompleted: [Bool]
  var weatherSnapshot: HomeHeroInsights.WeatherSnapshot?
  var savedAt: Date
}

struct ProjectRoute: Identifiable, Hashable {
  let id: String
  let name: String
  let snapshot: ProjectDetailSnapshot?

  init(id: String, name: String, snapshot: ProjectDetailSnapshot? = nil) {
    self.id = id
    self.name = name
    self.snapshot = snapshot
  }

  static func == (lhs: ProjectRoute, rhs: ProjectRoute) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
