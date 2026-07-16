import Foundation
import SwiftUI

/// Estado compartilhado entre hosts separados (header fixo × painel expansível).
/// UIKIT_SCROLL_POLISH: um único UIHostingConfiguration fazia o self-sizing
/// recalcular o chevron junto com a altura do painel.
final class TaskRowSplitSession: ObservableObject {
  @Published var expanded: Bool
  @Published var subtaskRevealActive: Bool
  @Published var subtaskRevealLayoutPass: Int
  @Published var snapRevealOpen: Bool
  @Published var displaySubtasks: [Subtask]
  @Published var subtasksDone: [Bool]
  @Published var subtaskSortHoldId: String?
  @Published var labelCatalog: [TaskLabel]

  var subtaskReorderTask: _Concurrency.Task<Void, Never>?

  /// Sentinel para `ObservedObject` quando a row não está em modo split.
  static let unused = TaskRowSplitSession(placeholder: true)

  init(placeholder: Bool = false) {
    expanded = false
    subtaskRevealActive = false
    subtaskRevealLayoutPass = 0
    snapRevealOpen = false
    displaySubtasks = []
    subtasksDone = []
    subtaskSortHoldId = nil
    labelCatalog = []
    if placeholder { return }
  }

  func seed(from task: Task, restoreExpansion: Bool) {
    let wantOpen =
      restoreExpansion
      && task.hasSubtasks
      && ProjectDetailPreferences.isSubtaskListExpanded(taskId: task.id)
    if wantOpen {
      let sorted = TaskMapper.sortSubtasksForDisplay(task.subtasks)
      expanded = true
      subtaskRevealActive = true
      snapRevealOpen = true
      displaySubtasks = sorted
      subtasksDone = sorted.map(\.done)
    } else {
      expanded = false
      subtaskRevealActive = false
      snapRevealOpen = false
      displaySubtasks = []
      subtasksDone = []
    }
    subtaskRevealLayoutPass = 0
    subtaskSortHoldId = nil
    labelCatalog = []
    subtaskReorderTask?.cancel()
    subtaskReorderTask = nil
  }

  func resetIdentity() {
    displaySubtasks = []
    subtasksDone = []
    expanded = false
    subtaskRevealActive = false
    snapRevealOpen = false
    subtaskSortHoldId = nil
    subtaskReorderTask?.cancel()
    subtaskReorderTask = nil
  }
}

enum TaskRowBodyMode {
  /// Header + painel no mesmo host (SwiftUI List / default).
  case full
  /// Só o header (chevron). Altura fixa — fora do self-sizing do painel.
  case headerOnly
  /// Só o painel `SubtaskExpandReveal`.
  case panelOnly
}
