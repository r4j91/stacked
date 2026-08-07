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

    let upcoming = buildUpcoming(tasks: upcomingTasks, subtasks: upcomingSubtasks)

    return WidgetSnapshot(
      isAuthenticated: true,
      todayCount: split.today.count,
      overdueCount: split.overdue.count,
      completedTodayCount: todayCompleted.count,
      upcomingCount: upcoming.totalCount,
      nextTaskTitle: orderedToday.first?.title ?? upcoming.items.first?.title,
      tasks: Array(todayItems),
      upcomingTasks: upcoming.items,
      dayBuckets: upcoming.dayBuckets,
      updatedAt: Date()
    )
  }

  private static func buildUpcoming(
    tasks: [Task],
    subtasks: [SubtaskScheduleEntry]
  ) -> (items: [WidgetTaskItem], dayBuckets: [WidgetDayBucket], totalCount: Int) {
    let calendar = Calendar.current
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
    var countsByDay: [Date: Int] = [:]
    for entry in sortable {
      let key = "\(entry.item.id)|\(entry.item.title)"
      guard seen.insert(key).inserted else { continue }
      countsByDay[entry.date, default: 0] += 1
      if items.count < 6 {
        items.append(entry.item)
      }
    }

    let dayBuckets: [WidgetDayBucket] = (0..<7).compactMap { offset in
      guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
      return WidgetDayBucket(dayStart: day, count: countsByDay[day, default: 0])
    }

    let totalCount = countsByDay.values.reduce(0, +)
    return (items, dayBuckets, totalCount)
  }

  private static func persist(_ snapshot: WidgetSnapshot) {
    WidgetSnapshotStore.save(snapshot)
    WidgetCenter.shared.reloadAllTimelines()
  }
}
