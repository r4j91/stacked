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

  private var filterLoadGeneration = 0
  private var pendingPresetFilter: TaskFilterKind?
  /// Incrementa a cada `requestPresetFilterNavigation` — FiltersView observa
  /// para abrir drill-down mesmo quando a aba já estava montada (onAppear não repete).
  private(set) var pendingPresetFilterToken = 0
  private var savedFilterResultsCache: [String: (pending: [FilterResultItem], completed: [FilterResultItem])] = [:]
  private var presetFilterTasksCache: [TaskFilterKind: [Task]] = [:]

  private init() {}

  func takePendingPresetFilter() -> TaskFilterKind? {
    defer { pendingPresetFilter = nil }
    return pendingPresetFilter
  }

  func requestPresetFilterNavigation(_ kind: TaskFilterKind) {
    pendingPresetFilter = kind
    pendingPresetFilterToken &+= 1
  }

  func loadDashboard() async {
    dashboardLoading = projects.isEmpty && savedFilters.isEmpty && counts.overdue == 0 && counts.today == 0
    dashboardError = nil
    let todayStr = TaskMapper.dateString(Date())
    let weekStr = TaskMapper.weekString()
    do {
      async let countsReq = taskRepo.fetchFilterDashboardCounts(todayStr: todayStr, weekStr: weekStr)
      async let projectStatsReq = projectRepo.fetchProjectsWithTaskStats()
      async let savedReq = loadSavedFiltersPopulatingCache(todayStr: todayStr, weekStr: weekStr)
      async let presetCacheReq = populatePresetFilterCache(todayStr: todayStr, weekStr: weekStr)
      async let labelsReq = LabelRepository.shared.fetchLabels()
      async let pickerProjectsReq = ProjectRepository.shared.fetchProjects()
      counts = try await countsReq
      projects = try await projectStatsReq
      savedFilters = try await savedReq
      await presetCacheReq
      pickerLabels = try await labelsReq
      pickerProjects = try await pickerProjectsReq
    } catch {
      if AsyncLoad.isCancellation(error) { return }
      dashboardError = error.localizedDescription
    }
    dashboardLoading = false
  }

  private func loadSavedFiltersPopulatingCache(
    todayStr: String,
    weekStr: String
  ) async throws -> [SavedFilterWithCount] {
    let filters = try await savedFilterRepo.fetchSavedFilters()
    let order = filters.map(\.id)
    var byId: [String: SavedFilterWithCount] = [:]

    try await withThrowingTaskGroup(of: (String, [FilterResultItem], [FilterResultItem]).self) { group in
      for filter in filters {
        group.addTask {
          let split = try await self.taskRepo.fetchPendingAndCompletedMatchingCriteria(
            filter.criteria,
            todayStr: todayStr,
            weekStr: weekStr
          )
          return (filter.id, split.pending, split.completed)
        }
      }

      for try await (id, pending, completed) in group {
        savedFilterResultsCache[id] = (pending, completed)
        if let filter = filters.first(where: { $0.id == id }) {
          byId[id] = SavedFilterWithCount(filter: filter, pendingCount: pending.count)
        }
      }
    }

    return order.compactMap { byId[$0] }
  }

  private func populatePresetFilterCache(todayStr: String, weekStr: String) async {
    await withTaskGroup(of: (TaskFilterKind, [Task]).self) { group in
      for kind in TaskFilterKind.allCases {
        group.addTask {
          let tasks = (try? await self.taskRepo.fetchFilteredTasks(
            kind: kind,
            todayStr: todayStr,
            weekStr: weekStr
          )) ?? []
          return (kind, tasks)
        }
      }
      for await (kind, tasks) in group {
        presetFilterTasksCache[kind] = tasks
      }
    }
  }

  func cachedPresetTasks(for kind: TaskFilterKind) -> [Task] {
    presetFilterTasksCache[kind] ?? []
  }

  func hasPresetFilterCache(_ kind: TaskFilterKind) -> Bool {
    presetFilterTasksCache[kind] != nil
  }

  /// Prepara sessão do preset no toque — dados do cache imediatamente, sem dados stale.
  func preparePresetFilterSession(_ kind: TaskFilterKind) {
    filterLoadGeneration += 1
    mode = .presetFilter(kind)
    filterError = nil
    filterCompletedTasks = []
    filterResults = []
    filterCompletedResults = []
    if let cached = presetFilterTasksCache[kind] {
      filterTasks = cached
      filterLoading = false
    } else {
      filterTasks = []
      filterLoading = true
    }
  }

  /// Liga sessão do preset ao store após a transição de navegação.
  func adoptPresetFilterSession(_ kind: TaskFilterKind, tasks: [Task]) {
    mode = .presetFilter(kind)
    filterError = nil
    filterCompletedTasks = []
    filterResults = []
    filterCompletedResults = []
    filterTasks = tasks
    filterLoading = tasks.isEmpty && presetFilterTasksCache[kind] == nil
  }

  private func syncPresetFilterCache() {
    guard case .presetFilter(let kind) = mode else { return }
    presetFilterTasksCache[kind] = filterTasks
  }

  /// Aplica cache do dashboard imediatamente ao abrir drill-down (sem spinner).
  func presentSavedFilter(_ filter: SavedFilter) {
    mode = .savedFilter(filter)
    filterError = nil
    filterTasks = []
    filterCompletedTasks = []
    if let cached = savedFilterResultsCache[filter.id] {
      filterResults = cached.pending
      filterCompletedResults = cached.completed
      filterLoading = false
    } else {
      filterResults = []
      filterCompletedResults = []
      filterLoading = true
    }
  }

  func hasSavedFilterCache(_ filterId: String) -> Bool {
    savedFilterResultsCache[filterId] != nil
  }

  func cachedPendingResults(for filterId: String) -> [FilterResultItem] {
    savedFilterResultsCache[filterId]?.pending ?? []
  }

  func cachedCompletedResults(for filterId: String) -> [FilterResultItem] {
    savedFilterResultsCache[filterId]?.completed ?? []
  }

  /// Liga a sessão do drill-down ao store após a transição de navegação.
  func adoptSavedFilterSession(_ filter: SavedFilter, pending: [FilterResultItem], completed: [FilterResultItem]) {
    mode = .savedFilter(filter)
    filterError = nil
    filterTasks = []
    filterCompletedTasks = []
    filterResults = pending
    filterCompletedResults = completed
    filterLoading = pending.isEmpty && completed.isEmpty && savedFilterResultsCache[filter.id] == nil
  }

  private func syncSavedFilterCache() {
    guard case .savedFilter(let filter) = mode else { return }
    savedFilterResultsCache[filter.id] = (filterResults, filterCompletedResults)
  }

  func openFilter(_ kind: TaskFilterKind) async {
    filterLoadGeneration += 1
    let generation = filterLoadGeneration

    mode = .presetFilter(kind)
    filterError = nil
    filterCompletedTasks = []
    filterLoading = filterTasks.isEmpty
    defer {
      if generation == filterLoadGeneration {
        filterLoading = false
      }
    }

    let todayStr = TaskMapper.dateString(Date())
    let weekStr = TaskMapper.weekString()
    do {
      filterTasks = try await taskRepo.fetchFilteredTasks(kind: kind, todayStr: todayStr, weekStr: weekStr)
      presetFilterTasksCache[kind] = filterTasks
    } catch {
      if AsyncLoad.isCancellation(error) { return }
      filterError = error.localizedDescription
    }
  }

  func openSavedFilter(_ filter: SavedFilter) async {
    filterLoadGeneration += 1
    let generation = filterLoadGeneration

    mode = .savedFilter(filter)
    filterError = nil
    filterTasks = []
    filterCompletedTasks = []
    let hasCache = savedFilterResultsCache[filter.id] != nil
    if hasCache, let cached = savedFilterResultsCache[filter.id] {
      filterResults = cached.pending
      filterCompletedResults = cached.completed
    } else if !hasCache {
      filterResults = []
      filterCompletedResults = []
    }
    filterLoading = !hasCache
    defer {
      if generation == filterLoadGeneration {
        filterLoading = false
      }
    }

    let todayStr = TaskMapper.dateString(Date())
    let weekStr = TaskMapper.weekString()
    do {
      let split = try await taskRepo.fetchPendingAndCompletedMatchingCriteria(
        filter.criteria,
        todayStr: todayStr,
        weekStr: weekStr
      )
      guard generation == filterLoadGeneration else { return }
      if filterResults != split.pending || filterCompletedResults != split.completed {
        filterResults = split.pending
        filterCompletedResults = split.completed
      }
      savedFilterResultsCache[filter.id] = (split.pending, split.completed)
    } catch {
      if AsyncLoad.isCancellation(error) { return }
      filterError = error.localizedDescription
    }
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
      savedFilterResultsCache[filter.id] = (split.pending, split.completed)
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
    savedFilterResultsCache.removeValue(forKey: filter.id)
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
    syncSavedFilterCache()
  }

  func backToDashboard() {
    filterLoadGeneration += 1
    mode = .dashboard
    filterTasks = []
    filterCompletedTasks = []
    filterResults = []
    filterCompletedResults = []
    filterError = nil
    filterLoading = false
    presetFilterTasksCache.removeAll()
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
    syncSavedFilterCache()
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
          time: subtask.time,
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
          syncSavedFilterCache()
        },
        persist: {
          if let newId = try await self.taskRepo.completeTask(snapshot) {
            await TaskCalendarSync.syncTaskId(newId)
          }
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
        syncPresetFilterCache()
      },
      persist: {
        if let newId = try await self.taskRepo.completeTask(snapshot) {
          await TaskCalendarSync.syncTaskId(newId)
        }
        await self.loadDashboard()
      },
      rollback: { [self] in
        var restored = snapshot
        restored.done = false
        filterTasks.insert(restored, at: min(originalIndex, filterTasks.count))
        filterCompletedTasks.removeAll { $0.id == taskId }
        syncPresetFilterCache()
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
    syncSavedFilterCache()
    syncPresetFilterCache()
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
