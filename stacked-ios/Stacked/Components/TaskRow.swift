import SwiftUI

// Paridade task_tile.dart — card + expansão inline de subtarefas
struct TaskRow: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.openTaskContextMenu) private var openTaskContextMenu

  let task: Task
  var style: TaskRowStyle = .card
  var showProject: Bool = true
  var allLabels: [TaskLabel] = []
  var onToggle: () -> Void
  var onTap: (() -> Void)?
  var onSubtaskTap: ((Subtask) -> Void)?
  var onSubtaskChanged: (() -> Void)?

  @State private var expanded = false
  @State private var subtasksDone: [Bool] = []
  @State private var labelCatalog: [TaskLabel] = []

  var body: some View {
    switch style {
    case .card: cardBody
    case .list: listBody
    }
  }

  private var cardBody: some View {
    let c = theme.colors

    return VStack(spacing: 0) {
      rowHeader(expandTrailing: 8, expandTop: 8)

      subtasksExpansion
    }
    .frame(minHeight: AppLayout.taskRowHeight)
    .background(c.surface)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .accessibilityElement(children: .combine)
    .accessibilityLabel(taskAccessibilityLabel)
    .accessibilityHint(taskAccessibilityHint)
    .onAppear { syncSubtasks() }
    .onChange(of: task.subtasks) { _, _ in syncSubtasks() }
    .task(id: task.id) {
      guard task.subtasks.contains(where: { !$0.labelIds.isEmpty }), allLabels.isEmpty else { return }
      // SUBSTITUIDO_FASE5: fetch por row — LabelRepository.shared.fetchLabels()
      labelCatalog = await LabelCatalogCache.labels()
    }
  }

  private var listBody: some View {
    let c = theme.colors

    return VStack(spacing: 0) {
      rowHeader(expandTrailing: 12, expandTop: 8)
        .opacity(task.done ? 0.45 : 1)

      subtasksExpansion

      Divider().overlay(c.textTertiary.opacity(0.12))
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(taskAccessibilityLabel)
    .accessibilityHint(taskAccessibilityHint)
    .onAppear { syncSubtasks() }
    .onChange(of: task.subtasks) { _, _ in syncSubtasks() }
    .task(id: task.id) {
      guard task.subtasks.contains(where: { !$0.labelIds.isEmpty }), allLabels.isEmpty else { return }
      // SUBSTITUIDO_FASE5: fetch por row — LabelRepository.shared.fetchLabels()
      labelCatalog = await LabelCatalogCache.labels()
    }
  }

  private func rowHeader(expandTrailing: CGFloat, expandTop: CGFloat) -> some View {
    let expandReserve: CGFloat = task.hasSubtasks ? 40 : 0

    return ZStack(alignment: .topLeading) {
      taskContentTapArea(expandReserve: expandReserve)

      HStack(alignment: .top, spacing: 0) {
        // SUBSTITUIDO_FASE3C: onTapGesture na VStack de conteúdo
        Button(action: onToggle) {
          PriorityDot(priority: task.priority, done: task.done)
            .padding(12)
        }
        .buttonStyle(PressableStyle(onPrepare: HapticService.prepareTaskComplete))
        .accessibilityLabel(task.done ? "Reabrir tarefa" : "Concluir tarefa")
        .accessibilityHint("Toque duas vezes para \(task.done ? "reabrir" : "concluir")")

        Spacer(minLength: 0)

        if task.hasSubtasks {
          expandButton
            .padding(.trailing, expandTrailing)
            .padding(.top, expandTop)
        }
      }
    }
    .frame(minHeight: AppLayout.taskRowHeight)
  }

  @ViewBuilder
  private func taskContentTapArea(expandReserve: CGFloat) -> some View {
    let content = HStack(alignment: .top, spacing: 0) {
      Color.clear.frame(width: 46)
      rowTextContent
        .padding(.vertical, 10)
        .padding(.trailing, task.hasSubtasks ? 4 : 14)
        .frame(maxWidth: .infinity, alignment: .leading)
      if task.hasSubtasks {
        Color.clear.frame(width: expandReserve)
      }
    }
    .contentShape(Rectangle())

    if let onTap, let openTaskContextMenu {
      // Long-press exclusivo antes do tap: evita abrir TaskDetail ao soltar após o menu.
      content.gesture(
        LongPressGesture(minimumDuration: TaskContextLift.minimumDuration)
          .onEnded { _ in openTaskContextMenu() }
          .exclusively(before: TapGesture().onEnded { onTap() })
      )
    } else if let onTap {
      content.onTapGesture(perform: onTap)
    } else {
      content
    }
  }

  @ViewBuilder
  private var subtasksExpansion: some View {
    if task.hasSubtasks {
      SubtaskExpandReveal(expanded: expanded, reduceMotion: reduceMotion) {
        subtaskList
      }
    }
  }

  @ViewBuilder
  private var rowTextContent: some View {
    let c = theme.colors
    VStack(alignment: .leading, spacing: 0) {
      titleRow
      if style == .card, let desc = task.description, !desc.isEmpty {
        Text(desc)
          .font(AppTypography.taskPreview)
          .foregroundStyle(c.textTertiary)
          .lineLimit(1)
          .padding(.top, 4)
      }
      TaskMetaLine(
        labels: task.labels,
        dueDate: task.dueDate,
        dueDateLabel: task.dueDateChipLabel,
        dueDateColor: task.dueDateChipColor,
        subtasksDone: subtasksDone.filter { $0 }.count,
        subtasksTotal: subtasksDone.count,
        commentCount: task.commentCount,
        projectName: showProject ? task.project : nil
      )
    }
  }

  private var titleRow: some View {
    let c = theme.colors
    return HStack(alignment: .firstTextBaseline, spacing: 6) {
      Text(task.title)
        .font(AppTypography.taskTitle)
        .foregroundStyle(task.done ? c.textTertiary : c.textPrimary)
        .strikethrough(task.done, color: c.textTertiary)
        .lineLimit(2)
        .layoutPriority(1)

      Spacer(minLength: 4)

      if let timeDisplay = task.timeDisplay {
        HStack(spacing: 2) {
          StackedIcons.icon(.clock, size: 11, color: c.textTertiary)
          // SUBSTITUIDO_FASE5: TaskMapper.formatTimeDisplay(time) no body
          Text(timeDisplay)
            .font(AppTypography.timeChip)
            .foregroundStyle(c.textTertiary)
        }
        .fixedSize()
      }
    }
  }

  private var expandButton: some View {
    let c = theme.colors
    return Button {
      HapticService.selection()
      expanded.toggle()
    } label: {
      StackedIcons.image(.chevronDown)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(c.textTertiary)
        .rotationEffect(.degrees(expanded ? 180 : 0))
        .animation(AppMotion.subtaskExpand(reduceMotion: reduceMotion), value: expanded)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(expanded ? "Recolher subtarefas" : "Expandir subtarefas")
    .accessibilityValue("\(subtasksDone.filter { $0 }.count) de \(subtasksDone.count) concluídas")
  }

  private var subtaskList: some View {
    let c = theme.colors
    return VStack(spacing: 0) {
      Divider().overlay(c.surfaceVariant)
      ForEach(Array(task.subtasks.enumerated()), id: \.element.idOrFallback) { index, sub in
        let done = index < subtasksDone.count ? subtasksDone[index] : sub.done
        let labels = resolvedLabels(for: sub)
        let hasExtra = (sub.description?.isEmpty == false) || sub.dueDate != nil || !labels.isEmpty
        HStack(alignment: hasExtra ? .top : .center, spacing: 0) {
          Button { toggleSubtask(at: index, sub: sub) } label: {
            subtaskDot(sub: sub, done: done)
              .padding(.horizontal, 4)
              .padding(.vertical, hasExtra ? 13 : 0)
          }
          .buttonStyle(PressableStyle(onPrepare: HapticService.prepareTaskComplete))

          Button {
            onSubtaskTap?(sub)
          } label: {
            VStack(alignment: .leading, spacing: 0) {
              Text(sub.title)
                .font(AppTypography.subtaskRowTitle)
                .foregroundStyle(done ? c.textTertiary : c.textPrimary.opacity(0.88))
                .strikethrough(done)
              if let desc = sub.description, !desc.isEmpty {
                Text(desc)
                  .font(AppTypography.subtaskPreview)
                  .foregroundStyle(c.textSecondary.opacity(done ? 0.55 : 0.85))
                  .lineLimit(2)
                  .padding(.top, 2)
              }
              if hasExtra {
                TaskMetaLine(
                  labels: labels,
                  dueDate: sub.dueDate,
                  dueDateLabel: sub.dueDateChipLabel,
                  dueDateColor: sub.dueDateChipColor
                )
              }
            }
            .padding(.vertical, hasExtra ? 9 : 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
          }
          .buttonStyle(PressableStyle())
          .disabled(onSubtaskTap == nil)
        }
        .padding(.leading, 36)
        .padding(.trailing, 12)

        if index < task.subtasks.count - 1 {
          Divider().overlay(c.textTertiary.opacity(0.08)).padding(.leading, 36)
        }
      }
      Color.clear.frame(height: 4)
    }
    .background(c.surfaceVariant.opacity(style == .card ? 0.45 : 0))
  }

  private func subtaskDot(sub: Subtask, done: Bool) -> some View {
    DoneCircle(
      done: done,
      size: 18,
      borderWidth: DoneCircle.RingStyle.borderWidth,
      tickSize: 10,
      ringColor: sub.priority?.color ?? theme.colors.textTertiary,
      ringFillAlpha: done ? 0 : DoneCircle.RingStyle.inactiveFillAlpha
    )
  }

  private func resolvedLabels(for sub: Subtask) -> [TaskLabel] {
    let source = !allLabels.isEmpty ? allLabels : labelCatalog
    return sub.labelIds.compactMap { id in source.first(where: { $0.id == id }) }
  }

  private func syncSubtasks() {
    subtasksDone = task.subtasks.map(\.done)
  }

  private func toggleSubtask(at index: Int, sub: Subtask) {
    guard let id = sub.id, index < subtasksDone.count else { return }
    let newDone = !subtasksDone[index]
    if newDone {
      HapticService.taskCompleted()
    } else {
      HapticService.light()
    }
    subtasksDone[index] = newDone
    _Concurrency.Task {
      try? await SubtaskRepository.shared.toggleDone(id: id, done: newDone)
      onSubtaskChanged?()
    }
  }

  private var taskAccessibilityLabel: String {
    var parts = [task.title]
    if task.done { parts.append("concluída") }
    if showProject, !task.project.isEmpty {
      parts.append("projeto \(task.project)")
    }
    if let due = task.dueDateChipLabel { parts.append("vencimento \(due)") }
    if task.hasSubtasks {
      let done = subtasksDone.filter { $0 }.count
      parts.append("\(done) de \(subtasksDone.count) subtarefas concluídas")
    }
    return parts.joined(separator: ", ")
  }

  private var taskAccessibilityHint: String {
    if onTap != nil { return "Toque para abrir detalhes. Pressione e segure para mais opções." }
    return ""
  }
}

// SUBSTITUIDO_FASE3D: subtaskList com frame(maxHeight:) + clip + opacity + .animation no VStack pai
// if task.hasSubtasks {
//   subtaskList
//     .frame(maxHeight: expanded ? nil : 0, alignment: .top)
//     .clipped()
//     .opacity(expanded ? 1 : 0)
//     .allowsHitTesting(expanded)
// }
// .animation(AppMotion.smooth(reduceMotion: reduceMotion), value: expanded)

enum TaskRowStyle {
  case card
  case list
}

struct PriorityDot: View {
  @Environment(ThemeManager.self) private var theme
  let priority: Priority?
  let done: Bool

  var body: some View {
    DoneCircle(
      done: done,
      size: 22,
      borderWidth: DoneCircle.RingStyle.borderWidth,
      tickSize: 10,
      ringColor: priority?.color ?? theme.colors.textTertiary,
      ringFillAlpha: done ? 0 : DoneCircle.RingStyle.inactiveFillAlpha
    )
    .accessibilityHidden(true)
  }
}
