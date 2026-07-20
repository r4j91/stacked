import SwiftUI

/// Subtarefa agendada / filtrada (Hoje · Em breve · Filtros).
/// Renderiza via `TaskRow` com snapshot sintético — mesma altura, tipografia e chrome
/// das tarefas-pai no modo atual (Balões / Lista / Lista+).
struct FilterSubtaskRow: View {
  let subtask: Subtask
  let parent: Task
  let labelCatalog: [TaskLabel]
  var style: TaskRowStyle = .card
  /// UIKit host: hit-test estável (paridade TaskRow nas cells).
  var stabilizeInUIKitCell: Bool = false
  var onToggle: () -> Void
  var onTap: () -> Void

  var body: some View {
    TaskRow(
      task: displayTask,
      style: style,
      showProject: true,
      allLabels: resolvedLabelCatalog,
      restoreExpansionOnAppear: false,
      stabilizeExpandInSelfSizingCell: stabilizeInUIKitCell,
      onToggle: onToggle,
      onTap: onTap
    )
  }

  /// Catálogo para resolver `labelIds` da subtarefa (paridade TaskRow).
  private var resolvedLabelCatalog: [TaskLabel] {
    if !labelCatalog.isEmpty { return labelCatalog }
    return parent.labels
  }

  private var resolvedLabels: [TaskLabel] {
    let source = resolvedLabelCatalog
    return subtask.labelIds.compactMap { id in source.first(where: { $0.id == id }) }
  }

  /// Projeto no eyebrow/meta — igual às tarefas da agenda (ex.: "Rodrigo", "Financeiro").
  private var displayProject: String {
    let project = parent.project
    if !project.isEmpty, project != "Sem projeto" { return project }
    if !parent.title.isEmpty { return parent.title }
    return "Sem projeto"
  }

  private var displayTask: Task {
    Task(
      id: subtask.idOrFallback,
      title: subtask.title,
      description: subtask.description,
      project: displayProject,
      projectId: parent.projectId,
      sectionId: nil,
      priority: subtask.priority,
      time: subtask.time,
      timeDisplay: subtask.timeDisplay,
      labels: resolvedLabels,
      subtasks: [],
      dueDate: subtask.dueDate,
      dueDateChipLabel: subtask.dueDateChipLabel,
      dueDateChipColor: subtask.dueDateChipColor,
      done: subtask.done,
      commentCount: 0,
      recurrence: nil,
      whatsappRoutine: false,
      subtasksDoneCount: 0,
      subtasksTotalCount: 0,
      subtasksCounterLabel: nil
    )
  }
}
