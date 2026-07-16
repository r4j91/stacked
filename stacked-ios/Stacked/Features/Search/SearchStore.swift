import Foundation

private struct SearchTaskIndexEntry {
  let task: Task
  let title: String
  let description: String
  let project: String
  let labels: [String]

  init(task: Task) {
    self.task = task
    title = task.title.lowercased()
    description = (task.description ?? "").lowercased()
    project = task.project.lowercased()
    labels = task.labels.map { $0.name.lowercased() }
  }

  func matches(_ query: String) -> Bool {
    title.contains(query)
      || description.contains(query)
      || project.contains(query)
      || labels.contains { $0.contains(query) }
  }
}

@MainActor
@Observable
final class SearchStore {
  static let shared = SearchStore()

  private(set) var allTasks: [Task] = []
  private(set) var isLoading = false
  private(set) var error: String?
  private(set) var groupedResults: [(title: String, tasks: [Task])] = []
  var query = "" {
    didSet {
      guard query != oldValue else { return }
      scheduleFilter()
    }
  }

  private var searchIndex: [SearchTaskIndexEntry] = []
  private var filterTask: _Concurrency.Task<Void, Never>?
  private var debouncedQuery = ""

  private init() {}

  var results: [Task] {
    groupedResults.flatMap(\.tasks)
  }

  func applySubtaskPatch(_ snapshot: SubtaskSaveSnapshot) {
    SubtaskListPatch.apply(snapshot, to: &allTasks)
    rebuildSearchIndex()
    regroupResults()
  }

  func removeSubtask(parentId: String, subtask: Subtask) {
    SubtaskListPatch.remove(parentTaskId: parentId, subtask: subtask, from: &allTasks)
    rebuildSearchIndex()
    regroupResults()
  }

  func load() async {
    isLoading = allTasks.isEmpty
    error = nil
    do {
      allTasks = try await TaskRepository.shared.fetchPendingTasksForSearch()
      rebuildSearchIndex()
      regroupResults()
    } catch {
      self.error = error.localizedDescription
    }
    isLoading = false
  }

  func syncTask(_ taskId: String) async {
    if let updated = try? await TaskRepository.shared.fetchTaskById(taskId) {
      if updated.done {
        allTasks.removeAll { $0.id == taskId }
      } else if let index = allTasks.firstIndex(where: { $0.id == taskId }) {
        allTasks[index] = updated
      } else {
        allTasks.append(updated)
      }
    } else {
      allTasks.removeAll { $0.id == taskId }
    }
    rebuildSearchIndex()
    regroupResults()
  }

  func complete(_ task: Task) {
    guard let i = allTasks.firstIndex(where: { $0.id == task.id }) else { return }
    guard !allTasks[i].done else { return }

    let originalIndex = i
    let snapshot = allTasks[i]
    let taskId = task.id

    allTasks[i].done = true
    HapticService.taskCompleted()
    rebuildSearchIndex()
    regroupResults()

    TaskCompletionMotion.afterDwell(
      rowIdentity: taskId,
      animatedRemoval: { [self] in
        allTasks.removeAll { $0.id == taskId }
        rebuildSearchIndex()
        regroupResults()
      },
      persist: {
        _ = try await TaskRepository.shared.completeTask(snapshot)
      },
      rollback: { [self] in
        var restored = snapshot
        restored.done = false
        allTasks.insert(restored, at: min(originalIndex, allTasks.count))
        rebuildSearchIndex()
        regroupResults()
      }
    )
  }

  func delete(_ task: Task) {
    allTasks.removeAll { $0.id == task.id }
    rebuildSearchIndex()
    regroupResults()
    HapticService.taskDeleted()
    _Concurrency.Task {
      try? await TaskRepository.shared.deleteTask(id: task.id)
    }
  }

  func duplicate(_ task: Task) {
    _Concurrency.Task {
      _ = try? await TaskRepository.shared.duplicateTask(task)
      await load()
    }
  }

  func postpone(_ task: Task) async {
    let iso = TaskMapper.postponedDateISO(for: task)
    try? await TaskRepository.shared.updateTaskDate(id: task.id, isoDate: iso)
    allTasks.removeAll { $0.id == task.id }
    rebuildSearchIndex()
    regroupResults()
  }

  private func scheduleFilter() {
    filterTask?.cancel()
    let pending = query
    filterTask = _Concurrency.Task {
      try? await _Concurrency.Task.sleep(for: .milliseconds(200))
      guard !_Concurrency.Task.isCancelled else { return }
      debouncedQuery = pending.trimmingCharacters(in: .whitespacesAndNewlines)
      regroupResults()
    }
  }

  private func rebuildSearchIndex() {
    searchIndex = allTasks.map(SearchTaskIndexEntry.init)
  }

  private func regroupResults() {
    let q = debouncedQuery.lowercased()
    guard !q.isEmpty else {
      groupedResults = []
      return
    }

    let matched = searchIndex.filter { $0.matches(q) }.map(\.task)
    let today = TaskMapper.startOfDay(Date())
    var todayGroup: [Task] = []
    var upcomingGroup: [Task] = []
    var undatedGroup: [Task] = []

    for task in matched {
      guard let due = task.dueDate else {
        undatedGroup.append(task)
        continue
      }
      let day = TaskMapper.startOfDay(due)
      if day <= today { todayGroup.append(task) }
      else { upcomingGroup.append(task) }
    }

    var groups: [(String, [Task])] = []
    if !todayGroup.isEmpty { groups.append(("Hoje", todayGroup)) }
    if !upcomingGroup.isEmpty { groups.append(("Em breve", upcomingGroup)) }
    if !undatedGroup.isEmpty { groups.append(("Sem data", undatedGroup)) }
    groupedResults = groups
  }
}
