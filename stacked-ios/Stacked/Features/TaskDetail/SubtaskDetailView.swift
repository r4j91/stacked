import SwiftUI
import Hugeicons

// Paridade lib/widgets/task_detail/sheets/subtask_detail_sheet.dart
struct SubtaskDetailView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme

  let subtask: Subtask
  let parentTaskId: String
  var parentTaskTitle: String?
  var onChanged: (SubtaskSaveSnapshot?) async -> Void

  @State private var title: String
  @State private var descriptionText: String
  @State private var done: Bool
  @State private var priority: Priority?
  @State private var dueDate: Date?
  @State private var selectedLabelIds: Set<String> = []
  @State private var labels: [TaskLabel] = []
  @State private var saving = false
  @State private var saveError: String?
  @State private var showDatePicker = false
  @State private var resolvedSubtaskId: String?

  @State private var priorityAnchor: CGRect = .zero
  @State private var dateAnchor: CGRect = .zero
  @State private var labelsAnchor: CGRect = .zero

  private var persistSubtaskId: String? {
    if let resolvedSubtaskId, !resolvedSubtaskId.isEmpty { return resolvedSubtaskId }
    if let id = subtask.id, !id.isEmpty { return id }
    return nil
  }

  init(
    subtask: Subtask,
    parentTaskId: String,
    parentTaskTitle: String? = nil,
    onChanged: @escaping (SubtaskSaveSnapshot?) async -> Void
  ) {
    self.subtask = subtask
    self.parentTaskId = parentTaskId
    self.parentTaskTitle = parentTaskTitle
    self.onChanged = onChanged
    _title = State(initialValue: subtask.title)
    _descriptionText = State(initialValue: subtask.description ?? "")
    _done = State(initialValue: subtask.done)
    _priority = State(initialValue: subtask.priority)
    _dueDate = State(initialValue: subtask.dueDate)
    _selectedLabelIds = State(initialValue: Set(subtask.labelIds))
    _resolvedSubtaskId = State(initialValue: subtask.id)
  }

  var body: some View {
    let c = theme.colors

    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          HStack(spacing: 12) {
            Button {
              _Concurrency.Task { await toggleDone() }
            } label: {
              DoneCircle(
                done: done,
                size: 22,
                borderWidth: 1.8,
                tickSize: 11,
                ringColor: priority?.color ?? c.textTertiary.opacity(0.45)
              )
            }
            .buttonStyle(.plain)

            TextField("Nova subtarefa", text: $title)
              .font(.system(size: 20, weight: .bold))
              .foregroundStyle(c.textPrimary)
              .onSubmit { _Concurrency.Task { await flushPending() } }
          }
          .padding(.horizontal, 20)

          if let parentTaskTitle, !parentTaskTitle.isEmpty {
            HStack(spacing: 4) {
              StackedIcons.icon(.chevronDown, size: 12, color: c.textTertiary)
              Text(parentTaskTitle)
                .font(.system(size: 11))
                .foregroundStyle(c.textTertiary)
            }
            .padding(.horizontal, 36)
          }

          TextField("Adicionar notas...", text: $descriptionText, axis: .vertical)
            .font(.system(size: 14))
            .foregroundStyle(c.textSecondary)
            .lineLimit(2...6)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(c.surfaceVariant.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(c.textTertiary.opacity(0.12)))
            .padding(.horizontal, 20)
            .onSubmit { _Concurrency.Task { await flushPending() } }

          if let saveError {
            Text(saveError)
              .font(.system(size: 13))
              .foregroundStyle(AppColors.priorityHigh)
              .padding(.horizontal, 20)
          }

          metadataCard
            .padding(.horizontal, 16)
        }
        .padding(.top, 8)
        .padding(.bottom, 24)
      }
      .background(c.background)
      .presentationBackground(c.background)
      .navigationTitle("Subtarefa")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Fechar") {
            _Concurrency.Task {
              await flushPending()
              dismiss()
            }
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Salvar") {
            _Concurrency.Task {
              await flushPending()
              if saveError == nil { dismiss() }
            }
          }
          .disabled(saving)
          .foregroundStyle(c.accent)
        }
      }
      .popoverHostScope()
      .task { await reloadLabels() }
      .onReceive(NotificationCenter.default.publisher(for: .labelsCatalogDidChange)) { _ in
        _Concurrency.Task { await reloadLabels() }
      }
      .stackedTaskDatePickerSheet(
        isPresented: $showDatePicker,
        initialDate: dueDate,
        showRecurrence: false
      ) { date, _ in
        dueDate = date
        _Concurrency.Task { await flushPending() }
      }
    }
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
  }

  private var metadataCard: some View {
    let c = theme.colors

    return VStack(spacing: 0) {
      metaRow(
        icon: .flag,
        title: "Prioridade",
        value: priorityLabel,
        active: priority != nil,
        valueColor: priority?.color,
        anchor: $priorityAnchor
      ) { showPriorityMenu() }

      Divider().overlay(c.textTertiary.opacity(0.12))

      metaRow(
        icon: .calendar,
        title: "Data",
        value: dueDateLabel,
        active: dueDate != nil,
        valueColor: dueDate.map { TaskMapper.dateColor(for: $0) },
        anchor: $dateAnchor
      ) { showDatePicker = true }

      Divider().overlay(c.textTertiary.opacity(0.12))

      metaRow(
        icon: .tag,
        title: "Etiquetas",
        value: labelsSummary,
        active: !selectedLabelIds.isEmpty,
        valueColor: labels.first(where: { selectedLabelIds.contains($0.id) })?.color,
        anchor: $labelsAnchor
      ) { showLabelsMenu() }
    }
    .background(c.surface)
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .overlay(RoundedRectangle(cornerRadius: 14).stroke(c.textPrimary.opacity(0.06)))
  }

  private var priorityLabel: String {
    switch priority {
    case .high: "P1"
    case .medium: "P2"
    case .low: "P3"
    case nil: "Nenhuma"
    }
  }

  private var dueDateLabel: String {
    guard let dueDate else { return "Nenhuma" }
    return TaskMapper.dayLabel(for: dueDate)
  }

  private var labelsSummary: String {
    let names = labels.filter { selectedLabelIds.contains($0.id) }.map(\.name)
    if names.isEmpty { return "Nenhuma" }
    if names.count == 1 { return names[0] }
    return "\(names[0]) +\(names.count - 1)"
  }

  private func reloadLabels() async {
    labels = (try? await LabelRepository.shared.fetchLabels()) ?? []
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
          .font(.system(size: 16))
          .foregroundStyle(active ? accent : c.textTertiary)
          .frame(width: 22)
        Text(title)
          .font(.system(size: 13))
          .foregroundStyle(c.textTertiary)
        Spacer()
        Text(value)
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(active ? accent : c.textTertiary)
          .lineLimit(1)
        StackedIcons.image(.chevronRight)
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(c.textTertiary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
    }
    .buttonStyle(.plain)
    .readAnchor(anchor)
  }

  private func showPriorityMenu() {
    presentAnchoredPopover(anchorRect: priorityAnchor, items: [
      PopoverMenuItem(id: "none", icon: Hugeicons.flag01, label: "Sem prioridade",
                      selected: priority == nil, iconColor: Color(hex: 0x6B6E76)),
      PopoverMenuItem(id: "high", icon: Hugeicons.flag01, label: "Prioridade 1",
                      selected: priority == .high, iconColor: AppColors.priorityHigh),
      PopoverMenuItem(id: "medium", icon: Hugeicons.flag01, label: "Prioridade 2",
                      selected: priority == .medium, iconColor: AppColors.priorityMedium),
      PopoverMenuItem(id: "low", icon: Hugeicons.flag01, label: "Prioridade 3",
                      selected: priority == .low, iconColor: AppColors.priorityLow),
    ]) { result in
      guard let result else { return }
      switch result {
      case "high": priority = .high
      case "medium": priority = .medium
      case "low": priority = .low
      case "none": priority = nil
      default: break
      }
      _Concurrency.Task { await flushPending() }
    }
  }

  private func showLabelsMenu() {
    _Concurrency.Task {
      await reloadLabels()
      let items = labels.map { label in
        PopoverMenuItem(
          id: label.id,
          icon: Hugeicons.tag01,
          label: label.name,
          selected: selectedLabelIds.contains(label.id),
          iconColor: label.color
        )
      }
      presentAnchoredPopover(anchorRect: labelsAnchor, items: items, allowsToggle: true) { result in
        guard let result else { return }
        if selectedLabelIds.contains(result) {
          selectedLabelIds.remove(result)
        } else {
          selectedLabelIds.insert(result)
        }
        _Concurrency.Task { await flushPending() }
      }
    }
  }

  private func currentSnapshot(resolvedId: String?) -> SubtaskSaveSnapshot {
    SubtaskSaveSnapshot(
      parentTaskId: parentTaskId,
      order: subtask.order,
      resolvedId: resolvedId,
      title: title.trimmingCharacters(in: .whitespacesAndNewlines),
      description: {
        let trimmed = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
      }(),
      done: done,
      priority: priority,
      dueDate: dueDate,
      labelIds: Array(selectedLabelIds)
    )
  }

  private func notifyChanged(resolvedId: String?) async {
    await onChanged(currentSnapshot(resolvedId: resolvedId ?? persistSubtaskId))
  }

  private func toggleDone() async {
    let newValue = !done
    done = newValue
    do {
      var activeId = persistSubtaskId
      let resolved = try await SubtaskRepository.shared.persistSubtask(
        id: activeId,
        taskId: parentTaskId,
        order: subtask.order,
        payload: TogglePayload(concluida: newValue)
      )
      if let resolved {
        activeId = resolved
        resolvedSubtaskId = resolved
      }
      HapticService.taskCompleted()
      await notifyChanged(resolvedId: activeId)
    } catch {
      done = !newValue
      saveError = error.localizedDescription
    }
  }

  private struct TogglePayload: Encodable {
    let concluida: Bool
  }

  private func flushPending() async {
    saving = true
    saveError = nil
    defer { saving = false }

    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedDesc = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
    let initialDesc = (subtask.description ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let titleChanged = !trimmedTitle.isEmpty && trimmedTitle != subtask.title
    let descChanged = trimmedDesc != initialDesc
    let metaChanged = priority != subtask.priority
      || dueDate != subtask.dueDate
      || selectedLabelIds != Set(subtask.labelIds)

    guard titleChanged || descChanged || metaChanged else { return }

    var activeId = persistSubtaskId

    do {
      if titleChanged {
        let resolved = try await SubtaskRepository.shared.persistSubtask(
          id: activeId,
          taskId: parentTaskId,
          order: subtask.order,
          payload: TitlePayload(titulo: trimmedTitle)
        )
        if let resolved {
          activeId = resolved
          resolvedSubtaskId = resolved
        }
      }

      if descChanged {
        do {
          let resolved = try await SubtaskRepository.shared.persistSubtask(
            id: activeId,
            taskId: parentTaskId,
            order: subtask.order,
            payload: DescriptionPayload(descricao: trimmedDesc.isEmpty ? nil : trimmedDesc)
          )
          if let resolved {
            activeId = resolved
            resolvedSubtaskId = resolved
          }
        } catch {
          guard SubtaskRepository.shared.isMissingDescriptionColumn(error) else { throw error }
        }
      }

      if metaChanged {
        let dueISO = dueDate.map { TaskMapper.dateString($0) }
        try await SubtaskRepository.shared.updateMetadata(
          id: activeId,
          taskId: parentTaskId,
          order: subtask.order,
          priority: priority,
          dueDateISO: dueISO,
          labelIds: Array(selectedLabelIds)
        )
      }

      await notifyChanged(resolvedId: activeId)
      HapticService.saved()
    } catch {
      saveError = error.localizedDescription
    }
  }

  private struct TitlePayload: Encodable {
    let titulo: String
  }

  private struct DescriptionPayload: Encodable {
    let descricao: String?

    enum CodingKeys: String, CodingKey { case descricao }

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      if let descricao {
        try container.encode(descricao, forKey: .descricao)
      } else {
        try container.encodeNil(forKey: .descricao)
      }
    }
  }
}
