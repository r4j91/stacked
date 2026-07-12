import Foundation
import WidgetKit

@MainActor
enum WidgetSnapshotSync {
  static func refreshAll() {
    guard AuthManager.shared.isAuthenticated else {
      clear()
      return
    }

    let todayStore = TaskStore.shared
    let upcomingStore = UpcomingStore.shared
    persist(buildSnapshot(
      todayPending: todayStore.todayPending,
      todayCompleted: todayStore.todayCompleted,
      upcomingTasks: upcomingStore.tasks,
      upcomingSubtasks: upcomingStore.scheduledSubtasks
    ))
  }

  /// Mantido para call sites existentes — agora sincroniza Hoje + Em breve.
  static func updateFromToday(pending: [Task], completed: [Task]) {
    guard AuthManager.shared.isAuthenticated else {
      clear()
      return
    }
    let upcomingStore = UpcomingStore.shared
    persist(buildSnapshot(
      todayPending: pending,
      todayCompleted: completed,
      upcomingTasks: upcomingStore.tasks,
      upcomingSubtasks: upcomingStore.scheduledSubtasks
    ))
  }

  static func refreshFromCachedToday() {
    refreshAll()
  }

  static func clear() {
    persist(.empty)
  }

  private static func buildSnapshot(
    todayPending: [Task],
    todayCompleted: [Task],
    upcomingTasks: [Task],
    upcomingSubtasks: [SubtaskScheduleEntry]
  ) -> WidgetSnapshot {
    let split = TaskMapper.splitTodayPending(todayPending)
    let orderedToday = split.overdue + split.today
    let todayItems = orderedToday.prefix(5).compactMap { task -> WidgetTaskItem? in
      guard TaskIdentity.isValidUUID(task.id) else { return nil }
      return WidgetTaskItem(
        id: task.id,
        title: task.title,
        isOverdue: split.overdue.contains(where: { $0.id == task.id }),
        dateLabel: nil
      )
    }

    let upcomingItems = buildUpcomingItems(tasks: upcomingTasks, subtasks: upcomingSubtasks)

    return WidgetSnapshot(
      isAuthenticated: true,
      todayCount: split.today.count,
      overdueCount: split.overdue.count,
      completedTodayCount: todayCompleted.count,
      upcomingCount: upcomingItems.count,
      nextTaskTitle: orderedToday.first?.title ?? upcomingItems.first?.title,
      tasks: Array(todayItems),
      upcomingTasks: upcomingItems,
      updatedAt: Date()
    )
  }

  private static func buildUpcomingItems(
    tasks: [Task],
    subtasks: [SubtaskScheduleEntry]
  ) -> [WidgetTaskItem] {
    let today = TaskMapper.startOfDay(Date())

    struct SortableItem {
      let date: Date
      let item: WidgetTaskItem
    }

    var sortable: [SortableItem] = []

    for task in tasks {
      guard TaskIdentity.isValidUUID(task.id) else { continue }
      guard let due = task.dueDate else { continue }
      let day = TaskMapper.startOfDay(due)
      guard day > today else { continue }
      sortable.append(SortableItem(
        date: day,
        item: WidgetTaskItem(
          id: task.id,
          title: task.title,
          isOverdue: false,
          dateLabel: TaskMapper.dayLabel(for: due)
        )
      ))
    }

    for entry in subtasks {
      guard TaskIdentity.isValidUUID(entry.parent.id) else { continue }
      guard let due = entry.subtask.dueDate else { continue }
      let day = TaskMapper.startOfDay(due)
      guard day > today else { continue }
      sortable.append(SortableItem(
        date: day,
        item: WidgetTaskItem(
          id: entry.parent.id,
          title: entry.subtask.title,
          isOverdue: false,
          dateLabel: TaskMapper.dayLabel(for: due)
        )
      ))
    }

    sortable.sort { lhs, rhs in
      if lhs.date != rhs.date { return lhs.date < rhs.date }
      return lhs.item.title.localizedCaseInsensitiveCompare(rhs.item.title) == .orderedAscending
    }

    var seen = Set<String>()
    var items: [WidgetTaskItem] = []
    for entry in sortable {
      let key = "\(entry.item.id)|\(entry.item.title)"
      guard seen.insert(key).inserted else { continue }
      items.append(entry.item)
      if items.count >= 6 { break }
    }
    return items
  }

  private static func persist(_ snapshot: WidgetSnapshot) {
    WidgetSnapshotStore.save(snapshot)
    WidgetCenter.shared.reloadAllTimelines()
  }
}
