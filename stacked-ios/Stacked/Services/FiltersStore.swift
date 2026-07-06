import Foundation

enum FiltersScreenMode: Equatable {
  case dashboard
  case presetFilter(TaskFilterKind)
  case savedFilter(SavedFilter)
}

@MainActor
@Observable
final class FiltersStore {
  static let shared = FiltersStore()

  private let taskRepo = TaskRepository.shared
  private let projectRepo = ProjectRepository.shared
  private let savedFilterRepo = SavedFilterRepository.shared

  var mode: FiltersScreenMode = .dashboard

  private(set) var counts = FilterDashboardCounts(overdue: 0, today: 0, week: 0, completedToday: 0)
  private(set) var projects: [ProjectTaskStats] = []
  private(set) var savedFilters: [SavedFilterWithCount] = []
  private(set) var pickerLabels: [TaskLabel] = []
  private(set) var pickerProjects: [Project] = []
  private(set) var dashboardLoading = false
  private(set) var dashboardError: String?

  private(set) var filterTasks: [Task] = []
  private(set) var filterCompletedTasks: [Task] = []
  private(set) var filterResults: [FilterResultItem] = []
  private(set) var filterCompletedResults: [FilterResultItem] = []
  private(set) var filterLoading = false
  private(set) var filterError: String?

  private init() {}

  func loadDashboard() async {
    dashboardLoading = projects.isEmpty && savedFilters.isEmpty && counts.overdue == 0 && counts.today == 0
    dashboardError = nil
    let todayStr = TaskMapper.dateString(Date())
    let weekStr = TaskMapper.weekString()
    do {
      async let countsReq = taskRepo.fetchFilterDashboardCounts(todayStr: todayStr, weekStr: weekStr)
      async let projectStatsReq = projectRepo.fetchProjectsWithTaskStats()
      async let savedReq = savedFilterRepo.fetchSavedFiltersWithCounts(todayStr: todayStr, weekStr: weekStr)
      async let labelsReq = LabelRepository.shared.fetchLabels()
      async let pickerProjectsReq = ProjectRepository.shared.fetchProjects()
      counts = try await countsReq
      projects = try await projectStatsReq
      savedFilters = try await savedReq
      pickerLabels = try await labelsReq
      pickerProjects = try await pickerProjectsReq
    } catch {
      if AsyncLoad.isCancellation(error) { return }
      dashboardError = error.localizedDescription
    }
    dashboardLoading = false
  }

