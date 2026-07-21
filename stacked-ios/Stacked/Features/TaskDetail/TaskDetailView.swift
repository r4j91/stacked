import SwiftUI
import Hugeicons

// Paridade lib/screens/task_detail_sheet.dart (mobile)
struct TaskDetailView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(ThemeManager.self) private var theme

  @State private var vm: TaskDetailViewModel
  @State private var newSubtaskTitle = ""
  @FocusState private var newSubtaskFocused: Bool
  @FocusState private var descriptionFocused: Bool
  @State private var showDatePicker = false
  @State private var showDeleteConfirm = false
  @State private var subtaskDetailRoute: SubtaskDetailRoute?
  @State private var subtasksExpanded = false
  @State private var didInitSubtasksExpanded = false
  @State private var commentsExpanded = false
  @State private var didInitCommentsExpanded = false
  @State private var isClosing = false
  @State private var showNotesPanel = false
  @State private var notesAnchor: CGRect = .zero

  @AppStorage(ProductivityPreferences.anchoredDetailNotesKey) private var anchoredDetailNotes = false

  @State private var installmentRoute: InstallmentGeneratorRoute?
  @State private var showWhatsAppPreview = false

  var onDismiss: () -> Void = {}

  init(
    taskId: String,
    seed: Task? = nil,
    onDismiss: @escaping () -> Void = {}
  ) {
    _vm = State(initialValue: TaskDetailViewModel(taskId: taskId, seed: seed))
    self.onDismiss = onDismiss
  }

  var body: some View {
    let c = theme.colors

    NavigationStack {
      Group {
        if let error = vm.error, vm.title.isEmpty {
          LoadErrorView(message: error) {
            _Concurrency.Task { await vm.load() }
          }
        } else {
          scrollContent
            .overlay {
              if vm.isLoading && vm.title.isEmpty {
                ProgressView().tint(c.accent)
              }
            }
        }
      }
      .background(c.background.ignoresSafeArea())
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            close()
          } label: {
            Image(systemName: "xmark")
              .font(AppTypography.bodySemibold)
              .foregroundStyle(c.textSecondary)
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          HStack(spacing: 10) {
            if vm.showsWhatsAppAction {
              whatsAppToolbarButton
            }
            Menu {
              Button(role: .destructive) {
                showDeleteConfirm = true
              } label: {
                Label("Excluir tarefa", systemImage: "trash")
              }
            } label: {
              Image(systemName: "ellipsis")
                .foregroundStyle(c.textSecondary)
            }
          }
        }
      }
      .confirmationDialog("Excluir esta tarefa?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
        Button("Excluir", role: .destructive) {
          _Concurrency.Task {
            try? await vm.deleteTask()
            close()
          }
        }
        Button("Cancelar", role: .cancel) {}
      }
      .stackedTaskDatePickerSheet(
        isPresented: $showDatePicker,
        initialDate: vm.dueDate,
        initialTime: vm.dueTimeDate,
        showRecurrence: true
      ) { date, timeDate in
        vm.setDueDate(date, time: timeDate)
      }
      .installmentGeneratorSheet(route: $installmentRoute) {
        _Concurrency.Task { await vm.load() }
      }
      .sheet(item: $subtaskDetailRoute) { route in
        SubtaskDetailView(
          subtask: route.subtask,
          parentTaskId: route.parentTaskId,
          parentTaskTitle: vm.title
        ) { snapshot in
          if let snapshot { vm.applySubtaskPatch(snapshot) }
        }
        .environment(ThemeManager.shared)
        .presentationBackground(c.background)
        .presentationDragIndicator(.visible)
      }
      .sheet(isPresented: $showWhatsAppPreview) {
        WhatsAppCopyPreviewSheet(taskTitle: vm.title, message: vm.whatsAppMessage)
          .environment(ThemeManager.shared)
          .presentationBackground(c.background)
          .presentationDragIndicator(.visible)
      }
      .task {
        initExpandedSectionsIfNeeded()
        await vm.load()
        initExpandedSectionsIfNeeded()
      }
      .onChange(of: vm.isLoading) { wasLoading, isLoading in
        guard wasLoading, !isLoading else { return }
        initExpandedSectionsIfNeeded()
      }
      .onReceive(NotificationCenter.default.publisher(for: .labelsCatalogDidChange)) { _ in
        _Concurrency.Task { await vm.reloadLabels() }
      }
      .popoverHostScope()
      .overlay {
        if showNotesPanel {
          GeometryReader { geo in
            AnchoredNotesPopoverOverlay(
              anchorRect: notesAnchor,
              text: $vm.descriptionText,
              hostBounds: geo.frame(in: .global),
              onTextChange: { vm.onDescriptionChanged() },
              onDismiss: { showNotesPanel = false }
            )
          }
          .ignoresSafeArea()
        }
      }
    }
    .opacity(isClosing ? 0 : 1)
    .animation(isClosing ? .easeOut(duration: 0.22) : nil, value: isClosing)
    .allowsHitTesting(!isClosing)
    // NET_FASEC_ETAPA1B — swipe-down / qualquer dismiss: flush títulos/notas.
    .onDisappear {
      guard !isClosing else { return }
      _Concurrency.Task { await vm.flushPendingAutosaves() }
    }
  }

  private var scrollContent: some View {
    let c = theme.colors

    return ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        HStack(alignment: .top, spacing: 8) {
          Button(action: vm.toggleDone) {
            PriorityDot(priority: vm.priority, done: vm.done)
          }
          .buttonStyle(.plain)
          .padding(.top, 4)

          TextField("O que precisa ser feito?", text: $vm.title, axis: .vertical)
            .font(AppTypography.detailTitle)
            .foregroundStyle(c.textPrimary)
            .onChange(of: vm.title) { _, _ in vm.onTitleChanged() }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)

        descriptionNotesSection

        metadataCard
          .padding(.horizontal, 16)

        subtasksSection
          .padding(.horizontal, 16)
          .padding(.top, 16)

        commentsSection
          .padding(.horizontal, 16)
          .padding(.top, 16)
          .padding(.bottom, 40)
      }
    }
  }

  private var metadataCard: some View {
    let c = theme.colors

    return VStack(spacing: 0) {
      metaRow(icon: .folder, title: "Projeto", value: vm.projectName, active: vm.projectId != nil,
              valueColor: vm.allProjects.first(where: { $0.id == vm.projectId })?.color) { rect in
        showProjectMenu(anchor: rect)
      }

      if vm.dueDate != nil {
        divider
        metaRow(icon: .calendar, title: "Data", value: vm.dueDateLabel, active: true,
                valueColor: vm.dueDate.map { TaskMapper.dateColor(for: $0, done: vm.done) }) { _ in
          showDatePicker = true
        }
      }
      if vm.priority != nil {
        divider
        metaRow(icon: .flag, title: "Prioridade", value: vm.priority!.label, active: true,
                valueColor: vm.priority?.color) { rect in
          showPriorityMenu(anchor: rect)
        }
      }
      if !vm.selectedLabels.isEmpty {
        divider
        metaRow(icon: .tag, title: "Etiquetas", value: labelsSummary, active: true,
                valueColor: vm.selectedLabels.first?.color) { rect in
          showLabelsMenu(anchor: rect)
        }
      }
      if vm.recurrence != nil {
        divider
        metaRow(icon: .repeatIcon, title: "Recorrência", value: vm.recurrenceLabel, active: true) { rect in
          showRecurrenceMenu(anchor: rect)
        }
      }

      divider
      whatsappRoutineRow

      divider

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          if vm.dueDate == nil {
            fieldPill("Data", icon: .calendar) { _ in showDatePicker = true }
          }
          if vm.priority == nil {
            fieldPill("Prioridade", icon: .flag) { showPriorityMenu(anchor: $0) }
          }
          if vm.selectedLabels.isEmpty {
            fieldPill("Etiquetas", icon: .tag) { showLabelsMenu(anchor: $0) }
          }
          if vm.recurrence == nil {
            fieldPill("Recorrência", icon: .repeatIcon) { showRecurrenceMenu(anchor: $0) }
          }
          fieldPill("Parcelas", icon: .money) { _ in
            installmentRoute = InstallmentGeneratorRoute(taskId: vm.taskId, taskTitle: vm.title)
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
      }
    }
    .background(c.surface)
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .overlay(RoundedRectangle(cornerRadius: 14).stroke(c.textPrimary.opacity(0.06)))
  }

  private var subtasksSection: some View {
    let doneCount = vm.subtasks.filter(\.done).count
    let totalCount = vm.subtasks.count

    return VStack(alignment: .leading, spacing: 10) {
      detailSectionHeader(
        title: "Subtarefas",
        badge: totalCount > 0 ? "\(doneCount)/\(totalCount)" : nil,
        expanded: subtasksExpanded
      ) {
        HapticService.selection()
        withAnimation(AppMotion.subtaskExpand(reduceMotion: reduceMotion)) {
          subtasksExpanded.toggle()
        }
      }
      .accessibilityLabel(subtasksExpanded ? "Recolher subtarefas" : "Expandir subtarefas")

      if subtasksExpanded {
        detailSurfaceCard {
          ForEach(Array(vm.subtasks.enumerated()), id: \.element.idOrFallback) { index, sub in
            subtaskEditorRow(sub)
              .padding(.horizontal, 12)
            if index < vm.subtasks.count - 1 {
              subtaskDivider
            }
          }

          if !vm.subtasks.isEmpty {
            subtaskDivider
          }

          newSubtaskField
        }
      }
    }
  }

  private var subtaskDivider: some View {
    Rectangle()
      .fill(theme.colors.textTertiary.opacity(0.1))
      .frame(height: 1)
      .padding(.leading, 52)
      .padding(.trailing, 16)
  }

  private func subtaskEditorRow(_ sub: Subtask) -> some View {
    let c = theme.colors
    let labels = subtaskLabels(for: sub)
    let layout = TaskRowLayoutStorage.current
    let hasDescription = sub.description?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    let showsEyebrow = TaskRowLayoutStorage.showsEyebrow(
      layout: layout,
      projectName: nil,
      showProject: false,
      priority: sub.priority
    )
    let showsMetaLine: Bool = {
      if layout.usesEyebrow {
        if layout == .x2, sub.priority != nil { return true }
        if sub.dueDate != nil { return true }
        if sub.timeDisplay != nil { return true }
        if !labels.isEmpty { return true }
        return false
      }
      if layout.usesTrailingTimeColumn {
        return sub.dueDate != nil || !labels.isEmpty
      }
      if layout.isDense {
        return sub.dueDate != nil || sub.timeDisplay != nil || !labels.isEmpty
      }
      return sub.dueDate != nil || !labels.isEmpty
    }()
    let hasMeta = hasDescription || showsMetaLine || showsEyebrow
    let alignTop = hasMeta

    return HStack(alignment: alignTop ? .top : .center, spacing: 8) {
      Button {
        if !sub.done {
          HapticService.taskCompleted()
        } else {
          HapticService.light()
        }
        vm.toggleSubtask(sub)
      } label: {
        PriorityDot(priority: sub.priority, done: sub.done)
        .frame(width: 32, height: 32)
        .padding(.top, alignTop ? 2 : 0)
      }
      .buttonStyle(PressableStyle(onPrepare: HapticService.prepareTaskComplete))

      SubtaskTitlePressArea(
        onTap: {
          subtaskDetailRoute = SubtaskDetailRoute(subtask: sub, parentTaskId: vm.taskId)
        },
        onDelete: {
          HapticService.warning()
          _Concurrency.Task { await vm.deleteSubtask(sub) }
        }
      ) {
        VStack(alignment: .leading, spacing: 2) {
          if showsEyebrow {
            TaskRowEyebrow(
              projectName: nil,
              priority: sub.priority,
              layout: layout
            )
          }
          HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(sub.title)
              .font(AppTypography.taskTitle)
              .foregroundStyle(sub.done ? c.textTertiary : c.textPrimary)
              .strikethrough(sub.done)
              .lineLimit(2)
              .layoutPriority(1)
            Spacer(minLength: 4)
            if layout == .default, let timeDisplay = sub.timeDisplay, !timeDisplay.isEmpty {
              Text(timeDisplay)
                .font(AppTypography.timeChip)
                .foregroundStyle(c.textTertiary)
                .fixedSize()
            } else if layout.usesTrailingTimeColumn, let timeDisplay = sub.timeDisplay, !timeDisplay.isEmpty {
              Text(timeDisplay)
                .font(AppTypography.timeTrailing)
                .foregroundStyle(AppColors.dateUpcoming)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize()
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)

          if hasDescription, let desc = sub.description {
            NotesMarkupText(
              source: desc,
              color: c.textTertiary,
              size: 14,
              weight: .regular,
              boldWeight: .semibold,
              lineLimit: 2
            )
          }

          if showsMetaLine {
            TaskMetaLine(
              labels: labels,
              dueDate: sub.dueDate,
              priority: sub.priority,
              dueDateLabel: sub.dueDateChipLabel,
              dueDateColor: sub.dueDateChipColor,
              dateDone: sub.done,
              timeDisplay: sub.timeDisplay,
              maxLabels: 4
            )
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
      }
    }
    .padding(.vertical, hasMeta ? 8 : 2)
  }

  private func subtaskLabels(for sub: Subtask) -> [TaskLabel] {
    sub.labelIds.compactMap { id in vm.allLabels.first(where: { $0.id == id }) }
  }

  private var newSubtaskField: some View {
    let c = theme.colors

    return HStack(alignment: .center, spacing: 8) {
      newSubtaskPlusIcon

      TextField(
        "",
        text: $newSubtaskTitle,
        prompt: Text("Adicionar subtarefa")
          .font(AppTypography.taskTitle)
          .foregroundStyle(c.textTertiary)
      )
      .font(AppTypography.taskTitle)
      .foregroundStyle(c.textPrimary)
      .focused($newSubtaskFocused)
      .submitLabel(.done)
      .onSubmit {
        _Concurrency.Task { await submitNewSubtask() }
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .contentShape(Rectangle())
    .onTapGesture {
      HapticService.selection()
      newSubtaskFocused = true
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Adicionar subtarefa")
    .accessibilityHint("Toque para digitar uma nova subtarefa")
  }

  private var newSubtaskPlusIcon: some View {
    let c = theme.colors
    return ZStack {
      Circle()
        .fill(c.accent.opacity(DoneCircle.RingStyle.inactiveFillAlpha))
        .overlay(
          Circle().strokeBorder(c.accent.opacity(0.45), lineWidth: DoneCircle.RingStyle.borderWidth)
        )
        .frame(width: DoneCircle.listRowCircleSize, height: DoneCircle.listRowCircleSize)
      StackedIcons.image(.plus)
        .font(.system(size: 11, weight: .bold))
        .foregroundStyle(c.accent)
    }
    .frame(width: 32, height: 32)
    .accessibilityHidden(true)
  }

  @ViewBuilder
  private var descriptionNotesSection: some View {
    if anchoredDetailNotes {
      DetailNotesTriggerRow(text: vm.descriptionText) { rect in
        notesAnchor = rect
        showNotesPanel = true
      }
      .padding(.horizontal, 16)
      .padding(.top, 6)
      .padding(.bottom, 10)
    } else {
      descriptionNotesField
        .padding(.leading, 50)
        .padding(.trailing, 20)
        .padding(.top, 6)
        .padding(.bottom, 14)
    }
  }

  private var descriptionNotesField: some View {
    let c = theme.colors
    return TextField("Adicionar notas...", text: $vm.descriptionText, axis: .vertical)
      .font(AppTypography.commentBody)
      .foregroundStyle(c.textSecondary)
      .lineLimit(2...8)
      .focused($descriptionFocused)
      .onChange(of: vm.descriptionText) { _, _ in vm.onDescriptionChanged() }
  }

  private var commentsSection: some View {
    let count = vm.comments.count

    return VStack(alignment: .leading, spacing: 10) {
      detailSectionHeader(
        title: "Comentários",
        badge: count > 0 ? "\(count)" : nil,
        expanded: commentsExpanded
      ) {
        HapticService.selection()
        withAnimation(AppMotion.subtaskExpand(reduceMotion: reduceMotion)) {
          commentsExpanded.toggle()
        }
      }
      .accessibilityLabel(commentsExpanded ? "Recolher comentários" : "Expandir comentários")

      if commentsExpanded {
        detailSurfaceCard {
          ForEach(Array(vm.comments.enumerated()), id: \.element.id) { index, comment in
            commentRow(comment)
            if index < vm.comments.count - 1 {
              cardDivider(leadingInset: 16)
            }
          }

          if !vm.comments.isEmpty {
            cardDivider(leadingInset: 16)
          }

          commentComposerRow
        }
      }
    }
  }

  private func commentRow(_ comment: TaskComment) -> some View {
    let c = theme.colors
    return Text(comment.content)
      .font(AppTypography.commentBody)
      .foregroundStyle(c.textPrimary)
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var commentComposerRow: some View {
    let c = theme.colors
    let canSend = !vm.newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

    return HStack(spacing: 8) {
      TextField("Adicionar comentário…", text: $vm.newCommentText, axis: .vertical)
        .font(AppTypography.commentBody)
        .foregroundStyle(c.textPrimary)
        .lineLimit(1...3)
      Button {
        _Concurrency.Task { await vm.sendComment() }
      } label: {
        Image(systemName: "paperplane.fill")
          .foregroundStyle(canSend ? c.accent : c.textTertiary)
      }
      .disabled(!canSend)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
  }

  private func detailSectionHeader(
    title: String,
    badge: String?,
    expanded: Bool,
    onToggle: @escaping () -> Void
  ) -> some View {
    let c = theme.colors
    return Button(action: onToggle) {
      HStack(spacing: 8) {
        Text(title)
          .font(.system(size: 15, weight: .bold))
          .foregroundStyle(c.textPrimary)

        if let badge {
          Text(badge)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(c.textSecondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(c.accent.opacity(0.12))
            .clipShape(Capsule())
        }

        Spacer(minLength: 0)

        SubtaskExpandChevron(expanded: expanded, size: 14)
      }
      .padding(.horizontal, 4)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private func detailSurfaceCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    let c = theme.colors
    VStack(spacing: 0) {
      content()
    }
    .background(c.surface)
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .overlay(RoundedRectangle(cornerRadius: 14).stroke(c.textPrimary.opacity(0.06)))
  }

  private func cardDivider(leadingInset: CGFloat) -> some View {
    Rectangle()
      .fill(theme.colors.textTertiary.opacity(0.1))
      .frame(height: 1)
      .padding(.leading, leadingInset)
      .padding(.trailing, 16)
  }

  private var labelsSummary: String {
    let names = vm.selectedLabels.map(\.name)
    if names.isEmpty { return "Nenhuma" }
    if names.count == 1 { return names[0] }
    return "\(names[0]) +\(names.count - 1)"
  }

  private func metaRow(
    icon: StackedIconKey,
    title: String,
    value: String,
    active: Bool,
    valueColor: Color? = nil,
    action: @escaping (CGRect) -> Void
  ) -> some View {
    let c = theme.colors
    let accent = valueColor ?? (active ? c.textPrimary : c.textTertiary)
    return AnchoredTapButton(action: action) {
      HStack(spacing: 12) {
        StackedIcons.image(icon)
          .font(AppTypography.body)
          .foregroundStyle(active ? accent : c.textTertiary)
          .frame(width: 22)
        Text(title)
          .font(AppTypography.meta)
          .foregroundStyle(c.textTertiary)
        Spacer()
        Text(value)
          .font(AppTypography.metadataLabel)
          .foregroundStyle(active ? accent : c.textTertiary)
          .lineLimit(1)
        DisclosureChevron()
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .contentShape(Rectangle())
    }
  }

  private func fieldPill(_ title: String, icon: StackedIconKey, action: @escaping (CGRect) -> Void) -> some View {
    let c = theme.colors
    return AnchoredTapButton(action: action) {
      HStack(spacing: 6) {
        StackedIcons.image(icon)
          .font(AppTypography.metaSmall)
        Text(title)
          .font(AppTypography.metadataLabel)
      }
      .foregroundStyle(c.textSecondary)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(c.surfaceVariant)
      .clipShape(Capsule())
    }
  }

  private var whatsAppToolbarButton: some View {
    let c = theme.colors
    return Button {
      showWhatsAppPreview = true
    } label: {
      Text("WhatsApp")
        .font(.system(size: 11, weight: .bold))
        .foregroundStyle(c.accent)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(c.accent.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(c.accent.opacity(0.35), lineWidth: 1))
    }
    .accessibilityLabel("Copiar mensagem para WhatsApp")
  }

  private var whatsappRoutineRow: some View {
    let c = theme.colors
    let binding = Binding(
      get: { vm.whatsappRoutine },
      set: { vm.setWhatsappRoutine($0) }
    )
    return HStack(spacing: 12) {
      StackedIcons.image(.copy)
        .font(AppTypography.body)
        .foregroundStyle(c.textTertiary)
        .frame(width: 22)
      VStack(alignment: .leading, spacing: 2) {
        Text("Rotina WhatsApp")
          .font(AppTypography.metadataLabel)
          .foregroundStyle(c.textPrimary)
        Text("Copiar descrição formatada para WhatsApp")
          .font(AppTypography.metaSmall)
          .foregroundStyle(c.textTertiary)
      }
      Spacer(minLength: 8)
      Group {
        if vm.isLoading {
          Capsule()
            .fill(c.textTertiary.opacity(0.35))
            .frame(width: 51, height: 31)
        } else {
          SettingsSwitchToggle(isOn: binding, tint: c.actionAccent)
        }
      }
      .frame(width: 51, height: 44)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Rotina WhatsApp")
    .accessibilityValue(vm.whatsappRoutine ? "Ativada" : "Desativada")
  }

  private func showPriorityMenu(anchor: CGRect) {
    presentAnchoredPopover(anchorRect: anchor, items: [
      PopoverMenuItem(id: "none", icon: Hugeicons.flag01, label: "Sem prioridade",
                      selected: vm.priority == nil, iconColor: theme.colors.textTertiary),
      PopoverMenuItem(id: "high", icon: Hugeicons.flag01, label: "Prioridade 1",
                      selected: vm.priority == .high, iconColor: AppColors.priorityHigh),
      PopoverMenuItem(id: "medium", icon: Hugeicons.flag01, label: "Prioridade 2",
                      selected: vm.priority == .medium, iconColor: AppColors.priorityMedium),
      PopoverMenuItem(id: "low", icon: Hugeicons.flag01, label: "Prioridade 3",
                      selected: vm.priority == .low, iconColor: AppColors.priorityLow),
    ]) { result in
      guard let result else { return }
      switch result {
      case "none": vm.setPriority(nil)
      case "high": vm.setPriority(.high)
      case "medium": vm.setPriority(.medium)
      case "low": vm.setPriority(.low)
      default: break
      }
    }
  }

  private func showLabelsMenu(anchor: CGRect) {
    _Concurrency.Task {
      await vm.reloadLabels()
      let items = vm.allLabels.map { label in
        PopoverMenuItem(
          id: label.id,
          icon: Hugeicons.tag01,
          label: label.name,
          selected: vm.selectedLabelIds.contains(label.id),
          iconColor: label.color
        )
      }
      presentAnchoredPopover(anchorRect: anchor, items: items, allowsToggle: true) { result in
        guard let result else { return }
        var ids = vm.selectedLabelIds
        if ids.contains(result) { ids.remove(result) } else { ids.insert(result) }
        vm.setLabels(ids)
      }
    }
  }

  private func showProjectMenu(anchor: CGRect) {
    var items: [PopoverMenuItem] = [
      PopoverMenuItem(id: "none", icon: Hugeicons.inbox, label: "Sem projeto",
                      selected: vm.projectId == nil),
    ]
    for project in vm.allProjects {
      items.append(PopoverMenuItem(
        id: project.id,
        icon: Hugeicons.folder01,
        label: project.name,
        selected: vm.projectId == project.id,
        iconColor: project.color
      ))
    }
    presentAnchoredPopover(anchorRect: anchor, items: items) { result in
      guard let result else { return }
      if result == "none" {
        vm.setProject(nil)
        return
      }
      if let project = vm.allProjects.first(where: { $0.id == result }) {
        vm.setProject(project)
      }
    }
  }

  private func showRecurrenceMenu(anchor: CGRect) {
    var items = RecurrenceType.allCases.map { type in
      PopoverMenuItem(
        id: type.jsonTipo,
        icon: Hugeicons.repeatIcon,
        label: type.displayLabel,
        selected: vm.recurrenceType == type
      )
    }
    items.append(PopoverMenuItem(id: "none", icon: Hugeicons.repeatIcon, label: "Nenhuma",
                                 selected: vm.recurrence == nil))
    presentAnchoredPopover(anchorRect: anchor, items: items) { result in
      guard let result else { return }
      if result == "none" {
        vm.setRecurrence(nil)
      } else if let type = RecurrenceType.fromJsonTipo(result) {
        vm.setRecurrence(type)
      }
    }
  }

  private var divider: some View {
    Rectangle()
      .fill(theme.colors.textTertiary.opacity(0.12))
      .frame(height: 1)
  }

  private func initExpandedSectionsIfNeeded() {
    if !didInitSubtasksExpanded {
      subtasksExpanded = !vm.subtasks.isEmpty
      didInitSubtasksExpanded = true
    }
    if !didInitCommentsExpanded {
      commentsExpanded = false
      didInitCommentsExpanded = true
    }
  }

  private func close() {
    guard !isClosing else { return }
    isClosing = true
    // NET_FASEC_ETAPA1B — flush debounces antes de encerrar (X / Fechar).
    _Concurrency.Task {
      await vm.flushPendingAutosaves()
      await MainActor.run {
        if reduceMotion {
          dismiss()
          return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
          dismiss()
        }
      }
    }
  }

  private func submitNewSubtask() async {
    let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    newSubtaskTitle = ""
    await vm.addSubtask(title: trimmed)
    HapticService.saved()
  }
}
