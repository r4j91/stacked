import SwiftUI

// Paridade task_tile.dart — card + expansão inline de subtarefas
struct TaskRow: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.openTaskContextMenu) private var openTaskContextMenu

  let task: Task
  var style: TaskRowStyle = .card
  var flatSubtaskPanel: Bool = false
  var showProject: Bool = true
  var allLabels: [TaskLabel] = []
  var deferHeavyWork: Bool = false
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
    .onAppear {
      guard !deferHeavyWork else { return }
      syncSubtasks()
    }
    .onChange(of: task.subtasks) { _, _ in
      guard !deferHeavyWork else { return }
      syncSubtasks()
    }
    .onChange(of: deferHeavyWork) { _, deferred in
      guard !deferred else { return }
      syncSubtasks()
    }
    .task(id: task.id) {
      guard !deferHeavyWork, task.hasSubtasks, allLabels.isEmpty else { return }
      labelCatalog = await LabelCatalogCache.labels()
    }
  }

  private var listBody: some View {
    let c = theme.colors

    return VStack(spacing: 0) {
      rowHeader(expandTrailing: 12, expandTop: 8)
        .opacity(task.done ? 0.45 : 1)

      subtasksExpansion

      if !(task.hasSubtasks && expanded) {
        TaskExpandDivider(indent: TaskExpandDividerStyle.listParentInset)
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(taskAccessibilityLabel)
    .accessibilityHint(taskAccessibilityHint)
    .onAppear {
      guard !deferHeavyWork else { return }
      syncSubtasks()
    }
    .onChange(of: task.subtasks) { _, _ in
      guard !deferHeavyWork else { return }
      syncSubtasks()
    }
    .onChange(of: deferHeavyWork) { _, deferred in
      guard !deferred else { return }
      syncSubtasks()
    }
    .task(id: task.id) {
      guard !deferHeavyWork, task.hasSubtasks, allLabels.isEmpty else { return }
      labelCatalog = await LabelCatalogCache.labels()
    }
  }

  private func rowHeader(expandTrailing: CGFloat, expandTop: CGFloat) -> some View {
    let expandReserve: CGFloat = task.hasSubtasks ? 40 : 0
    let centerTitle = centersTitleInRow

    return ZStack(alignment: centerTitle ? .leading : .topLeading) {
      taskContentTapArea(expandReserve: expandReserve)

      HStack(alignment: centerTitle ? .center : .top, spacing: 0) {
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
    let centerTitle = centersTitleInRow
    let content = HStack(alignment: centerTitle ? .center : .top, spacing: 0) {
      Color.clear.frame(width: 46)
      rowTextContent
        .padding(.vertical, centerTitle ? 4 : 10)
        .padding(.trailing, task.hasSubtasks ? 4 : 14)
        .frame(maxWidth: .infinity, alignment: .leading)
      if task.hasSubtasks {
        Color.clear.frame(width: expandReserve)
      }
    }
    .frame(maxWidth: .infinity, minHeight: AppLayout.taskRowHeight)
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
      if let desc = task.description, !desc.isEmpty {
        Text(desc)
          .font(AppTypography.taskPreview)
          .foregroundStyle(c.textTertiary)
          .lineLimit(2)
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

  private var centersTitleInRow: Bool {
    guard !task.hasSubtasks else { return false }
    if let desc = task.description, !desc.isEmpty { return false }
    if task.timeDisplay != nil { return false }
    if !task.labels.isEmpty { return false }
    if task.dueDate != nil { return false }
    if task.commentCount > 0 { return false }
    if showProject, !task.project.isEmpty, task.project != "Sem projeto" { return false }
    return true
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
    let subtaskLeading: CGFloat = style == .card ? 36 : 36
    let betweenAlpha: CGFloat = (style == .card && !flatSubtaskPanel) ? 0.08 : TaskExpandDividerStyle.alpha

    return VStack(spacing: 0) {
      if flatSubtaskPanel || style == .list {
        TaskExpandDivider(
          indent: style == .card
            ? TaskExpandDividerStyle.cardSubtaskInset
            : TaskExpandDividerStyle.listParentInset
        )
      } else {
        Divider().overlay(c.surfaceVariant)
      }

      ForEach(Array(task.subtasks.enumerated()), id: \.element.idOrFallback) { index, sub in
        let done = index < subtasksDone.count ? subtasksDone[index] : sub.done
        let labels = resolvedLabels(for: sub)
        let hasMeta = (sub.description?.isEmpty == false) || sub.dueDate != nil || !labels.isEmpty
        HStack(alignment: hasMeta ? .top : .center, spacing: 0) {
          Button { toggleSubtask(at: index, sub: sub) } label: {
            subtaskDot(sub: sub, done: done)
              .padding(.horizontal, 4)
              .padding(.vertical, hasMeta ? 13 : 0)
          }
          .buttonStyle(PressableStyle(onPrepare: HapticService.prepareTaskComplete))

          Button {
            onSubtaskTap?(sub)
          } label: {
            VStack(alignment: .leading, spacing: 0) {
              Text(sub.title)
                .font(AppTypography.subtaskRowTitle)
                .foregroundStyle(done ? c.textTertiary : c.textPrimary)
                .strikethrough(done)
              if let desc = sub.description, !desc.isEmpty {
                Text(desc)
                  .font(AppTypography.subtaskPreview)
                  .foregroundStyle(c.textSecondary.opacity(done ? 0.55 : 0.85))
                  .lineLimit(2)
                  .padding(.top, 2)
              }
              if hasMeta {
                TaskMetaLine(
                  labels: labels,
                  dueDate: sub.dueDate,
                  dueDateLabel: sub.dueDateChipLabel,
                  dueDateColor: sub.dueDateChipColor
                )
              }
            }
            .padding(.vertical, hasMeta ? 9 : 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
          }
          .buttonStyle(PressableStyle())
          .disabled(onSubtaskTap == nil)
        }
        .padding(.leading, subtaskLeading)
        .padding(.trailing, 12)

        if index < task.subtasks.count - 1 {
          TaskExpandDivider(
            indent: style == .card
              ? TaskExpandDividerStyle.cardSubtaskInset
              : TaskExpandDividerStyle.listSubtaskInset(rowLeading: subtaskLeading),
            colorAlpha: betweenAlpha
          )
        }
      }
      Color.clear.frame(height: 4)
    }
    .background(c.surfaceVariant.opacity(flatSubtaskPanel ? 0 : (style == .card ? 0.45 : 0)))
  }

  private func subtaskDot(sub: Subtask, done: Bool) -> some View {
    DoneCircle(
      done: done,
      size: DoneCircle.listRowCircleSize,
      borderWidth: DoneCircle.RingStyle.borderWidth,
      tickSize: 13,
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
    guard index < subtasksDone.count else { return }
    guard sub.id != nil || sub.taskId != nil else { return }
    let newDone = !subtasksDone[index]
    if newDone {
      HapticService.taskCompleted()
    } else {
      HapticService.light()
    }
    subtasksDone[index] = newDone
    _Concurrency.Task {
      try? await SubtaskRepository.shared.toggleDone(
        id: sub.id,
        taskId: sub.taskId,
        order: sub.order,
        done: newDone
      )
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
      size: DoneCircle.listRowCircleSize,
      borderWidth: DoneCircle.RingStyle.borderWidth,
      tickSize: 13,
      ringColor: priority?.color ?? theme.colors.textTertiary,
      ringFillAlpha: done ? 0 : DoneCircle.RingStyle.inactiveFillAlpha
    )
    .accessibilityHidden(true)
  }
}
