import SwiftUI
import Hugeicons

// Fase 4A — lift progressivo estilo Flutter task_context_menu.dart
enum TaskContextLift {
  static let minimumDuration: Double = 0.35
  static let scale: CGFloat = 1.02
  static let offsetY: CGFloat = -5
  static let shadowOpacity: Double = 0
  static let shadowRadius: CGFloat = 10
  static let shadowY: CGFloat = 5
}

enum TaskContextLiftPhase: Equatable {
  case normal
  case pressing
  case menuOpen
}

/// Estado compartilhado — âncora no header; lift visual no container da TaskRow.
@MainActor
@Observable
final class TaskContextMenuModel {
  var liftPhase: TaskContextLiftPhase = .normal
  var needsAnchorReader = false
  var anchorFrame: CGRect = .zero
  var anchorCaptureGeneration = 0
  /// Seleção de etiquetas na sessão do submenu (ordem MRU: última tocada primeiro).
  var pendingLabelIds: [String]?

  var isLifted: Bool { liftPhase != .normal }
}

private struct TaskContextMenuModelKey: EnvironmentKey {
  static let defaultValue: TaskContextMenuModel? = nil
}

extension EnvironmentValues {
  var taskContextMenuModel: TaskContextMenuModel? {
    get { self[TaskContextMenuModelKey.self] }
    set { self[TaskContextMenuModelKey.self] = newValue }
  }
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
  /// nil esconde "Adiar" do menu — telas de tarefas concluídas não postergam.
  var onPostpone: (() -> Void)? = nil
  /// UIKIT_SCROLL_POLISH: lift no container UIKit (split) — não no SwiftUI interno.
  var onLiftPhaseChanged: ((TaskContextLiftPhase) -> Void)? = nil

  @State private var model = TaskContextMenuModel()

  func body(content: Content) -> some View {
    // Ambiente só — lift no container; âncora no header (TaskRow).
    content
      .environment(\.taskContextMenuModel, model)
      .environment(\.openTaskContextMenu, { openContextMenu(at: $0) })
      // UIKIT_SCROLL_POLISH: LiftHost interno vira no-op quando o split anima o card.
      .environment(\.taskContextMenuExternalLift, onLiftPhaseChanged != nil)
      .onChange(of: model.liftPhase) { _, phase in
        onLiftPhaseChanged?(phase)
      }
  }

  private func openContextMenu(at pressLocation: CGPoint? = nil) {
    HapticService.prepareContextMenu()
    HapticService.medium()
    model.needsAnchorReader = true
    AppMotion.animate(AppMotion.smooth, reduceMotion: reduceMotion) {
      model.liftPhase = .menuOpen
    }
    // CTXMENU_ANCHOR_FIX: zera frame da abertura anterior (evita menu "preso" na 1ª tarefa).
    model.anchorFrame = .zero
    let generation = model.anchorCaptureGeneration + 1
    model.anchorCaptureGeneration = generation
    _Concurrency.Task { @MainActor in
      var resolved = CGRect.zero
      for attempt in 0..<16 {
        if attempt > 0 {
          try? await _Concurrency.Task.sleep(for: .milliseconds(8))
        } else {
          await _Concurrency.Task.yield()
          await _Concurrency.Task.yield()
        }
        guard generation == model.anchorCaptureGeneration else { return }
        if model.anchorFrame.isValidAnchor {
          resolved = model.anchorFrame
          break
        }
      }
      guard generation == model.anchorCaptureGeneration else { return }
      if !resolved.isValidAnchor, let pressLocation {
        resolved = CGRect(x: pressLocation.x - 22, y: pressLocation.y - 22, width: 44, height: 44)
      }
      let screenH = ScreenMetrics.bounds.height
      let preferAbove = (resolved.isValidAnchor ? resolved.midY : screenH * 0.5) > screenH * 0.55
      presentAnchoredPopover(
        anchorRect: resolved,
        items: menuItems,
        preferAbove: preferAbove
      ) { result in
        AppMotion.animate(AppMotion.smooth, reduceMotion: reduceMotion) {
          model.liftPhase = .normal
        }
        model.needsAnchorReader = false
        guard let result else { return }
        handle(result)
      }
    }
  }

