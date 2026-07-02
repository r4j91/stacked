import SwiftUI
import Hugeicons

// Paridade lib/widgets/task_context_menu.dart
struct TaskContextMenu: ViewModifier {
  let task: Task
  var onEdit: () -> Void
  var onComplete: () -> Void
  var onDuplicate: () -> Void
  var onDelete: () -> Void
  var onRefresh: () -> Void

  @State private var anchorFrame: CGRect = .zero

  func body(content: Content) -> some View {
    content
      .readAnchor($anchorFrame)
      .onLongPressGesture(minimumDuration: 0.45) {
        HapticService.light()
        PopoverPresenter.shared.present(
          anchor: CGPoint(x: anchorFrame.midX, y: anchorFrame.midY),
          items: menuItems
        ) { result in
          guard let result else { return }
          handle(result)
        }
      }
  }

  private var menuItems: [PopoverMenuItem] {
    [
      PopoverMenuItem(id: "edit", icon: Hugeicons.edit01, label: "Editar"),
      PopoverMenuItem(id: "complete", icon: Hugeicons.checkmarkCircle01, label: "Concluir"),
      PopoverMenuItem(id: "duplicate", icon: Hugeicons.copy01, label: "Duplicar"),
      PopoverMenuItem(
        id: "priority",
        icon: Hugeicons.flag01,
        label: "Prioridade",
        hasArrow: true,
        children: [
          PopoverMenuItem(id: "priority:high", icon: Hugeicons.flag01, label: "Alta",
                          selected: task.priority == .high, iconColor: AppColors.priorityHigh),
          PopoverMenuItem(id: "priority:medium", icon: Hugeicons.flag01, label: "Média",
                          selected: task.priority == .medium, iconColor: AppColors.priorityMedium),
          PopoverMenuItem(id: "priority:low", icon: Hugeicons.flag01, label: "Baixa",
                          selected: task.priority == .low, iconColor: AppColors.priorityLow),
          PopoverMenuItem(id: "priority:none", icon: Hugeicons.flag01, label: "Sem prioridade",
                          selected: task.priority == nil, iconColor: Color(hex: 0x6B6E76)),
        ]
      ),
      PopoverMenuItem(
        id: "move",
        icon: Hugeicons.folder01,
        label: "Mover para projeto",
        hasArrow: true,
        loadChildren: { await loadMoveItems() }
      ),
      PopoverMenuItem(id: "delete", icon: Hugeicons.delete01, label: "Excluir", destructive: true),
    ]
  }

  private func loadMoveItems() async -> [PopoverMenuItem]? {
    let projects = (try? await ProjectRepository.shared.fetchProjects()) ?? []
    var items: [PopoverMenuItem] = [
      PopoverMenuItem(id: "move:|", icon: Hugeicons.inbox, label: "Sem projeto"),
    ]
    for project in projects {
      items.append(PopoverMenuItem(
        id: "move:\(project.id)|",
        icon: Hugeicons.folder01,
        label: project.name,
        hasArrow: true,
        loadChildren: {
          let sections = (try? await SectionRepository.shared.fetchSections(projectId: project.id)) ?? []
          guard !sections.isEmpty else { return nil }
          var sectionItems = [
            PopoverMenuItem(id: "move:\(project.id)|", icon: Hugeicons.arrowRight02, label: "Sem seção"),
          ]
          sectionItems += sections.map { s in
            PopoverMenuItem(id: "move:\(project.id)|\(s.id)", icon: Hugeicons.arrowRight02, label: s.name)
          }
          return sectionItems
        }
      ))
    }
    return items
  }

  private func handle(_ result: String) {
    if result.hasPrefix("priority:") {
      let raw = String(result.dropFirst("priority:".count))
      let priority: Priority? = raw == "none" ? nil : Priority(rawValue: raw)
      _Concurrency.Task {
        await TaskDetailPersistence.autosavePriority(taskId: task.id, priority: priority)
        onRefresh()
      }
      return
    }
    if result.hasPrefix("move:") {
      let payload = String(result.dropFirst(5))
      let parts = payload.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
      let projectId = parts.first.flatMap { $0.isEmpty ? nil : $0 }
      let sectionId = parts.count > 1 ? (parts[1].isEmpty ? nil : parts[1]) : nil
      _Concurrency.Task {
        try? await TaskRepository.shared.updateTaskProject(id: task.id, projectId: projectId, sectionId: sectionId)
        onRefresh()
      }
      return
    }
    switch result {
    case "edit": onEdit()
    case "complete": onComplete()
    case "duplicate": onDuplicate()
    case "delete": onDelete()
    default: break
    }
  }
}

extension View {
  func taskContextMenu(
    task: Task,
    onEdit: @escaping () -> Void,
    onComplete: @escaping () -> Void,
    onDuplicate: @escaping () -> Void,
    onDelete: @escaping () -> Void,
    onRefresh: @escaping () -> Void = {}
  ) -> some View {
    modifier(TaskContextMenu(
      task: task,
      onEdit: onEdit,
      onComplete: onComplete,
      onDuplicate: onDuplicate,
      onDelete: onDelete,
      onRefresh: onRefresh
    ))
  }
}
