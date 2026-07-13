import SwiftUI
import Hugeicons

// Fase 4A — lift progressivo estilo Flutter task_context_menu.dart
enum TaskContextLift {
  static let minimumDuration: Double = 0.35
  static let scale: CGFloat = 1.02
  static let offsetY: CGFloat = -5
  static let shadowOpacity: Double = 0.16
  static let shadowRadius: CGFloat = 10
  static let shadowY: CGFloat = 5
}

private enum TaskContextLiftPhase: Equatable {
  case normal
  case pressing
  case menuOpen
}

// Paridade lib/widgets/task_context_menu.dart
struct TaskContextMenu: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let task: Task
  var onEdit: () -> Void
  var onComplete: () -> Void
  var onDuplicate: () -> Void
  var onDelete: () -> Void
  var onRefresh: () -> Void

  @State private var anchorFrame: CGRect = .zero
  @State private var anchorCaptureGeneration = 0
  @State private var liftPhase: TaskContextLiftPhase = .normal
  /// PERF_FASEB2_ETAPA4: UIViewRepresentable só após long-press — zero custo no scroll idle.
  @State private var needsAnchorReader = false

  func body(content: Content) -> some View {
    content
      .background {
        // PERF_FASEB2_ETAPA4: OnDemandScreenBoundsReader sempre no background de cada célula.
        // OnDemandScreenBoundsReader(captureGeneration: anchorCaptureGeneration, rect: $anchorFrame)
        //   .frame(maxWidth: .infinity, maxHeight: .infinity)
        //   .allowsHitTesting(false)
        if needsAnchorReader {
          OnDemandScreenBoundsReader(captureGeneration: anchorCaptureGeneration, rect: $anchorFrame)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
        }
      }
      .scaleEffect(liftScale)
      .offset(y: liftOffset)
      .shadow(
        color: .black.opacity(isLifted && !reduceMotion ? TaskContextLift.shadowOpacity : 0),
        radius: isLifted && !reduceMotion ? TaskContextLift.shadowRadius : 0,
        y: isLifted && !reduceMotion ? TaskContextLift.shadowY : 0
      )
      .zIndex(isLifted ? 1 : 0)
      .animation(isLifted ? AppMotion.smooth(reduceMotion: reduceMotion) : nil, value: liftPhase)
      // TaskRow usa long-press exclusivo antes do tap na área de conteúdo; aqui só expõe a ação.
      .environment(\.openTaskContextMenu, openContextMenu)
  }

  private var isLifted: Bool {
    liftPhase != .normal
  }

  private var liftScale: CGFloat {
    guard !reduceMotion, isLifted else { return 1 }
    return TaskContextLift.scale
  }

  private var liftOffset: CGFloat {
    guard !reduceMotion, isLifted else { return 0 }
    return TaskContextLift.offsetY
  }

  private func openContextMenu() {
    HapticService.prepareContextMenu()
    HapticService.medium()
    // Instala o reader antes do yield de captura.
    needsAnchorReader = true
    AppMotion.animate(AppMotion.smooth, reduceMotion: reduceMotion) {
      liftPhase = .menuOpen
    }
    let generation = anchorCaptureGeneration + 1
    anchorCaptureGeneration = generation
    _Concurrency.Task { @MainActor in
      // Dois yields: monta o reader + captura o anchor antes do popover.
      await _Concurrency.Task.yield()
      await _Concurrency.Task.yield()
      guard generation == anchorCaptureGeneration else { return }
      let screenH = ScreenMetrics.bounds.height
      let preferAbove = anchorFrame.midY > screenH * 0.55
      presentAnchoredPopover(
        anchorRect: anchorFrame,
        items: menuItems,
        preferAbove: preferAbove
      ) { result in
        AppMotion.animate(AppMotion.smooth, reduceMotion: reduceMotion) {
          liftPhase = .normal
        }
        guard let result else { return }
        handle(result)
      }
    }
  }

  private var menuItems: [PopoverMenuItem] {
    [
      PopoverMenuItem(id: "edit", icon: Hugeicons.edit01, label: "Editar"),
      PopoverMenuItem(
        id: "complete",
        icon: Hugeicons.checkmarkCircle01,
        label: task.done ? "Reabrir" : "Concluir"
      ),
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
        iconColor: project.color,
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

// SUBSTITUIDO_FASE4A: onLongPressGesture(0.45) sem lift + HapticService.light()
// .onLongPressGesture(minimumDuration: 0.45) {
//   HapticService.light()
//   PopoverPresenter.shared.present(...) { result in ... }
// }

private struct OpenTaskContextMenuKey: EnvironmentKey {
  static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
  var openTaskContextMenu: (() -> Void)? {
    get { self[OpenTaskContextMenuKey.self] }
    set { self[OpenTaskContextMenuKey.self] = newValue }
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
