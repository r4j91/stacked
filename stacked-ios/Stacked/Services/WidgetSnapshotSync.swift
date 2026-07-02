import Foundation
import WidgetKit

@MainActor
enum WidgetSnapshotSync {
  static func updateFromToday(pending: [Task], completed: [Task]) {
    let split = TaskMapper.splitTodayPending(pending)
    let ordered = split.overdue + split.today
    let items = ordered.prefix(4).map { task in
      WidgetTaskItem(
        id: task.id,
        title: task.title,
        isOverdue: split.overdue.contains(where: { $0.id == task.id })
      )
    }

    let snapshot = WidgetSnapshot(
      todayCount: split.today.count,
      overdueCount: split.overdue.count,
      nextTaskTitle: ordered.first?.title,
      tasks: Array(items),
      updatedAt: Date()
    )
    WidgetSnapshotStore.save(snapshot)
    WidgetCenter.shared.reloadAllTimelines()
  }

  static func clear() {
    WidgetSnapshotStore.save(.empty)
    WidgetCenter.shared.reloadAllTimelines()
  }
}
