import Foundation

struct HomeTaskSummary {
  let todayTotal: Int
  let todayDone: Int
  let overdueCount: Int

  var todayPending: Int { max(0, todayTotal - todayDone) }
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
}
