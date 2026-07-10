import Foundation

// Paridade lib/services/project_detail_preferences.dart — estado de UI do detalhe do projeto.
enum ProjectDetailPreferences {
  static func collapsedSectionsKey(projectId: String) -> String {
    "proj_detail_collapsed_sections_\(projectId)"
  }

  static func completedExpandedKey(projectId: String) -> String {
    "proj_detail_completed_expanded_\(projectId)"
  }

  static func collapsedSectionIds(projectId: String) -> Set<String> {
    let key = collapsedSectionsKey(projectId: projectId)
    guard let raw = UserDefaults.standard.array(forKey: key) as? [String] else { return [] }
    return Set(raw)
  }

  static func setCollapsedSectionIds(_ ids: Set<String>, projectId: String) {
    UserDefaults.standard.set(Array(ids), forKey: collapsedSectionsKey(projectId: projectId))
  }

  static func completedExpanded(projectId: String, default defaultValue: Bool = false) -> Bool {
    let key = completedExpandedKey(projectId: projectId)
    guard UserDefaults.standard.object(forKey: key) != nil else { return defaultValue }
    return UserDefaults.standard.bool(forKey: key)
  }

  static func setCompletedExpanded(_ value: Bool, projectId: String) {
    UserDefaults.standard.set(value, forKey: completedExpandedKey(projectId: projectId))
  }

  // MARK: - Subtarefas inline expandidas (global)

  private static let expandedSubtaskTasksKey = "subtask_expanded_task_ids"

  static func expandedSubtaskTaskIds() -> Set<String> {
    guard let raw = UserDefaults.standard.array(forKey: expandedSubtaskTasksKey) as? [String] else { return [] }
    return Set(raw)
  }

  static func isSubtaskListExpanded(taskId: String) -> Bool {
    expandedSubtaskTaskIds().contains(taskId)
  }

  static func setSubtaskListExpanded(_ expanded: Bool, taskId: String) {
    var ids = expandedSubtaskTaskIds()
    if expanded, !taskId.isEmpty {
      ids.insert(taskId)
    } else {
      ids.remove(taskId)
    }
    UserDefaults.standard.set(Array(ids), forKey: expandedSubtaskTasksKey)
  }
}
