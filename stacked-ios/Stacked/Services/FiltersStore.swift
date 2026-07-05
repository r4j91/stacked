import Foundation

enum FiltersScreenMode: Equatable {
  case dashboard
  case filter(TaskFilterKind)
}

@MainActor
@Observable
final class FiltersStore {
  static let shared = FiltersStore()

  private let taskRepo = TaskRepository.shared
  private let projectRepo = ProjectRepository.shared

  var mode: FiltersScreenMode = .dashboard

  private(set) var counts = FilterDashboardCounts(overdue: 0, today: 0, week: 0, completedToday: 0)
  private(set) var projects: [ProjectTaskStats] = []
  private(set) var dashboardLoading = false
  private(set) var dashboardError: String?

  private(set) var filterTasks: [Task] = []
  private(set) var filterLoading = false
  private(set) var filterError: String?

  private init() {}

  func loadDashboard() async {
    dashboardLoading = projects.isEmpty && counts.overdue == 0 && counts.today == 0
    dashboardError = nil
    let todayStr = TaskMapper.dateString(Date())
    let weekStr = TaskMapper.weekString()
    do {
      async let countsReq = taskRepo.fetchFilterDashboardCounts(todayStr: todayStr, weekStr: weekStr)
      async let projectsReq = projectRepo.fetchProjectsWithTaskStats()
      counts = try await countsReq
      projects = try await projectsReq
    } catch {
      if AsyncLoad.isCancellation(error) { return }
      dashboardError = error.localizedDescription
    }
    dashboardLoading = false
  }

  func openFilter(_ kind: TaskFilterKind) async {
    mode = .filter(kind)
    filterLoading = filterTasks.isEmpty
    filterError = nil
    let todayStr = TaskMapper.dateString(Date())
    let weekStr = TaskMapper.weekString()
    do {
      filterTasks = try await taskRepo.fetchFilteredTasks(kind: kind, todayStr: todayStr, weekStr: weekStr)
    } catch {
      if AsyncLoad.isCancellation(error) { return }
      filterError = error.localizedDescription
    }
    filterLoading = false
  }

  func applySubtaskPatch(_ snapshot: SubtaskSaveSnapshot) {
    SubtaskListPatch.apply(snapshot, to: &filterTasks)
  }

  func backToDashboard() {
    mode = .dashboard
    filterTasks = []
    filterError = nil
  }

  func complete(_ task: Task) {
    guard let i = filterTasks.firstIndex(where: { $0.id == task.id }) else { return }
    guard !filterTasks[i].done else { return }

    let originalIndex = i
    let snapshot = filterTasks[i]
    let taskId = task.id

    filterTasks[i].done = true
    HapticService.taskCompleted()

    TaskCompletionMotion.afterDwell(
      animatedRemoval: { [self] in
        filterTasks.removeAll { $0.id == taskId }
      },
      persist: {
        try await self.taskRepo.toggleTaskDone(id: taskId, done: true)
        await self.loadDashboard()
      },
      rollback: { [self] in
        var restored = snapshot
        restored.done = false
        filterTasks.insert(restored, at: min(originalIndex, filterTasks.count))
      }
    )
  }

  func delete(_ task: Task) {
    filterTasks.removeAll { $0.id == task.id }
    _Concurrency.Task {
      try? await taskRepo.deleteTask(id: task.id)
      await loadDashboard()
    }
  }

  func postpone(_ task: Task) async {
    let iso = TaskMapper.postponedDateISO(for: task)
    try? await taskRepo.updateTaskDate(id: task.id, isoDate: iso)
    if case .filter(let kind) = mode {
      await openFilter(kind)
    }
    await loadDashboard()
  }
}
