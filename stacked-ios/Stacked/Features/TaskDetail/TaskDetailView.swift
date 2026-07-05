import SwiftUI
import Hugeicons

// Paridade lib/screens/task_detail_sheet.dart (mobile)
struct TaskDetailView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme

  @State private var vm: TaskDetailViewModel
  @State private var newSubtaskTitle = ""
  @FocusState private var newSubtaskFocused: Bool
  @FocusState private var descriptionFocused: Bool
  @State private var showDatePicker = false
  @State private var showDeleteConfirm = false
  @State private var subtaskDetailRoute: SubtaskDetailRoute?

  @State private var projectAnchor: CGRect = .zero
  @State private var dateAnchor: CGRect = .zero
  @State private var priorityAnchor: CGRect = .zero
  @State private var labelsAnchor: CGRect = .zero
  @State private var recurrenceAnchor: CGRect = .zero
  @State private var datePillAnchor: CGRect = .zero
  @State private var priorityPillAnchor: CGRect = .zero
  @State private var labelsPillAnchor: CGRect = .zero
  @State private var recurrencePillAnchor: CGRect = .zero
  @State private var installmentPillAnchor: CGRect = .zero
  @State private var installmentRoute: InstallmentGeneratorRoute?

  var onDismiss: () -> Void = {}

  init(taskId: String, onDismiss: @escaping () -> Void = {}) {
    _vm = State(initialValue: TaskDetailViewModel(taskId: taskId))
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
          await vm.load()
        }
        .environment(ThemeManager.shared)
        .presentationBackground(c.background)
        .presentationDragIndicator(.visible)
      }
      .task { await vm.load() }
      .popoverHostScope()
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

        descriptionNotesField
          .padding(.horizontal, 20)
          .padding(.top, 8)
          .padding(.bottom, 14)

        metadataCard
          .padding(.horizontal, 16)

        subtasksSection
          .padding(.horizontal, 16)
          .padding(.top, 20)

        commentsSection
          .padding(.horizontal, 16)
          .padding(.top, 20)
          .padding(.bottom, 40)
      }
    }
  }

  private var metadataCard: some View {
    let c = theme.colors

    return VStack(spacing: 0) {
      metaRow(icon: .folder, title: "Projeto", value: vm.projectName, active: vm.projectId != nil,
              valueColor: vm.allProjects.first(where: { $0.id == vm.projectId })?.color,
              anchor: $projectAnchor) {
        showProjectMenu(anchor: projectAnchor)
      }
      divider
      metaRow(icon: .calendar, title: "Data", value: vm.dueDateLabel, active: vm.dueDate != nil,
              valueColor: vm.dueDate.map { TaskMapper.dateColor(for: $0) },
              anchor: $dateAnchor) {
        showDatePicker = true
      }
      divider
      metaRow(icon: .flag, title: "Prioridade", value: vm.priority?.label ?? "Nenhuma",
              active: vm.priority != nil, valueColor: vm.priority?.color,
              anchor: $priorityAnchor) {
        showPriorityMenu(anchor: priorityAnchor)
      }
      divider
      metaRow(icon: .tag, title: "Etiquetas", value: labelsSummary, active: !vm.selectedLabels.isEmpty,
              valueColor: vm.selectedLabels.first?.color,
              anchor: $labelsAnchor) {
        showLabelsMenu(anchor: labelsAnchor)
      }
      if vm.recurrence != nil {
        divider
        metaRow(icon: .repeatIcon, title: "Recorrência", value: vm.recurrenceLabel, active: true,
                anchor: $recurrenceAnchor) {
          showRecurrenceMenu(anchor: recurrenceAnchor)
        }
      }

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          if vm.dueDate == nil {
            fieldPill("Data", icon: .calendar, anchor: $datePillAnchor) { showDatePicker = true }
          }
          if vm.priority == nil {
            fieldPill("Prioridade", icon: .flag, anchor: $priorityPillAnchor) { showPriorityMenu(anchor: priorityPillAnchor) }
          }
          if vm.selectedLabels.isEmpty {
            fieldPill("Etiquetas", icon: .tag, anchor: $labelsPillAnchor) { showLabelsMenu(anchor: labelsPillAnchor) }
          }
          if vm.recurrence == nil {
            fieldPill("Recorrência", icon: .repeatIcon, anchor: $recurrencePillAnchor) { showRecurrenceMenu(anchor: recurrencePillAnchor) }
          }
          fieldPill("Parcelas", icon: .money, anchor: $installmentPillAnchor) {
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
    let c = theme.colors

    return VStack(alignment: .leading, spacing: 8) {
      Text("Subtarefas")
        .font(AppTypography.detailSectionLabel)
        .foregroundStyle(c.textSecondary)

      VStack(spacing: 0) {
        ForEach(Array(vm.subtasks.enumerated()), id: \.element.idOrFallback) { index, sub in
          subtaskEditorRow(sub)
          if index < vm.subtasks.count - 1 {
            Divider()
              .overlay(c.textTertiary.opacity(0.08))
              .padding(.leading, 34)
          }
        }
      }

      newSubtaskField
    }
  }

  private func subtaskEditorRow(_ sub: Subtask) -> some View {
    let c = theme.colors
    return HStack(alignment: .center, spacing: 8) {
      Button {
        vm.toggleSubtask(sub)
      } label: {
        DoneCircle(
          done: sub.done,
          size: 20,
          borderWidth: 1.5,
          tickSize: 11,
          ringColor: c.textTertiary.opacity(0.4)
        )
        .frame(width: 32, height: 32)
      }
      .buttonStyle(.plain)

      Text(sub.title)
        .font(AppTypography.subtaskRowTitle.weight(.medium))
        .foregroundStyle(sub.done ? c.textTertiary : c.textPrimary)
        .strikethrough(sub.done)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
          subtaskDetailRoute = SubtaskDetailRoute(subtask: sub, parentTaskId: vm.taskId)
        }

      Button {
        HapticService.warning()
        _Concurrency.Task { await vm.deleteSubtask(sub) }
      } label: {
        Image(systemName: "trash")
          .font(AppTypography.meta)
          .foregroundStyle(c.textTertiary)
          .frame(width: 44, height: 36)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
    .padding(.vertical, 2)
    .contextMenu {
      Button(role: .destructive) {
        HapticService.warning()
        _Concurrency.Task { await vm.deleteSubtask(sub) }
      } label: {
        Label("Excluir subtarefa", systemImage: "trash")
      }
    }
  }

  private var newSubtaskField: some View {
    let c = theme.colors
    let canSubmit = !newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

    return HStack(spacing: 8) {
      Button {
        if canSubmit {
          _Concurrency.Task { await submitNewSubtask() }
        } else {
          HapticService.selection()
          newSubtaskFocused = true
        }
      } label: {
        StackedIcons.image(.plus)
          .font(AppTypography.body)
          .foregroundStyle(c.accent)
          .frame(width: 32, height: 32)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(canSubmit ? "Adicionar subtarefa" : "Focar campo de nova subtarefa")

      TextField("Nova subtarefa", text: $newSubtaskTitle)
        .font(AppTypography.commentBody)
        .foregroundStyle(c.textPrimary)
        .focused($newSubtaskFocused)
        .submitLabel(.done)
        .onSubmit {
          _Concurrency.Task { await submitNewSubtask() }
        }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 9)
    .background(c.surfaceVariant.opacity(0.45))
    .clipShape(RoundedRectangle(cornerRadius: 10))
    .overlay(
      RoundedRectangle(cornerRadius: 10)
        .stroke(
          newSubtaskFocused ? c.accent.opacity(0.5) : c.textTertiary.opacity(0.12),
          lineWidth: 1
        )
    )
    .contentShape(RoundedRectangle(cornerRadius: 10))
    .onTapGesture {
      newSubtaskFocused = true
    }
  }

  private var descriptionNotesField: some View {
    let c = theme.colors
    return TextField("Adicionar notas...", text: $vm.descriptionText, axis: .vertical)
      .font(AppTypography.commentBody)
      .foregroundStyle(c.textSecondary)
      .lineLimit(2...8)
      .padding(.horizontal, 12)
      .padding(.vertical, 9)
      .background(c.surfaceVariant.opacity(0.45))
      .clipShape(RoundedRectangle(cornerRadius: 10))
      .overlay(
        RoundedRectangle(cornerRadius: 10)
          .stroke(
            descriptionFocused ? c.accent.opacity(0.5) : c.textTertiary.opacity(0.12),
            lineWidth: 1
          )
      )
      .focused($descriptionFocused)
      .onChange(of: vm.descriptionText) { _, _ in vm.onDescriptionChanged() }
  }

  private var commentsSection: some View {
    let c = theme.colors

    return VStack(alignment: .leading, spacing: 10) {
      Text("Comentários")
        .font(AppTypography.detailSectionLabel)
        .foregroundStyle(c.textSecondary)

      ForEach(vm.comments) { comment in
        VStack(alignment: .leading, spacing: 4) {
          Text(comment.content)
            .font(AppTypography.commentBody)
            .foregroundStyle(c.textPrimary)
          Text(comment.createdAt, style: .relative)
            .font(.caption2)
            .foregroundStyle(c.textTertiary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(c.surfaceVariant.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 10))
      }

      HStack(spacing: 8) {
        TextField("Adicionar comentário…", text: $vm.newCommentText, axis: .vertical)
          .font(AppTypography.commentBody)
          .lineLimit(1...3)
        Button {
          _Concurrency.Task { await vm.sendComment() }
        } label: {
          Image(systemName: "paperplane.fill")
            .foregroundStyle(c.accent)
        }
        .disabled(vm.newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
      .background(c.surfaceVariant.opacity(0.5))
      .clipShape(RoundedRectangle(cornerRadius: 10))
    }
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
    anchor: Binding<CGRect>,
    action: @escaping () -> Void
  ) -> some View {
    let c = theme.colors
    let accent = valueColor ?? (active ? c.textPrimary : c.textTertiary)
    return Button(action: action) {
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
        StackedIcons.image(.chevronRight)
          .font(AppTypography.metaSmall.weight(.semibold))
          .foregroundStyle(c.textTertiary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
    }
    .buttonStyle(.plain)
    .readAnchor(anchor)
  }

  private func fieldPill(_ title: String, icon: StackedIconKey, anchor: Binding<CGRect>, action: @escaping () -> Void) -> some View {
    let c = theme.colors
    return Button(action: action) {
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
    .buttonStyle(.plain)
    .readAnchor(anchor)
  }

  private func showPriorityMenu(anchor: CGRect) {
    presentAnchoredPopover(anchorRect: anchor, items: [
      PopoverMenuItem(id: "none", icon: Hugeicons.flag01, label: "Sem prioridade",
                      selected: vm.priority == nil, iconColor: Color(hex: 0x6B6E76)),
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
      .padding(.leading, 50)
  }

  private func close() {
    dismiss()
  }

  private func submitNewSubtask() async {
    let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    newSubtaskTitle = ""
    await vm.addSubtask(title: trimmed)
    HapticService.saved()
  }
}
