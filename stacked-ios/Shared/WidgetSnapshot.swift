import Foundation

// Snapshot compartilhado app ↔ widget (App Group)
struct WidgetTaskItem: Codable, Identifiable, Hashable {
  let id: String
  let title: String
  let isOverdue: Bool
}

struct WidgetSnapshot: Codable, Equatable {
  let todayCount: Int
  let overdueCount: Int
  let nextTaskTitle: String?
  let tasks: [WidgetTaskItem]
  let updatedAt: Date

  static let empty = WidgetSnapshot(
    todayCount: 0,
    overdueCount: 0,
    nextTaskTitle: nil,
    tasks: [],
    updatedAt: .distantPast
  )
}

enum WidgetConstants {
  static let appGroupID = "group.com.stacked.app"
  static let snapshotKey = "widget_snapshot_v1"
}

enum WidgetSnapshotStore {
  static func save(_ snapshot: WidgetSnapshot) {
    guard let defaults = UserDefaults(suiteName: WidgetConstants.appGroupID),
          let data = try? JSONEncoder().encode(snapshot)
    else { return }
    defaults.set(data, forKey: WidgetConstants.snapshotKey)
  }

  static func load() -> WidgetSnapshot {
    guard let defaults = UserDefaults(suiteName: WidgetConstants.appGroupID),
          let data = defaults.data(forKey: WidgetConstants.snapshotKey),
          let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    else { return .empty }
    return snapshot
  }
}
