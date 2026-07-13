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
  var rowInteractionsEnabled: Bool = true
  var onToggle: () -> Void
  var onTap: (() -> Void)?
  var onSubtaskTap: ((Subtask) -> Void)?
  var onSubtaskChanged: ((SubtaskSaveSnapshot) -> Void)?
  var onWhatsAppCopy: (() -> Void)?

  @State private var expanded = false
  @State private var subtaskRevealActive = false
  @State private var subtaskRevealLayoutPass = 0
  @State private var displaySubtasks: [Subtask] = []
  @State private var subtasksDone: [Bool] = []
  @State private var subtaskSortHoldId: String?
  @State private var subtaskReorderTask: _Concurrency.Task<Void, Never>?
  @State private var labelCatalog: [TaskLabel] = []

  var body: some View {
    switch style {
    case .card: cardBody
    case .list: listBody
    }
  }

  private var cardBody: some View {
    let c = theme.colors
    let headerHeight = exactHeaderHeight

    return VStack(spacing: 0) {
      rowHeader(expandTrailing: 8, expandTop: 8)
        // PERF_FASEB2_ETAPA3: .frame(minHeight: AppLayout.taskRowHeight)
        .frame(height: headerHeight)

      subtasksExpansion
    }
    // PERF_FASEB2_ETAPA3: .frame(minHeight: AppLayout.taskRowHeight)
    .frame(minHeight: headerHeight)
    .background(c.surface)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .accessibilityElement(children: .combine)
    .accessibilityLabel(taskAccessibilityLabel)
    .accessibilityHint(taskAccessibilityHint)
    .onAppear {
      syncSubtasks()
      restoreSubtaskExpansionIfNeeded()
    }
    .onChange(of: task.subtasks) { _, newSubs in
      let previousCount = displaySubtasks.count
      syncSubtasks()
      if expanded, newSubs.count != previousCount {
        bumpSubtaskRevealLayout()
      }
    }
    .onChange(of: task.id) { _, _ in
      syncSubtasks()
      restoreSubtaskExpansionIfNeeded()
    }
    .task(id: expanded) {
      guard expanded, !deferHeavyWork, task.hasSubtasks, allLabels.isEmpty, labelCatalog.isEmpty else { return }
      labelCatalog = await LabelCatalogCache.labels()
      bumpSubtaskRevealLayout()
    }
    .onChange(of: deferHeavyWork) { _, deferred in
      guard !deferred, expanded, subtaskRevealActive else { return }
      _Concurrency.Task { @MainActor in
        if allLabels.isEmpty, labelCatalog.isEmpty {
          labelCatalog = await LabelCatalogCache.labels()
        }
        bumpSubtaskRevealLayout()
      }
    }
  }

  private var listBody: some View {
    let c = theme.colors
    let headerHeight = exactHeaderHeight

    return VStack(spacing: 0) {
      rowHeader(expandTrailing: 12, expandTop: 8)
        .opacity(task.done ? 0.45 : 1)
        // PERF_FASEB2_ETAPA3: altura exata do header
        .frame(height: headerHeight)

      TaskExpandDivider(indent: TaskExpandDividerStyle.listParentInset)

      subtasksExpansion
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(taskAccessibilityLabel)
    .accessibilityHint(taskAccessibilityHint)
    .onAppear {
      syncSubtasks()
      restoreSubtaskExpansionIfNeeded()
    }
    .onChange(of: task.subtasks) { _, newSubs in
      let previousCount = displaySubtasks.count
      syncSubtasks()
      if expanded, newSubs.count != previousCount {
        bumpSubtaskRevealLayout()
      }
    }
    .onChange(of: task.id) { _, _ in
      syncSubtasks()
      restoreSubtaskExpansionIfNeeded()
    }
    .task(id: expanded) {
      guard expanded, !deferHeavyWork, task.hasSubtasks, allLabels.isEmpty, labelCatalog.isEmpty else { return }
      labelCatalog = await LabelCatalogCache.labels()
      bumpSubtaskRevealLayout()
    }
    .onChange(of: deferHeavyWork) { _, deferred in
      guard !deferred, expanded, subtaskRevealActive else { return }
      _Concurrency.Task { @MainActor in
        if allLabels.isEmpty, labelCatalog.isEmpty {
          labelCatalog = await LabelCatalogCache.labels()
        }
        bumpSubtaskRevealLayout()
      }
    }
  }

  /// PERF_FASEB2_ETAPA3: altura determinística — (tem desc?, tem meta?).
  private var exactHeaderHeight: CGFloat {
    AppLayout.taskRowHeaderHeight(
      hasDescription: task.hasDescription,
      hasMeta: rowShowsMeta
    )
  }

  private var rowShowsMeta: Bool {
    let showsProject = showProject && !task.project.isEmpty && task.project != "Sem projeto"
    return showsProject
      || !task.labels.isEmpty
      || task.priority != nil
      || task.dueDate != nil
      || task.subtasksTotalCount > 0
      || task.commentCount > 0
  }

  private func bumpSubtaskRevealLayout() {
    subtaskRevealLayoutPass &+= 1
  }

  private func rowHeader(expandTrailing: CGFloat, expandTop: CGFloat) -> some View {
    let showsWhatsApp = showsWhatsAppCopyButton
    // Empilhados na rail: só uma coluna (~40pt), não 80pt lado a lado.
    let expandReserve: CGFloat = (task.hasSubtasks || showsWhatsApp) ? 40 : 0
    let centerTitle = centersTitleInRow
    let trailingBottom: CGFloat = 6

    return ZStack(alignment: centerTitle ? .leading : .topLeading) {
      taskContentTapArea(expandReserve: expandReserve)

      HStack(alignment: centerTitle ? .center : .top, spacing: 0) {
        Button(action: onToggle) {
          PriorityDot(priority: task.priority, done: task.done)
            .padding(12)
        }
        .buttonStyle(PressableStyle(onPrepare: HapticService.prepareTaskComplete))
        .disabled(!rowInteractionsEnabled)
        .accessibilityLabel(task.done ? "Reabrir tarefa" : "Concluir tarefa")
        .accessibilityHint("Toque duas vezes para \(task.done ? "reabrir" : "concluir")")

        Spacer(minLength: 0)

        if task.hasSubtasks || showsWhatsApp {
          VStack(spacing: 0) {
            if task.hasSubtasks {
              expandButton
                .padding(.top, expandTop)
                .disabled(!rowInteractionsEnabled)
            }
            Spacer(minLength: 0)
            if showsWhatsApp, let onWhatsAppCopy {
              whatsAppCopyButton(action: onWhatsAppCopy)
                .padding(.bottom, trailingBottom)
            }
          }
          .padding(.trailing, expandTrailing)
        }
      }
    }
    // PERF_FASEB2_ETAPA3: .frame(minHeight: AppLayout.taskRowHeight) — altura vem do pai.
    .frame(maxHeight: .infinity)
  }

  private var showsWhatsAppCopyButton: Bool {
    task.whatsappRoutine && task.hasDescription && onWhatsAppCopy != nil
  }

  private func whatsAppCopyButton(action: @escaping () -> Void) -> some View {
    let c = theme.colors
    return Button(action: action) {
      StackedIcons.image(.copy)
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(c.accent)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Copiar mensagem para WhatsApp")
  }

  @ViewBuilder
  private func taskContentTapArea(expandReserve: CGFloat) -> some View {
    let centerTitle = centersTitleInRow
    let content = HStack(alignment: centerTitle ? .center : .top, spacing: 0) {
      Color.clear.frame(width: 46)
      rowTextContent
        .padding(.vertical, centerTitle ? 4 : 10)
        .padding(.trailing, (task.hasSubtasks || showsWhatsAppCopyButton) ? 4 : 14)
        .frame(maxWidth: .infinity, alignment: .leading)
      if task.hasSubtasks || showsWhatsAppCopyButton {
        Color.clear.frame(width: expandReserve)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .contentShape(Rectangle())

    if let onTap, let openTaskContextMenu, rowInteractionsEnabled {
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
    if task.hasSubtasks, subtaskRevealActive {
      SubtaskExpandReveal(
        expanded: expanded,
        reduceMotion: reduceMotion,
        layoutPass: subtaskRevealLayoutPass
      ) {
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
          // PERF_FASEB2_ETAPA3: .lineLimit(2)
          .lineLimit(1)
          .truncationMode(.tail)
          .padding(.top, 4)
      }
      TaskMetaLine(
        labels: task.labels,
        dueDate: task.dueDate,
        dueDateLabel: task.dueDateChipLabel,
        dueDateColor: task.dueDateChipColor,
        dateDone: task.done,
        subtasksDone: displayedSubtasksDone,
        subtasksTotal: displayedSubtasksTotal,
        subtasksCounterLabel: displayedSubtasksCounterLabel,
        commentCount: task.commentCount,
        projectName: showProject ? task.project : nil
      )
    }
  }

  private var centersTitleInRow: Bool {
    guard !task.hasSubtasks else { return false }
    if task.hasDescription { return false }
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
        // PERF_FASEB2_ETAPA3: lineLimit(2) → 1 para altura determinística na List.
        .lineLimit(1)
        .truncationMode(.tail)
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
    Button {
      HapticService.selection()
      toggleSubtaskExpansion()
    } label: {
      SubtaskExpandChevron(expanded: expanded)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(expanded ? "Recolher subtarefas" : "Expandir subtarefas")
    .accessibilityValue("\(displayedSubtasksDone) de \(displayedSubtasksTotal) concluídas")
  }

  private var subtaskList: some View {
    let c = theme.colors
    let subtaskLeading: CGFloat = style == .card ? 36 : 36
    let betweenAlpha: CGFloat = (style == .card && !flatSubtaskPanel) ? 0.08 : TaskExpandDividerStyle.alpha

    return VStack(spacing: 0) {
      if flatSubtaskPanel {
        TaskExpandDivider(indent: TaskExpandDividerStyle.cardSubtaskInset)
      } else if style == .card {
        Divider().overlay(c.surfaceVariant)
      }

      ForEach(Array(displaySubtasks.enumerated()), id: \.element.idOrFallback) { index, sub in
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
              HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(sub.title)
                  .font(AppTypography.subtaskRowTitle)
                  .foregroundStyle(done ? c.textTertiary : c.textPrimary)
                  .strikethrough(done)
                  .lineLimit(2)
                  .layoutPriority(1)
                Spacer(minLength: 4)
                if let timeDisplay = sub.timeDisplay {
                  HStack(spacing: 2) {
                    StackedIcons.icon(.clock, size: 11, color: c.textTertiary)
                    Text(timeDisplay)
                      .font(AppTypography.timeChip)
                      .foregroundStyle(c.textTertiary)
                  }
                  .fixedSize()
                }
              }
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
                  dueDateColor: sub.dueDateChipColor,
                  dateDone: done
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

        if index < displaySubtasks.count - 1 {
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

  private var displayedSubtasksDone: Int {
    // PERF_FASEB2_ETAPA4: subtasksDone.isEmpty ? task.subtasks.filter(\.done).count : ...
    subtasksDone.isEmpty ? task.subtasksDoneCount : subtasksDone.filter { $0 }.count
  }

  private var displayedSubtasksTotal: Int {
    // PERF_FASEB2_ETAPA4: subtasksDone.isEmpty ? task.subtasks.count : ...
    subtasksDone.isEmpty ? task.subtasksTotalCount : subtasksDone.count
  }

  private var displayedSubtasksCounterLabel: String? {
    guard displayedSubtasksTotal > 0 else { return nil }
    if subtasksDone.isEmpty, let memo = task.subtasksCounterLabel {
      return memo
    }
    return "\(displayedSubtasksDone)/\(displayedSubtasksTotal)"
  }

  private func toggleSubtaskExpansion() {
    if !subtaskRevealActive {
      subtaskRevealActive = true
      expanded = false
      _Concurrency.Task { @MainActor in
        await _Concurrency.Task.yield()
        guard subtaskRevealActive else { return }
        AppMotion.animate(AppMotion.subtaskChevronTurnSpring, reduceMotion: reduceMotion) {
          expanded = true
        }
        ProjectDetailPreferences.setSubtaskListExpanded(true, taskId: task.id)
      }
      return
    }
    let willExpand = !expanded
    AppMotion.animate(AppMotion.subtaskChevronTurnSpring, reduceMotion: reduceMotion) {
      expanded = willExpand
    }
    ProjectDetailPreferences.setSubtaskListExpanded(willExpand, taskId: task.id)
    if !willExpand {
      scheduleSubtaskRevealTeardown()
    }
  }

  /// Desmonta o UIHostingController após o collapse — evita updateUIView pesado no scroll.
  private func scheduleSubtaskRevealTeardown() {
    let delayMs = reduceMotion ? 0 : 230
    _Concurrency.Task { @MainActor in
      try? await _Concurrency.Task.sleep(for: .milliseconds(delayMs))
      guard !expanded else { return }
      subtaskRevealActive = false
    }
  }

  private func restoreSubtaskExpansionIfNeeded() {
    guard task.hasSubtasks else {
      expanded = false
      subtaskRevealActive = false
      return
    }
    let saved = ProjectDetailPreferences.isSubtaskListExpanded(taskId: task.id)
    guard saved else {
      expanded = false
      subtaskRevealActive = false
      return
    }
    // Mesma sequência do toque manual — evita altura 0 ao restaurar na List.
    subtaskRevealActive = true
    expanded = false
    _Concurrency.Task { @MainActor in
      await _Concurrency.Task.yield()
      guard subtaskRevealActive,
            ProjectDetailPreferences.isSubtaskListExpanded(taskId: task.id) else { return }
      expanded = true
      bumpSubtaskRevealLayout()
      try? await _Concurrency.Task.sleep(for: .milliseconds(50))
      bumpSubtaskRevealLayout()
    }
  }

  private func syncSubtasks() {
    let sorted = TaskMapper.sortSubtasksForDisplay(task.subtasks)
    if subtaskSortHoldId != nil, !displaySubtasks.isEmpty {
      displaySubtasks = displaySubtasks.map { local in
        sorted.first(where: { subtaskHoldKey($0) == subtaskHoldKey(local) }) ?? local
      }
      subtasksDone = displaySubtasks.map(\.done)
      return
    }
    displaySubtasks = sorted
    subtasksDone = sorted.map(\.done)
  }

  private func subtaskHoldKey(_ sub: Subtask) -> String {
    if let id = sub.id, !id.isEmpty { return id }
    return "\(sub.taskId ?? task.id):\(sub.order)"
  }

  private func subtaskWithDone(_ sub: Subtask, done: Bool) -> Subtask {
    Subtask(
      id: sub.id,
      taskId: sub.taskId,
      title: sub.title,
      description: sub.description,
      done: done,
      priority: sub.priority,
      order: sub.order,
      valor: sub.valor,
      dueDate: sub.dueDate,
      time: sub.time,
      dueDateChipLabel: sub.dueDateChipLabel,
      dueDateChipColor: sub.dueDate.map { TaskMapper.dateColor(for: $0, done: done) } ?? sub.dueDateChipColor,
      timeDisplay: sub.timeDisplay,
      labelIds: sub.labelIds
    )
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

    let holdKey = subtaskHoldKey(sub)
    var updated = displaySubtasks
    updated[index] = subtaskWithDone(sub, done: newDone)
    displaySubtasks = updated
    subtasksDone[index] = newDone

    subtaskReorderTask?.cancel()
    subtaskReorderTask = _Concurrency.Task { @MainActor in
      if newDone {
        subtaskSortHoldId = holdKey
        if !reduceMotion {
          try? await _Concurrency.Task.sleep(for: AppMotion.subtaskCompleteReorderDelay)
        }
        guard !_Concurrency.Task.isCancelled else { return }
        subtaskSortHoldId = nil
        AppMotion.animate(AppMotion.smooth, reduceMotion: reduceMotion) {
          displaySubtasks = TaskMapper.sortSubtasksForDisplay(displaySubtasks)
          subtasksDone = displaySubtasks.map(\.done)
        }
      } else {
        subtaskSortHoldId = nil
        AppMotion.animate(AppMotion.smooth, reduceMotion: reduceMotion) {
          displaySubtasks = TaskMapper.sortSubtasksForDisplay(displaySubtasks)
          subtasksDone = displaySubtasks.map(\.done)
        }
      }

      try? await SubtaskRepository.shared.toggleDone(
        id: sub.id,
        taskId: sub.taskId,
        order: sub.order,
        done: newDone
      )
      if let id = sub.id {
        if newDone {
          TaskCalendarSync.remove(subtaskId: id)
        } else {
          TaskCalendarSync.sync(Subtask(
            id: sub.id,
            taskId: sub.taskId,
            title: sub.title,
            description: sub.description,
            done: false,
            priority: sub.priority,
            order: sub.order,
            valor: sub.valor,
            dueDate: sub.dueDate,
            time: sub.time,
            dueDateChipLabel: sub.dueDateChipLabel,
            dueDateChipColor: sub.dueDateChipColor,
            timeDisplay: sub.timeDisplay,
            labelIds: sub.labelIds
          ))
        }
      }
      onSubtaskChanged?(subtaskSnapshot(sub, done: newDone))
    }
  }

  private func subtaskSnapshot(_ sub: Subtask, done: Bool) -> SubtaskSaveSnapshot {
    SubtaskSaveSnapshot(
      parentTaskId: task.id,
      order: sub.order,
      resolvedId: sub.id,
      title: sub.title,
      description: sub.description,
      done: done,
      priority: sub.priority,
      dueDate: sub.dueDate,
      time: sub.time,
      labelIds: sub.labelIds
    )
  }

  private var taskAccessibilityLabel: String {
    var parts = [task.title]
    if task.done { parts.append("concluída") }
    if showProject, !task.project.isEmpty {
      parts.append("projeto \(task.project)")
    }
    if let due = task.dueDateChipLabel { parts.append("vencimento \(due)") }
    if task.hasSubtasks {
      parts.append("\(displayedSubtasksDone) de \(displayedSubtasksTotal) subtarefas concluídas")
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

/// Chevron lateral para linhas navegáveis — mesmo ícone das subtarefas (`arrowDown01` → direita).
struct DisclosureChevron: View {
  @Environment(ThemeManager.self) private var theme

  var size: CGFloat = 12
  var color: Color?

  var body: some View {
    StackedIcons.image(.chevronDown)
      .font(.system(size: size, weight: .semibold))
      .foregroundStyle(color ?? theme.colors.textTertiary)
      .rotationEffect(.degrees(-90))
  }
}

/// Chevron de expandir subtarefas — paridade web (`rotate-90`: → fechado, ↓ aberto).
struct SubtaskExpandChevron: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let expanded: Bool
  var size: CGFloat = 12

  var body: some View {
    StackedIcons.image(.chevronDown)
      .font(.system(size: size, weight: .semibold))
      .foregroundStyle(theme.colors.textTertiary)
      .rotationEffect(.degrees(expanded ? 0 : -90))
      .animation(AppMotion.subtaskChevronTurn(reduceMotion: reduceMotion), value: expanded)
  }
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
