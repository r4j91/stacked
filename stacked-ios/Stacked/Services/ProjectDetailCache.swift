import Foundation

struct ProjectDetailSnapshot: Equatable {
  var sections: [ProjectSection]
  var pending: [Task]
  var completed: [Task]
}

@MainActor
final class ProjectDetailCache {
  static let shared = ProjectDetailCache()

  private var cache: [String: ProjectDetailSnapshot] = [:]
  private var inflight: [String: _Concurrency.Task<Void, Never>] = [:]

  private init() {}

  func snapshot(for projectId: String) -> ProjectDetailSnapshot? {
    cache[projectId]
  }

  func hasSnapshot(for projectId: String) -> Bool {
    cache[projectId] != nil
  }

  func prefetch(projectId: String) {
    guard cache[projectId] == nil, inflight[projectId] == nil else { return }
    inflight[projectId] = _Concurrency.Task {
      if let snap = await fetchSnapshot(projectId: projectId) {
        cache[projectId] = snap
      }
      inflight.removeValue(forKey: projectId)
    }
  }

  func store(projectId: String, sections: [ProjectSection], pending: [Task], completed: [Task]) {
    var nextPending = pending
    var nextCompleted = completed
    TaskMapper.refreshDisplayMemos(in: &nextPending)
    TaskMapper.refreshDisplayMemos(in: &nextCompleted)
    cache[projectId] = ProjectDetailSnapshot(
      sections: sections,
      pending: nextPending,
      completed: nextCompleted
    )
  }

  func applyTaskSnapshot(_ task: Task) {
    for (projectId, var snapshot) in cache {
      let pendingIndex = snapshot.pending.firstIndex { $0.id == task.id }
      let completedIndex = snapshot.completed.firstIndex { $0.id == task.id }
      snapshot.pending.removeAll { $0.id == task.id }
      snapshot.completed.removeAll { $0.id == task.id }
      if task.projectId == projectId {
        if task.done {
          snapshot.completed.insert(task, at: min(completedIndex ?? 0, snapshot.completed.count))
        } else {
          snapshot.pending.insert(task, at: min(pendingIndex ?? 0, snapshot.pending.count))
        }
      }
      cache[projectId] = snapshot
    }
  }

  /// Virada de dia: reavalia chips de todos os snapshots em memória.
  func refreshRelativeDateChips() {
    for (id, snap) in cache {
      var pending = snap.pending
      var completed = snap.completed
      TaskMapper.refreshDisplayMemos(in: &pending)
      TaskMapper.refreshDisplayMemos(in: &completed)
      cache[id] = ProjectDetailSnapshot(
        sections: snap.sections,
        pending: pending,
        completed: completed
      )
    }
  }

  private func fetchSnapshot(projectId: String) async -> ProjectDetailSnapshot? {
    do {
      async let sectionsReq = SectionRepository.shared.fetchSections(projectId: projectId)
      async let pendingReq = TaskRepository.shared.fetchTasksByProject(projectId)
      async let completedReq = TaskRepository.shared.fetchCompletedTasksByProject(projectId)
      return ProjectDetailSnapshot(
        sections: try await sectionsReq,
        pending: try await pendingReq,
        completed: try await completedReq
      )
    } catch {
      if AsyncLoad.isCancellation(error) { return nil }
      return nil
    }
  }
}
