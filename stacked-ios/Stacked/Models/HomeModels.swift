import Foundation

struct HomeTaskSummary {
  let todayTotal: Int
  let todayDone: Int
  let todayPending: Int
  let overdueCount: Int
}

struct HomeProject: Identifiable, Equatable {
  let id: String
  let name: String
  let colorHex: String?
  let iconKey: String?
  let taskCount: Int
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