  private var menuItems: [PopoverMenuItem] {
    var items: [PopoverMenuItem] = [
      PopoverMenuItem(id: "edit", icon: Hugeicons.edit01, label: "Editar"),
      PopoverMenuItem(
        id: "complete",
        icon: Hugeicons.checkmarkCircle01,
        label: task.done ? "Reabrir" : "Concluir"
      ),
    ]
    if onPostpone != nil {
      items.append(PopoverMenuItem(id: "postpone", icon: Hugeicons.clock01, label: "Adiar"))
    }
    items.append(PopoverMenuItem(id: "duplicate", icon: Hugeicons.copy01, label: "Duplicar"))
    items.append(
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
                          selected: task.priority == nil, iconColor: ThemeManager.shared.colors.textTertiary),
        ]
      )
    )
    items.append(
      PopoverMenuItem(
        id: "labels",
        icon: Hugeicons.tag01,
        label: "Etiquetas (\(task.labels.count))",
        hasArrow: true,
        loadChildren: { await loadLabelItems() },
        childrenAllowToggle: true
      )
    )
    items.append(
      PopoverMenuItem(
        id: "move",
        icon: Hugeicons.folder01,
        label: "Mover para projeto",
        hasArrow: true,
        loadChildren: { await loadMoveItems() }
      )
    )
    items.append(PopoverMenuItem(id: "delete", icon: Hugeicons.delete01, label: "Excluir", destructive: true))
    return items
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
            PopoverMenuItem(id: "move:\(project.id)|", icon: Hugeicons.chevronRight, label: "Sem seção"),
          ]
          sectionItems += sections.map { s in
            PopoverMenuItem(id: "move:\(project.id)|\(s.id)", icon: Hugeicons.chevronRight, label: s.name)
          }
          return sectionItems
        }
      ))
    }
    return items
  }

  /// Catálogo carregado sob demanda (LabelCatalogCache) — checkmarks refletem as etiquetas atuais da task.
  private func loadLabelItems() async -> [PopoverMenuItem]? {
    let labels = await LabelCatalogCache.labels()
    guard !labels.isEmpty else { return nil }
    let current = task.labels.map(\.id)
    model.pendingLabelIds = current
    let selected = Set(current)
    return labels.map { label in
      PopoverMenuItem(
        id: "label:\(label.id)",
        icon: Hugeicons.tag01,
        label: label.name,
        selected: selected.contains(label.id),
        iconColor: label.color
      )
    }
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
    if result.hasPrefix("label:") {
      let labelId = String(result.dropFirst("label:".count))
      let current = model.pendingLabelIds ?? task.labels.map(\.id)
      let next = LabelIdOrder.toggle(current, id: labelId)
      model.pendingLabelIds = next
      _Concurrency.Task {
        try? await LabelRepository.shared.setTaskLabels(taskId: task.id, labelIds: next)
        onRefresh()
      }
      return
    }
    switch result {
    case "edit": onEdit()
    case "complete": onComplete()
    case "postpone": onPostpone?()
    case "duplicate": onDuplicate()
    case "delete": onDelete()
    default: break
    }
  }
}

/// Lift visual do container (card/lista) — paridade Todoist: sobe o bloco inteiro.
struct TaskContextMenuLiftHost: ViewModifier {
  @Environment(\.taskContextMenuModel) private var model
  @Environment(\.taskContextMenuExternalLift) private var externalLift
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @ViewBuilder
  func body(content: Content) -> some View {
    // UIKIT_SCROLL_POLISH: no split, transform/sombra vêm do UIKitSplitTaskRowView.
    if externalLift {
      content
    } else if let model {
      let lifted = model.isLifted
      content
        .scaleEffect(!reduceMotion && lifted ? TaskContextLift.scale : 1)
        .offset(y: !reduceMotion && lifted ? TaskContextLift.offsetY : 0)
        .shadow(
          color: .black.opacity(!reduceMotion && lifted ? TaskContextLift.shadowOpacity : 0),
          radius: !reduceMotion && lifted ? TaskContextLift.shadowRadius : 0,
          y: !reduceMotion && lifted ? TaskContextLift.shadowY : 0
        )
        .zIndex(lifted ? 1 : 0)
        .animation(lifted ? AppMotion.smooth(reduceMotion: reduceMotion) : nil, value: model.liftPhase)
    } else {
      content
    }
  }
}

/// Reader de âncora só no header — menu não “prende” no meio das subtarefas.
struct TaskContextMenuAnchorHost: ViewModifier {
  @Environment(\.taskContextMenuModel) private var model

  @ViewBuilder
  func body(content: Content) -> some View {
    if let model {
      content
        .background {
          if model.needsAnchorReader {
            OnDemandScreenBoundsReader(
              captureGeneration: model.anchorCaptureGeneration,
              rect: Binding(
                get: { model.anchorFrame },
                set: { model.anchorFrame = $0 }
              )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
          }
        }
    } else {
      content
    }
  }
}

// SUBSTITUIDO_FASE4A: onLongPressGesture(0.45) sem lift + HapticService.light()
// .onLongPressGesture(minimumDuration: 0.45) {
//   HapticService.light()
//   PopoverPresenter.shared.present(...) { result in ... }
// }

private struct OpenTaskContextMenuKey: EnvironmentKey {
  static let defaultValue: ((CGPoint?) -> Void)? = nil
}

private struct TaskContextMenuExternalLiftKey: EnvironmentKey {
  static let defaultValue = false
}

extension EnvironmentValues {
  var openTaskContextMenu: ((CGPoint?) -> Void)? {
    get { self[OpenTaskContextMenuKey.self] }
    set { self[OpenTaskContextMenuKey.self] = newValue }
  }

  /// UIKIT_SCROLL_POLISH: true quando o lift é animado no UIKitSplitTaskRowView.
  var taskContextMenuExternalLift: Bool {
    get { self[TaskContextMenuExternalLiftKey.self] }
    set { self[TaskContextMenuExternalLiftKey.self] = newValue }
  }
}

extension View {
  func taskContextMenu(
    task: Task,
    onEdit: @escaping () -> Void,
    onComplete: @escaping () -> Void,
    onDuplicate: @escaping () -> Void,
    onDelete: @escaping () -> Void,
    onRefresh: @escaping () -> Void = {},
    onPostpone: (() -> Void)? = nil,
    onLiftPhaseChanged: ((TaskContextLiftPhase) -> Void)? = nil
  ) -> some View {
    modifier(TaskContextMenu(
      task: task,
      onEdit: onEdit,
      onComplete: onComplete,
      onDuplicate: onDuplicate,
      onDelete: onDelete,
      onRefresh: onRefresh,
      onPostpone: onPostpone,
      onLiftPhaseChanged: onLiftPhaseChanged
    ))
  }

  /// Lift do container da TaskRow (card inteiro).
  func taskContextMenuLiftHost() -> some View {
    modifier(TaskContextMenuLiftHost())
  }

  /// Âncora do popover — header da TaskRow.
  func taskContextMenuAnchorHost() -> some View {
    modifier(TaskContextMenuAnchorHost())
  }
}
