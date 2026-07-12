import Foundation
import SwiftUI

/// Paleta do widget — espelha o tema escuro do app.
enum WidgetTheme {
  static let background = Color(red: 0.10, green: 0.11, blue: 0.12)
  static let accent = Color(red: 0.37, green: 0.83, blue: 0.86)
  static let textPrimary = Color(red: 0.95, green: 0.95, blue: 0.96)
  static let textSecondary = Color(red: 0.57, green: 0.59, blue: 0.63)
  static let overdue = Color(red: 0.94, green: 0.35, blue: 0.37)
  static let success = Color(red: 0.56, green: 0.83, blue: 0.42)
}

// Snapshot compartilhado app ↔ widget (App Group)
struct WidgetTaskItem: Codable, Identifiable, Hashable {
  let id: String
  let title: String
  let isOverdue: Bool
  let dateLabel: String?
}

struct WidgetSnapshot: Codable, Equatable {
  let isAuthenticated: Bool
  let todayCount: Int
  let overdueCount: Int
  let completedTodayCount: Int
  let upcomingCount: Int
  let nextTaskTitle: String?
  let tasks: [WidgetTaskItem]
  let upcomingTasks: [WidgetTaskItem]
  let updatedAt: Date

  var pendingTotal: Int { todayCount + overdueCount }

  static let empty = WidgetSnapshot(
    isAuthenticated: false,
    todayCount: 0,
    overdueCount: 0,
    completedTodayCount: 0,
    upcomingCount: 0,
    nextTaskTitle: nil,
    tasks: [],
    upcomingTasks: [],
    updatedAt: .distantPast
  )

  static let preview = WidgetSnapshot(
    isAuthenticated: true,
    todayCount: 0,
    overdueCount: 0,
    completedTodayCount: 2,
    upcomingCount: 4,
    nextTaskTitle: "Revisar proposta",
    tasks: [],
    upcomingTasks: [
      WidgetTaskItem(id: "00000000-0000-0000-0000-000000000001", title: "Revisar proposta", isOverdue: false, dateLabel: "Amanhã"),
      WidgetTaskItem(id: "00000000-0000-0000-0000-000000000002", title: "Ligar para o cliente", isOverdue: false, dateLabel: "Sex, 13 Jul"),
      WidgetTaskItem(id: "00000000-0000-0000-0000-000000000003", title: "Enviar relatório", isOverdue: false, dateLabel: "Seg, 15 Jul"),
    ],
    updatedAt: Date()
  )

  static let previewToday = WidgetSnapshot(
    isAuthenticated: true,
    todayCount: 2,
    overdueCount: 1,
    completedTodayCount: 1,
    upcomingCount: 4,
    nextTaskTitle: "Revisar proposta",
    tasks: [
      WidgetTaskItem(id: "00000000-0000-0000-0000-00000000000a", title: "Tarefa atrasada", isOverdue: true, dateLabel: nil),
      WidgetTaskItem(id: "00000000-0000-0000-0000-00000000000b", title: "Tarefa de hoje", isOverdue: false, dateLabel: nil),
    ],
    upcomingTasks: preview.upcomingTasks,
    updatedAt: Date()
  )
}

enum WidgetConstants {
  static let appGroupID = "group.com.stacked.app"
  static let snapshotKey = "widget_snapshot_v3"
}

enum TaskIdentity {
  static func isValidUUID(_ id: String) -> Bool {
    UUID(uuidString: id) != nil
  }
}

enum WidgetSnapshotStore {
  static var isAppGroupAvailable: Bool {
    UserDefaults(suiteName: WidgetConstants.appGroupID) != nil
  }

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

enum WidgetDeepLink {
  static let today = URL(string: "stacked://today")!
  static let upcoming = URL(string: "stacked://upcoming")!
  static let inbox = URL(string: "stacked://inbox")!

  static func task(_ id: String) -> URL {
    URL(string: "stacked://task/\(id)")!
  }
}
