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
    cache[projectId] = ProjectDetailSnapshot(sections: sections, pending: pending, completed: completed)
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
