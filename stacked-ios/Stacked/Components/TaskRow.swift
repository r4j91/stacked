import SwiftUI
import UIKit
import Hugeicons

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
  /// UIKit cells: não restaurar expansão salva no appear (evita altura fantasma + hitch).
  var restoreExpansionOnAppear: Bool = true
  /// UIKit `UIHostingConfiguration`: evita animar o layout do header (título/chevron “chutam”).
  /// Altura anima só no `SubtaskExpandReveal`; chevron usa o `.animation` próprio.
  var stabilizeExpandInSelfSizingCell: Bool = false
  var rowInteractionsEnabled: Bool = true
  var onToggle: () -> Void
  var onTap: (() -> Void)?
  var onSubtaskTap: ((Subtask) -> Void)?
  var onSubtaskChanged: ((SubtaskSaveSnapshot) -> Void)?
  /// Long-press / context menu — excluir subtarefa inline (paridade TaskDetail).
  var onSubtaskDeleted: ((Subtask) -> Void)?
  var onWhatsAppCopy: (() -> Void)?
  /// UIKit list: collapse/expand → limpa cache de altura e reconfigure da cell.
  var onSubtaskExpansionChanged: ((Bool) -> Void)?

  @State private var expanded = false
  @State private var subtaskRevealActive = false
  @State private var subtaskRevealLayoutPass = 0
  /// Remount UIKit (scroll recycle): abre já na altura final — sem 0→full no meio do fling.
  @State private var snapRevealOpen = false
  @State private var displaySubtasks: [Subtask] = []
  @State private var subtasksDone: [Bool] = []
  @State private var subtaskSortHoldId: String?
  @State private var subtaskReorderTask: _Concurrency.Task<Void, Never>?
  @State private var labelCatalog: [TaskLabel] = []

  init(
    task: Task,
    style: TaskRowStyle = .card,
    flatSubtaskPanel: Bool = false,
    showProject: Bool = true,
    allLabels: [TaskLabel] = [],
    deferHeavyWork: Bool = false,
    restoreExpansionOnAppear: Bool = true,
    stabilizeExpandInSelfSizingCell: Bool = false,
    rowInteractionsEnabled: Bool = true,
    onToggle: @escaping () -> Void,
    onTap: (() -> Void)? = nil,
    onSubtaskTap: ((Subtask) -> Void)? = nil,
    onSubtaskChanged: ((SubtaskSaveSnapshot) -> Void)? = nil,
    onSubtaskDeleted: ((Subtask) -> Void)? = nil,
    onWhatsAppCopy: (() -> Void)? = nil,
    onSubtaskExpansionChanged: ((Bool) -> Void)? = nil
  ) {
    self.task = task
    self.style = style
    self.flatSubtaskPanel = flatSubtaskPanel
    self.showProject = showProject
    self.allLabels = allLabels
    self.deferHeavyWork = deferHeavyWork
    self.restoreExpansionOnAppear = restoreExpansionOnAppear
    self.stabilizeExpandInSelfSizingCell = stabilizeExpandInSelfSizingCell
    self.rowInteractionsEnabled = rowInteractionsEnabled
    self.onToggle = onToggle
    self.onTap = onTap
    self.onSubtaskTap = onSubtaskTap
    self.onSubtaskChanged = onSubtaskChanged
    self.onSubtaskDeleted = onSubtaskDeleted
    self.onWhatsAppCopy = onWhatsAppCopy
    self.onSubtaskExpansionChanged = onSubtaskExpansionChanged

    // UIKit recycle: 1º frame já expandido — onAppear false→true saltava a lista no fling.
    let seedOpen =
      restoreExpansionOnAppear
      && !deferHeavyWork
      && stabilizeExpandInSelfSizingCell
      && task.hasSubtasks
      && ProjectDetailPreferences.isSubtaskListExpanded(taskId: task.id)
    _subtaskRevealLayoutPass = State(initialValue: 0)
    _subtaskSortHoldId = State(initialValue: nil)
    _subtaskReorderTask = State(initialValue: nil)
    _labelCatalog = State(initialValue: [])

    if seedOpen {
      let sorted = TaskMapper.sortSubtasksForDisplay(task.subtasks)
      _expanded = State(initialValue: true)
      _subtaskRevealActive = State(initialValue: true)
      _snapRevealOpen = State(initialValue: true)
      _displaySubtasks = State(initialValue: sorted)
      _subtasksDone = State(initialValue: sorted.map(\.done))
    } else {
      _expanded = State(initialValue: false)
      _subtaskRevealActive = State(initialValue: false)
      _snapRevealOpen = State(initialValue: false)
      _displaySubtasks = State(initialValue: [])
      _subtasksDone = State(initialValue: [])
    }
  }

  var body: some View {
    switch style {
    case .card: cardBody(light: false)
    case .cardLight: cardBody(light: true)
    case .list: listBody(premium: false)
    case .listPremium: listBody(premium: true)
    }
  }

  private func cardBody(light: Bool) -> some View {
    let c = theme.colors
    let headerHeight = exactHeaderHeight
    let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
    // Clip estável sempre — ligar/desligar clip no expand destruía a árvore e
    // o chevron de subtarefas no Balões light precisava de vários toques.

    return VStack(spacing: 0) {
      rowHeader(expandTrailing: 8, expandTop: 8)
        // PERF_FASEB2_ETAPA3: .frame(minHeight: AppLayout.taskRowHeight)
        .frame(height: headerHeight)

      subtasksExpansion
    }
    // PERF_FASEB2_ETAPA3: .frame(minHeight: AppLayout.taskRowHeight)
    .frame(minHeight: headerHeight)
    .background {
      if light {
        // UIKIT_SCROLL_POLISH: shape.fill(c.surface.opacity(0.72))
        shape
          .fill(cardSurfaceFill(light: true))
          .overlay {
            shape.strokeBorder(c.textPrimary.opacity(0.055), lineWidth: 1)
          }
      } else {
        shape.fill(cardSurfaceFill(light: false))
      }
    }
    .clipShape(shape)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(taskAccessibilityLabel)
    .accessibilityHint(taskAccessibilityHint)
    .modifier(rowScrollLifecycle)
  }

  private func listBody(premium: Bool) -> some View {
    let headerHeight = exactHeaderHeight
    let expandTrailing: CGFloat = premium ? 10 : 12
    let expandTop: CGFloat = premium ? 6 : 8

    return VStack(spacing: 0) {
      rowHeader(expandTrailing: expandTrailing, expandTop: expandTop)
        .opacity(task.done ? 0.45 : 1)
        // PERF_FASEB2_ETAPA3: altura exata do header
        .frame(height: headerHeight)

      if !premium {
        TaskExpandDivider(indent: TaskExpandDividerStyle.listParentInset)
      }

      subtasksExpansion
    }
    .overlay(alignment: .bottom) {
      if premium {
        Rectangle()
          .fill(theme.colors.textPrimary.opacity(0.035))
          .frame(height: 1)
          .padding(.leading, 38)
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(taskAccessibilityLabel)
    .accessibilityHint(taskAccessibilityHint)
    .modifier(rowScrollLifecycle)
  }

  private var rowScrollLifecycle: TaskRowScrollLifecycle {
    TaskRowScrollLifecycle(
      taskId: task.id,
      subtaskCount: task.subtasks.count,
      subtasksRevision: taskSubtasksRevision,
      deferHeavyWork: deferHeavyWork,
      expanded: expanded,
      shouldLoadLabels: task.hasSubtasks && allLabels.isEmpty && labelCatalog.isEmpty,
      onAppearRow: handleRowAppear,
      onSubtasksChanged: handleSubtasksChanged,
      onTaskIdentityChanged: handleTaskIdentityChanged,
      onHeavyWorkAllowed: handleHeavyWorkAllowed,
      onLoadLabels: {
        labelCatalog = await LabelCatalogCache.labels()
        bumpSubtaskRevealLayout()
      }
    )
  }

  /// Detecta conclusão/edição sem mudar o count (Inbox UIKit reconfigure).
  private var taskSubtasksRevision: Int {
    var hasher = Hasher()
    for sub in task.subtasks {
      hasher.combine(sub.idOrFallback)
      hasher.combine(sub.done)
      hasher.combine(sub.title)
      hasher.combine(sub.order)
    }
    hasher.combine(task.subtasksDoneCount)
    return hasher.finalize()
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
          PriorityDot(
            priority: task.priority,
            done: task.done,
            scrollStable: stabilizeExpandInSelfSizingCell,
            rowIdentity: task.id
          )
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
    // CTXMENU_EXPAND_FIX: lift/âncora só no header — com subtarefas abertas o menu
    // escalava a row inteira e capturava âncora errada.
    .taskContextMenuLiftHost()
  }

  private var showsWhatsAppCopyButton: Bool {
    task.whatsappRoutine && task.hasDescription && onWhatsAppCopy != nil
  }

  @ViewBuilder
  private func rowClockIcon(color: Color) -> some View {
    if stabilizeExpandInSelfSizingCell {
      UIKitRowIconView(key: .clock, size: 11, color: color)
    } else {
      // UIKIT_SCROLL_POLISH: StackedIcons.icon(.clock, …) legado
      StackedIcons.icon(.clock, size: 11, color: color)
    }
  }

  private func whatsAppCopyButton(action: @escaping () -> Void) -> some View {
    let c = theme.colors
    return Button(action: action) {
      Group {
        if stabilizeExpandInSelfSizingCell {
          UIKitRowIconView(key: .copy, size: 16, color: c.accent)
        } else {
          // UIKIT_SCROLL_POLISH: path legado SwiftUI
          StackedIcons.image(.copy)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(c.accent)
        }
      }
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
      // CTXMENU_ANCHOR_FIX: NÃO usar LongPress.sequenced(before: Drag) — o onEnded
      // só rodava ao soltar o dedo. Abrir no reconhecimento do long-press (dedo ainda baixo).
      content.gesture(
        LongPressGesture(minimumDuration: TaskContextLift.minimumDuration)
          .onEnded { _ in openTaskContextMenu(nil) }
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
        layoutPass: subtaskRevealLayoutPass,
        contentRevision: subtaskRevealContentRevision,
        stabilizeSelfSizingParent: stabilizeExpandInSelfSizingCell,
        snapOpen: snapRevealOpen,
        panelFill: style.isCardFamily && !flatSubtaskPanel ? subtaskPanelFill : nil
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
        NotesMarkupText(
          source: desc,
          color: c.textTertiary,
          size: 14,
          weight: .regular,
          boldWeight: .semibold,
          lineLimit: 1
        )
        .padding(.top, 4)
      }
      // PERF_FASEC1: não monta TaskMetaLine vazio (mesmo visual — linha só quando há meta).
      if rowShowsMeta {
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
          rowClockIcon(color: c.textTertiary)
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
      SubtaskExpandChevron(
        expanded: expanded,
        stabilizeInSelfSizingCell: stabilizeExpandInSelfSizingCell,
        taskId: task.id
      )
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(expanded ? "Recolher subtarefas" : "Expandir subtarefas")
    .accessibilityValue("\(displayedSubtasksDone) de \(displayedSubtasksTotal) concluídas")
  }

  private var subtaskList: some View {
    let c = theme.colors
    let subtaskLeading: CGFloat = 36
    let betweenAlpha: CGFloat = (style.isCardFamily && !flatSubtaskPanel) ? 0.08 : TaskExpandDividerStyle.alpha

    return VStack(spacing: 0) {
      if flatSubtaskPanel {
        TaskExpandDivider(indent: TaskExpandDividerStyle.cardSubtaskInset)
      } else if style.isCardFamily {
        Divider().overlay(c.surfaceVariant)
      }

      ForEach(Array(displaySubtasks.enumerated()), id: \.element.idOrFallback) { index, sub in
        let done = index < subtasksDone.count ? subtasksDone[index] : sub.done
        let labels = resolvedLabels(for: sub)
        // labelIds (não resolved): reserva meta antes do catalog — evita flip center→top no scroll.
        let hasMeta = (sub.description?.isEmpty == false) || sub.dueDate != nil || !sub.labelIds.isEmpty
        HStack(alignment: hasMeta ? .top : .center, spacing: 0) {
          Button { toggleSubtask(at: index, sub: sub) } label: {
            subtaskDot(sub: sub, done: done)
              .frame(width: 44, height: hasMeta ? 48 : 44)
              .contentShape(Rectangle())
          }
          // Host aninhado no UIKit: PressableStyle + scale atrapalhava o hit-test.
          .buttonStyle(.borderless)
          .disabled(!rowInteractionsEnabled)

          // SUBTASK_CTXMENU_FIX: PressableStyle + Button + .contextMenu só “selecionava”
          // e não abria o menu (pior em listas de projeto). Long-press = popover Excluir.
          SubtaskTitlePressArea(
            onTap: { onSubtaskTap?(sub) },
            onDelete: { deleteInlineSubtask(sub) }
          ) {
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
                    rowClockIcon(color: c.textTertiary)
                    Text(timeDisplay)
                      .font(AppTypography.timeChip)
                      .foregroundStyle(c.textTertiary)
                  }
                  .fixedSize()
                }
              }
              if let desc = sub.description, !desc.isEmpty {
                NotesMarkupText(
                  source: desc,
                  color: c.textSecondary.opacity(done ? 0.55 : 0.85),
                  size: 14,
                  weight: .regular,
                  boldWeight: .semibold,
                  lineLimit: 2
                )
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
        }
        .padding(.leading, subtaskLeading)
        .padding(.trailing, 12)

        if index < displaySubtasks.count - 1 {
          TaskExpandDivider(
            indent: style.isCardFamily
              ? TaskExpandDividerStyle.cardSubtaskInset
              : TaskExpandDividerStyle.listSubtaskInset(rowLeading: subtaskLeading),
            colorAlpha: betweenAlpha
          )
        }
      }
      // Rodapé opaco — Clear deixava ver o card (tarja) sob o painel no UIKit.
      Rectangle()
        .fill(style.isCardFamily && !flatSubtaskPanel ? subtaskPanelFill : Color.clear)
        .frame(height: 8)
    }
    .background(subtaskPanelFill)
  }

  /// UIKIT_SCROLL_POLISH: fundo solido sob o card = theme.colors.background (CV).
  private func cardSurfaceFill(light: Bool) -> Color {
    let c = theme.colors
    if !stabilizeExpandInSelfSizingCell {
      return light ? c.surface.opacity(0.72) : c.surface
    }
    if light {
      return Self.opaqueBlend(src: c.surface, dst: c.background, alpha: 0.72)
    }
    return c.surface
  }

  private var subtaskPanelFill: Color {
    let c = theme.colors
    if flatSubtaskPanel { return .clear }
    guard style.isCardFamily else { return .clear }
    // UIKIT_SCROLL_POLISH: c.surfaceVariant.opacity(0.45)
    if !stabilizeExpandInSelfSizingCell {
      return c.surfaceVariant.opacity(0.45)
    }
    let cardBase = style == .cardLight
      ? Self.opaqueBlend(src: c.surface, dst: c.background, alpha: 0.72)
      : c.surface
    return Self.opaqueBlend(src: c.surfaceVariant, dst: cardBase, alpha: 0.45)
  }

  /// src over dst com alpha de src (sem blend transparente em runtime).
  private static func opaqueBlend(src: Color, dst: Color, alpha: CGFloat) -> Color {
    let s = UIColor(src)
    let d = UIColor(dst)
    var sr: CGFloat = 0, sg: CGFloat = 0, sb: CGFloat = 0, sa: CGFloat = 0
    var dr: CGFloat = 0, dg: CGFloat = 0, db: CGFloat = 0, da: CGFloat = 0
    s.getRed(&sr, green: &sg, blue: &sb, alpha: &sa)
    d.getRed(&dr, green: &dg, blue: &db, alpha: &da)
    let a = min(max(alpha, 0), 1)
    return Color(
      red: sr * a + dr * (1 - a),
      green: sg * a + dg * (1 - a),
      blue: sb * a + db * (1 - a)
    )
  }


  private func subtaskDot(sub: Subtask, done: Bool) -> some View {
    DoneCircle(
      done: done,
      size: DoneCircle.listRowCircleSize,
      borderWidth: DoneCircle.RingStyle.borderWidth,
      tickSize: 13,
      ringColor: sub.priority?.color ?? theme.colors.textTertiary,
      ringFillAlpha: done ? 0 : DoneCircle.RingStyle.inactiveFillAlpha,
      scrollStable: stabilizeExpandInSelfSizingCell,
      rowIdentity: sub.idOrFallback
    )
  }

  private func deleteInlineSubtask(_ sub: Subtask) {
    HapticService.warning()
    let key = subtaskHoldKey(sub)
    displaySubtasks.removeAll { subtaskHoldKey($0) == key }
    subtasksDone = displaySubtasks.map(\.done)

    guard let id = sub.id, !id.isEmpty else {
      onSubtaskDeleted?(sub)
      return
    }
    _Concurrency.Task {
      try? await SubtaskRepository.shared.deleteSubtask(id: id)
      await NotificationService.shared.cancelSubtaskNotification(id: id)
      TaskCalendarSync.remove(subtaskId: id)
      await MainActor.run {
        onSubtaskDeleted?(sub)
        // Fallback se a tela não passou callback — mantém stores principais coerentes.
        if onSubtaskDeleted == nil {
          TaskStore.shared.removeSubtask(parentId: task.id, subtask: sub)
          UpcomingStore.shared.removeSubtask(parentId: task.id, subtask: sub)
        }
      }
    }
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

  /// Só muda quando subtarefas / done / labels mudam — evita reassign do UIHostingController no scroll.
  private var subtaskRevealContentRevision: Int {
    var hasher = Hasher()
    hasher.combine(displaySubtasks.count)
    hasher.combine(labelCatalog.count)
    for label in labelCatalog {
      hasher.combine(label.id)
    }
    for (index, sub) in displaySubtasks.enumerated() {
      hasher.combine(sub.idOrFallback)
      hasher.combine(sub.title)
      hasher.combine(index < subtasksDone.count ? subtasksDone[index] : sub.done)
      hasher.combine(sub.dueDateChipLabel)
      hasher.combine(sub.timeDisplay)
      hasher.combine(sub.description)
      hasher.combine(sub.labelIds)
    }
    return hasher.finalize()
  }

  private func handleRowAppear() {
    // PERF_FASEC1: sort/sync só com painel aberto — idle usa counters do Task.
    if expanded || subtaskRevealActive {
      syncSubtasks()
    }
    if restoreExpansionOnAppear, !deferHeavyWork {
      restoreSubtaskExpansionIfNeeded()
    }
  }

  private func handleSubtasksChanged() {
    guard expanded || subtaskRevealActive else { return }
    let previousCount = displaySubtasks.count
    syncSubtasks()
    if expanded, task.subtasks.count != previousCount {
      bumpSubtaskRevealLayout()
    }
  }

  private func handleTaskIdentityChanged() {
    displaySubtasks = []
    subtasksDone = []
    expanded = false
    subtaskRevealActive = false
    snapRevealOpen = false
    if restoreExpansionOnAppear, !deferHeavyWork {
      restoreSubtaskExpansionIfNeeded()
    }
  }

  private func handleHeavyWorkAllowed() {
    if restoreExpansionOnAppear {
      restoreSubtaskExpansionIfNeeded()
    }
    guard expanded, subtaskRevealActive else { return }
    _Concurrency.Task { @MainActor in
      if allLabels.isEmpty, labelCatalog.isEmpty {
        labelCatalog = await LabelCatalogCache.labels()
      }
      bumpSubtaskRevealLayout()
    }
  }

  private func toggleSubtaskExpansion() {
    if !subtaskRevealActive {
      syncSubtasks()
      subtaskRevealActive = true
      if stabilizeExpandInSelfSizingCell {
        // Uma passagem: sem yield/AppMotion no `expanded` (isso deslocava o título na cell).
        expanded = true
        ProjectDetailPreferences.setSubtaskListExpanded(true, taskId: task.id)
        onSubtaskExpansionChanged?(true)
        return
      }
      expanded = false
      _Concurrency.Task { @MainActor in
        await _Concurrency.Task.yield()
        guard subtaskRevealActive else { return }
        AppMotion.animate(AppMotion.subtaskChevronTurnSpring, reduceMotion: reduceMotion) {
          expanded = true
        }
        ProjectDetailPreferences.setSubtaskListExpanded(true, taskId: task.id)
        onSubtaskExpansionChanged?(true)
      }
      return
    }
    let willExpand = !expanded
    if stabilizeExpandInSelfSizingCell {
      expanded = willExpand
    } else {
      AppMotion.animate(AppMotion.subtaskChevronTurnSpring, reduceMotion: reduceMotion) {
        expanded = willExpand
      }
    }
    ProjectDetailPreferences.setSubtaskListExpanded(willExpand, taskId: task.id)
    onSubtaskExpansionChanged?(willExpand)
    if !willExpand {
      scheduleSubtaskRevealTeardown()
    }
  }

  /// Desmonta o UIHostingController após o collapse — evita updateUIView pesado no scroll.
  private func scheduleSubtaskRevealTeardown() {
    let delayMs: Int
    if stabilizeExpandInSelfSizingCell {
      // Depois do slide (220ms) + reâncora (~3 frames) — teardown cedo faz a row pular.
      delayMs = reduceMotion ? 0 : 380
    } else {
      delayMs = reduceMotion ? 0 : 230
    }
    _Concurrency.Task { @MainActor in
      try? await _Concurrency.Task.sleep(for: .milliseconds(delayMs))
      guard !expanded else { return }
      subtaskRevealActive = false
      snapRevealOpen = false
    }
  }

  private func restoreSubtaskExpansionIfNeeded() {
    guard task.hasSubtasks else {
      expanded = false
      subtaskRevealActive = false
      snapRevealOpen = false
      return
    }
    let saved = ProjectDetailPreferences.isSubtaskListExpanded(taskId: task.id)
    guard saved else {
      expanded = false
      subtaskRevealActive = false
      snapRevealOpen = false
      return
    }
    // Já veio expandido do init (UIKit seed) — só garante lista e solta o snap.
    if stabilizeExpandInSelfSizingCell, expanded, subtaskRevealActive {
      if displaySubtasks.isEmpty { syncSubtasks() }
      if snapRevealOpen {
        _Concurrency.Task { @MainActor in
          try? await _Concurrency.Task.sleep(for: .milliseconds(40))
          guard expanded else { return }
          snapRevealOpen = false
        }
      }
      return
    }
    syncSubtasks()
    // UIKit recycle legado: uma passagem + snap — yield 0→full hitchava no scroll.
    if stabilizeExpandInSelfSizingCell {
      var transaction = Transaction()
      transaction.disablesAnimations = true
      withTransaction(transaction) {
        snapRevealOpen = true
        subtaskRevealActive = true
        expanded = true
      }
      bumpSubtaskRevealLayout()
      _Concurrency.Task { @MainActor in
        try? await _Concurrency.Task.sleep(for: .milliseconds(40))
        guard expanded else { return }
        snapRevealOpen = false
      }
      return
    }
    // List SwiftUI: yield evita altura 0 no 1º frame do reveal.
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

    // Patch otimista no store ANTES do delay de reorder — senão fechar/abrir lê task velho.
    let snapshot = subtaskSnapshot(sub, done: newDone)
    onSubtaskChanged?(snapshot)

    subtaskReorderTask?.cancel()
    subtaskReorderTask = _Concurrency.Task { @MainActor in
      // Persistência não depende do sleep de reorder (cancel matava o save).
      do {
        try await SubtaskRepository.shared.toggleDone(
          id: sub.id,
          taskId: sub.taskId,
          order: sub.order,
          done: newDone
        )
      } catch {
        // Reverte store + UI se o backend falhar.
        onSubtaskChanged?(subtaskSnapshot(sub, done: !newDone))
        guard !_Concurrency.Task.isCancelled else { return }
        if let idx = displaySubtasks.firstIndex(where: { subtaskHoldKey($0) == holdKey }) {
          displaySubtasks[idx] = subtaskWithDone(displaySubtasks[idx], done: !newDone)
          if idx < subtasksDone.count { subtasksDone[idx] = !newDone }
        }
        return
      }

      guard !_Concurrency.Task.isCancelled else { return }

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

/// Long-press abre popover “Excluir”; tap abre detalhe — sem PressableStyle/contextMenu do sistema.
struct SubtaskTitlePressArea<Content: View>: View {
  let onTap: () -> Void
  let onDelete: () -> Void
  @ViewBuilder var content: () -> Content

  /// PERF: reader só no long-press — GeometryReader+PreferenceKey por frame matava o scroll com subtarefas abertas.
  @State private var needsAnchorReader = false
  @State private var anchorFrame: CGRect = .zero
  @State private var anchorCaptureGeneration = 0

  var body: some View {
    content()
      .background {
        if needsAnchorReader {
          OnDemandScreenBoundsReader(captureGeneration: anchorCaptureGeneration, rect: $anchorFrame)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
        }
      }
      .contentShape(Rectangle())
      .gesture(
        LongPressGesture(minimumDuration: TaskContextLift.minimumDuration)
          .onEnded { _ in openDeleteMenu() }
          .exclusively(before: TapGesture().onEnded { onTap() })
      )
  }

  private func openDeleteMenu() {
    HapticService.prepareContextMenu()
    HapticService.medium()

    needsAnchorReader = true
    anchorFrame = .zero
    let generation = anchorCaptureGeneration + 1
    anchorCaptureGeneration = generation

    _Concurrency.Task { @MainActor in
      var resolved = CGRect.zero
      for attempt in 0..<16 {
        if attempt > 0 {
          try? await _Concurrency.Task.sleep(for: .milliseconds(8))
        } else {
          await _Concurrency.Task.yield()
          await _Concurrency.Task.yield()
        }
        guard generation == anchorCaptureGeneration else { return }
        if anchorFrame.isValidAnchor {
          resolved = anchorFrame
          break
        }
      }
      guard generation == anchorCaptureGeneration else { return }

      let screenH = ScreenMetrics.bounds.height
      let preferAbove = (resolved.isValidAnchor ? resolved.midY : screenH * 0.5) > screenH * 0.55
      presentAnchoredPopover(
        anchorRect: resolved,
        items: [
          PopoverMenuItem(
            id: "delete",
            icon: Hugeicons.delete01,
            label: "Excluir subtarefa",
            destructive: true
          ),
        ],
        preferAbove: preferAbove
      ) { result in
        if result == "delete" { onDelete() }
      }
    }
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

/// PERF_FASEC1 — lifecycle da row fora do body card/list (sem sync idle no scroll).
private struct TaskRowScrollLifecycle: ViewModifier {
  let taskId: String
  let subtaskCount: Int
  /// Hash de done/título — count sozinho não detecta conclusão.
  let subtasksRevision: Int
  let deferHeavyWork: Bool
  let expanded: Bool
  let shouldLoadLabels: Bool
  let onAppearRow: () -> Void
  let onSubtasksChanged: () -> Void
  let onTaskIdentityChanged: () -> Void
  let onHeavyWorkAllowed: () -> Void
  let onLoadLabels: () async -> Void

  func body(content: Content) -> some View {
    content
      .onAppear(perform: onAppearRow)
      .onChange(of: subtaskCount) { _, _ in onSubtasksChanged() }
      .onChange(of: subtasksRevision) { _, _ in onSubtasksChanged() }
      .onChange(of: taskId) { _, _ in onTaskIdentityChanged() }
      .onChange(of: deferHeavyWork) { _, deferred in
        if !deferred { onHeavyWorkAllowed() }
      }
      .task(id: expanded) {
        guard expanded, !deferHeavyWork, shouldLoadLabels else { return }
        await onLoadLabels()
      }
  }
}

/// Chevron de expandir subtarefas — paridade web (`rotate-90`: → fechado, ↓ aberto).
struct SubtaskExpandChevron: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let expanded: Bool
  var size: CGFloat = 12
  /// Em cell self-sizing, spring no chevron + resize da cell = “pulo”. Ease curto fica estável.
  var stabilizeInSelfSizingCell: Bool = false
  /// UIKIT_SCROLL_POLISH: id estável — reuse/restore não dispara `.animation`.
  var taskId: String = ""

  @State private var boundTaskId: String = ""
  @State private var animationsArmed = false

  var body: some View {
    // UIKIT_SCROLL_POLISH: raster nearest encolhia o chevron vs .font(semibold).
    // Volta ao vetor com o mesmo tamanho óptico de antes.
    StackedIcons.image(.chevronDown)
      .font(.system(size: size, weight: .semibold))
      .foregroundStyle(theme.colors.textTertiary)
      .rotationEffect(.degrees(expanded ? 0 : -90))
      // UIKIT_SCROLL_POLISH: .animation(chevronAnimation, value: expanded) sempre ligado
      .animation(animationsArmed ? chevronAnimation : nil, value: expanded)
      .onAppear { armAnimationsAfterBind() }
      .onChange(of: taskId) { _, _ in armAnimationsAfterBind(reset: true) }
  }

  private var chevronAnimation: Animation? {
    if reduceMotion { return nil }
    if stabilizeInSelfSizingCell {
      return .easeOut(duration: 0.18)
    }
    return AppMotion.subtaskChevronTurn(reduceMotion: false)
  }

  private func armAnimationsAfterBind(reset: Bool = false) {
    if taskId.isEmpty {
      animationsArmed = true
      return
    }
    if reset || boundTaskId != taskId {
      boundTaskId = taskId
      animationsArmed = false
      _Concurrency.Task { @MainActor in
        await _Concurrency.Task.yield()
        guard boundTaskId == taskId else { return }
        animationsArmed = true
      }
      return
    }
    if !animationsArmed {
      animationsArmed = true
    }
  }
}

struct PriorityDot: View {
  @Environment(ThemeManager.self) private var theme
  let priority: Priority?
  let done: Bool
  /// UIKit cell + scroll: bitmap idle — anéis vetoriais “nadam” no AA.
  var scrollStable: Bool = false
  var rowIdentity: String = ""

  var body: some View {
    DoneCircle(
      done: done,
      size: DoneCircle.listRowCircleSize,
      borderWidth: DoneCircle.RingStyle.borderWidth,
      tickSize: 13,
      ringColor: priority?.color ?? theme.colors.textTertiary,
      ringFillAlpha: done ? 0 : DoneCircle.RingStyle.inactiveFillAlpha,
      scrollStable: scrollStable,
      rowIdentity: rowIdentity
    )
    .accessibilityHidden(true)
  }
}
