import Foundation

// FASE5: cache simples — uma carga em lote para labels de subtarefas (sem fetch por row).
@MainActor
enum LabelCatalogCache {
  private static var cache: [TaskLabel]?
  private static var inFlight: _Concurrency.Task<[TaskLabel], Never>?

  static func labels() async -> [TaskLabel] {
    if let cache { return cache }
    if let inFlight { return await inFlight.value }
    let task = _Concurrency.Task { @MainActor in
      let fetched = (try? await LabelRepository.shared.fetchLabels()) ?? []
      cache = fetched
      return fetched
    }
    inFlight = task
    let result = await task.value
    inFlight = nil
    return result
  }

  static func invalidate() {
    cache = nil
  }
}