  func openFilter(_ kind: TaskFilterKind) async {
    mode = .presetFilter(kind)
    filterLoading = filterTasks.isEmpty
    filterError = nil
    filterCompletedTasks = []
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

  func openSavedFilter(_ filter: SavedFilter) async {
    mode = .savedFilter(filter)
    filterLoading = filterResults.isEmpty
    filterError = nil
    filterTasks = []
    filterCompletedTasks = []
    let todayStr = TaskMapper.dateString(Date())
    let weekStr = TaskMapper.weekString()
    do {
      let split = try await taskRepo.fetchPendingAndCompletedMatchingCriteria(
        filter.criteria,
        todayStr: todayStr,
        weekStr: weekStr
      )
      filterResults = split.pending
      filterCompletedResults = split.completed
    } catch {
      if AsyncLoad.isCancellation(error) { return }
      filterError = error.localizedDescription
    }
    filterLoading = false
  }

  func reloadSavedFilterTasks(includeCompleted: Bool) async {
    guard case .savedFilter(let filter) = mode else { return }
    let todayStr = TaskMapper.dateString(Date())
    let weekStr = TaskMapper.weekString()
    do {
      let split = try await taskRepo.fetchPendingAndCompletedMatchingCriteria(
        filter.criteria,
        todayStr: todayStr,
        weekStr: weekStr
      )
      filterResults = split.pending
      filterCompletedResults = includeCompleted ? split.completed : []
    } catch {
      if AsyncLoad.isCancellation(error) { return }
      filterError = error.localizedDescription
    }
  }

  func createSavedFilter(name: String, colorHex: String?, criteria: FilterCriteria) async throws {
    _ = try await savedFilterRepo.createSavedFilter(name: name, colorHex: colorHex, criteria: criteria)
    await loadDashboard()
  }

  func updateSavedFilter(_ filter: SavedFilter, name: String, colorHex: String?, criteria: FilterCriteria) async throws {
    let updated = try await savedFilterRepo.updateSavedFilter(
      id: filter.id,
      name: name,
      colorHex: colorHex,
      criteria: criteria
    )
    if case .savedFilter = mode {
      mode = .savedFilter(updated)
    }
    await loadDashboard()
    if case .savedFilter = mode {
      await openSavedFilter(updated)
    }
  }

  func deleteSavedFilter(_ filter: SavedFilter) async throws {
    try await savedFilterRepo.deleteSavedFilter(id: filter.id)
    if case .savedFilter(let current) = mode, current.id == filter.id {
      backToDashboard()
    }
    await loadDashboard()
  }

  func applySubtaskPatch(_ snapshot: SubtaskSaveSnapshot) {
    SubtaskListPatch.apply(snapshot, to: &filterTasks)
    SubtaskListPatch.apply(snapshot, to: &filterCompletedTasks)
    FilterResultListPatch.apply(snapshot, to: &filterResults)
    FilterResultListPatch.apply(snapshot, to: &filterCompletedResults)
  }

  func backToDashboard() {
    mode = .dashboard
    filterTasks = []
    filterCompletedTasks = []
    filterResults = []
    filterCompletedResults = []
    filterError = nil
  }

  func completeSubtask(parent: Task, sub: Subtask, at index: Int) {
    guard let i = filterResults.firstIndex(where: { item in
      if case .subtask(_, let p, let idx) = item {
        return p.id == parent.id && idx == index
      }
      return false
    }) else { return }
    guard case .subtask(let subtask, let parentTask, let subIndex) = filterResults[i], !subtask.done else { return }

    filterResults.remove(at: i)
    HapticService.taskCompleted()

    _Concurrency.Task {
      try? await SubtaskRepository.shared.toggleDone(
        id: sub.id,
        taskId: sub.taskId ?? parent.id,
        order: sub.order,
        done: true
      )
      if case .savedFilter = mode {
        let doneSub = Subtask(
          id: subtask.id,
          taskId: subtask.taskId ?? parent.id,
          title: subtask.title,
          description: subtask.description,
          done: true,
          priority: subtask.priority,
          order: subtask.order,
          valor: subtask.valor,
          dueDate: subtask.dueDate,
          dueDateChipLabel: subtask.dueDateChipLabel,
          dueDateChipColor: subtask.dueDateChipColor,
          labelIds: subtask.labelIds
        )
        filterCompletedResults.insert(.subtask(doneSub, parent: parentTask, index: subIndex), at: 0)
      }
      await loadDashboard()
    }
  }

  func complete(_ task: Task) {
    if case .savedFilter = mode,
       let i = filterResults.firstIndex(where: {
         if case .task(let t) = $0 { return t.id == task.id }
         return false
       }),
       case .task(let snapshot) = filterResults[i],
       !snapshot.done {
      let originalIndex = i
      let taskId = task.id
      filterResults.remove(at: i)
      HapticService.taskCompleted()
      TaskCompletionMotion.afterDwell(
        animatedRemoval: { [self] in
          var doneTask = snapshot
          doneTask.done = true
          filterCompletedResults.insert(.task(doneTask), at: 0)
        },
        persist: {
          try await self.taskRepo.toggleTaskDone(id: taskId, done: true)
          await self.loadDashboard()
        },
        rollback: { [self] in
          filterResults.insert(.task(snapshot), at: min(originalIndex, filterResults.count))
          filterCompletedResults.removeAll {
            if case .task(let t) = $0 { return t.id == taskId }
            return false
          }
        }
      )
      return
    }

    guard let i = filterTasks.firstIndex(where: { $0.id == task.id }) else {
      completeFromCompletedSection(task)
      return
    }
    guard !filterTasks[i].done else { return }

    let originalIndex = i
    let snapshot = filterTasks[i]
    let taskId = task.id

    filterTasks[i].done = true
    HapticService.taskCompleted()

    TaskCompletionMotion.afterDwell(
      animatedRemoval: { [self] in
        filterTasks.removeAll { $0.id == taskId }
        if case .savedFilter = mode {
          var doneTask = snapshot
          doneTask.done = true
          filterCompletedTasks.insert(doneTask, at: 0)
        }
      },
      persist: {
        try await self.taskRepo.toggleTaskDone(id: taskId, done: true)
        await self.loadDashboard()
      },
      rollback: { [self] in
        var restored = snapshot
        restored.done = false
        filterTasks.insert(restored, at: min(originalIndex, filterTasks.count))
        filterCompletedTasks.removeAll { $0.id == taskId }
      }
    )
  }

  private func completeFromCompletedSection(_ task: Task) {
    guard let i = filterCompletedTasks.firstIndex(where: { $0.id == task.id }) else { return }
    let snapshot = filterCompletedTasks[i]
    filterCompletedTasks.remove(at: i)
    _Concurrency.Task {
      try? await taskRepo.toggleTaskDone(id: task.id, done: false)
      if case .savedFilter(let filter) = mode {
        await openSavedFilter(filter)
      }
      await loadDashboard()
    }
    _ = snapshot
  }

  func delete(_ task: Task) {
    filterTasks.removeAll { $0.id == task.id }
    filterCompletedTasks.removeAll { $0.id == task.id }
    filterResults.removeAll {
      switch $0 {
      case .task(let t): return t.id == task.id
      case .subtask(_, let parent, _): return parent.id == task.id
      }
    }
    filterCompletedResults.removeAll {
      switch $0 {
      case .task(let t): return t.id == task.id
      case .subtask(_, let parent, _): return parent.id == task.id
      }
    }
    _Concurrency.Task {
      try? await taskRepo.deleteTask(id: task.id)
      await loadDashboard()
    }
  }

  func postpone(_ task: Task) async {
    let iso = TaskMapper.postponedDateISO(for: task)
    try? await taskRepo.updateTaskDate(id: task.id, isoDate: iso)
    switch mode {
    case .presetFilter(let kind):
      await openFilter(kind)
    case .savedFilter(let filter):
      await openSavedFilter(filter)
    case .dashboard:
      break
    }
    await loadDashboard()
  }

  func refreshCurrentFilter(showCompleted: Bool) async {
    switch mode {
    case .presetFilter(let kind):
      await openFilter(kind)
    case .savedFilter(let filter):
      await openSavedFilter(filter)
      if !showCompleted {
        filterCompletedResults = []
      }
    case .dashboard:
      break
    }
  }
}
