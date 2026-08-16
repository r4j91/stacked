import SwiftUI
import UIKit
import Hugeicons

// Paridade lib/widgets/task_detail/sheets/subtask_detail_sheet.dart
struct SubtaskDetailView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme

  let subtask: Subtask
  let parentTaskId: String
  var parentTaskTitle: String?
  var onChanged: (SubtaskSaveSnapshot?) async -> Void
  private let initialAccountId: String?

  @State private var title: String
  @State private var descriptionText: String
  @State private var done: Bool
  @State private var priority: Priority?
  @State private var dueDate: Date?
  @State private var dueTimeDate: Date?
  @State private var deadline: Date?
  @State private var selectedLabelIds: [String] = []
  @State private var labels: [TaskLabel] = []
  @State private var valorText: String
  @FocusState private var valorFieldFocused: Bool
  @State private var selectedAccountId: String?
  @State private var moneyStore = MoneyStore.shared
  @State private var includeInCashFlow = true
  @State private var includeInCashFlowReady = false
  @State private var saving = false
  @State private var saveError: String?
  @State private var showDatePicker = false
  @State private var showDeadlinePicker = false
  @State private var resolvedSubtaskId: String?
  @State private var attachmentsExpanded = false
  @State private var attachmentPickRequest: AttachmentPickRequest?

  @State private var showNotesPanel = false
  @State private var notesAnchor: CGRect = .zero

  @AppStorage(ProductivityPreferences.anchoredDetailNotesKey) private var anchoredDetailNotes = false

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
    initialAccountId = MoneyStore.shared.linkedAccountId(forSubtaskId: subtask.id)
    _title = State(initialValue: subtask.title)
    _descriptionText = State(initialValue: subtask.description ?? "")
    _done = State(initialValue: subtask.done)
    _priority = State(initialValue: subtask.priority)
    _dueDate = State(initialValue: subtask.dueDate)
    _dueTimeDate = State(initialValue: {
      guard let dueDate = subtask.dueDate, let time = subtask.time, !time.isEmpty else { return nil }
      return TaskMapper.combinedDateTime(dueDate: dueDate, time: time)
    }())
    _deadline = State(initialValue: subtask.deadline)
    _selectedLabelIds = State(initialValue: subtask.labelIds)
    _resolvedSubtaskId = State(initialValue: subtask.id)
    _valorText = State(initialValue: InstallmentGeneratorLogic.editingText(for: subtask.valor))
    _selectedAccountId = State(initialValue: initialAccountId)
    _includeInCashFlow = State(initialValue: subtask.includeInCashFlow)
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
              PriorityDot(priority: priority, done: done)
            }
            .buttonStyle(PressableStyle(onPrepare: HapticService.prepareTaskComplete))

            VStack(alignment: .leading, spacing: 4) {
              TextField("Nova subtarefa", text: $title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(c.textPrimary)
                .onSubmit { _Concurrency.Task { await flushPending() } }
              if let valor = parsedValor {
                Text(CurrencyFormat.brl(valor))
                  .font(.system(size: 16, weight: .semibold))
                  .foregroundStyle(c.accent)
                  .monospacedDigit()
              }
            }
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

          if anchoredDetailNotes {
            DetailNotesTriggerRow(text: descriptionText) { rect in
              notesAnchor = rect
              showNotesPanel = true
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 10)
          } else {
            TextField("Adicionar notas...", text: $descriptionText, axis: .vertical)
              .font(AppTypography.commentBody)
              .foregroundStyle(c.textSecondary)
              .lineLimit(2...8)
              .padding(.leading, 54)
              .padding(.trailing, 20)
              .padding(.top, 6)
              .padding(.bottom, 14)
              .onSubmit { _Concurrency.Task { await flushPending() } }
          }

          if let saveError {
            Text(saveError)
              .font(.system(size: 13))
              .foregroundStyle(AppColors.priorityHigh)
              .padding(.horizontal, 20)
          }

          metadataCard
            .padding(.horizontal, 16)

          if let sid = persistSubtaskId {
            AttachmentsSection(
              taskId: parentTaskId,
              subtaskId: sid,
              expanded: $attachmentsExpanded,
              pickRequest: $attachmentPickRequest
            )
              .padding(.horizontal, 16)
          }
        }
        .padding(.top, 8)
        .padding(.bottom, 24)
      }
      .background(c.background)
      .presentationBackground(c.background)
      .navigationTitle("Subtarefa")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        let isolate = GlassChromePreference.prefersStaticToolbarPills()
        ToolbarItem(id: "stacked-subtask-close", placement: .cancellationAction) {
          StackedToolbarTextButton(title: "Fechar") {
            resignValorField()
            _Concurrency.Task {
              await flushPending(playSaveHaptic: true)
              dismiss()
            }
          }
        }
        .stackedToolbarGlassIsolation(isolate)

        ToolbarItem(id: "stacked-subtask-save", placement: .confirmationAction) {
          StackedToolbarTextButton(title: "Salvar", accent: true, enabled: !saving) {
            resignValorField()
            _Concurrency.Task {
              await flushPending(playSaveHaptic: true)
              if saveError == nil { dismiss() }
            }
          }
        }
        .stackedToolbarGlassIsolation(isolate)
      }
      .toolbar {
        ToolbarItemGroup(placement: .keyboard) {
          Spacer()
          Button("OK") {
            resignValorField()
            _Concurrency.Task { await flushPending() }
          }
          .font(.system(size: 16, weight: .semibold))
        }
      }
      .popoverHostScope()
      .overlay {
        if showNotesPanel {
          GeometryReader { geo in
            AnchoredNotesPopoverOverlay(
              anchorRect: notesAnchor,
              text: $descriptionText,
              hostBounds: geo.frame(in: .global),
              title: "Notas da subtarefa",
              onDismiss: { showNotesPanel = false }
            )
          }
          .ignoresSafeArea()
        }
      }
      .task {
        await reloadLabels()
        await loadCashFlowPreference()
      }
      .onReceive(NotificationCenter.default.publisher(for: .labelsCatalogDidChange)) { _ in
        _Concurrency.Task { await reloadLabels() }
      }
      .stackedTaskDatePickerSheet(
        isPresented: $showDatePicker,
        initialDate: dueDate,
        initialTime: dueTimeDate,
        showRecurrence: false
      ) { date, timeDate in
        dueDate = date
        if date == nil {
          dueTimeDate = nil
        } else {
          dueTimeDate = timeDate
        }
        _Concurrency.Task { await flushPending() }
      }
      .stackedTaskDatePickerSheet(
        isPresented: $showDeadlinePicker,
        initialDate: deadline,
        showRecurrence: false,
        showsTime: false,
        title: "Prazo"
      ) { date, _ in
        deadline = date
        _Concurrency.Task { await flushPending() }
      }
    }
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
    // NET_FASEC_ETAPA1B — swipe dismiss também flusha.
    .onDisappear {
      _Concurrency.Task { await flushPending() }
    }
  }

  private var parsedValor: Double? {
    InstallmentGeneratorLogic.parseValor(valorText)
  }

  private var metadataCard: some View {
    let c = theme.colors
    let hasPriority = priority != nil
    let hasDueDate = dueDate != nil
    let hasDeadline = deadline != nil
    let hasLabels = !selectedLabelIds.isEmpty
    let hasFilledMeta = hasPriority || hasDueDate || hasDeadline || hasLabels
    let showAttachmentPill = persistSubtaskId != nil
    let showPills =
      !hasPriority || !hasDueDate || !hasDeadline || !hasLabels || showAttachmentPill

    return VStack(spacing: 0) {
      if hasPriority {
        metaRow(
          icon: .flag,
          title: "Prioridade",
          value: priorityLabel,
          active: true,
          valueColor: priority?.color
        ) { showPriorityMenu(anchor: $0) }
      }

      if hasDueDate {
        if hasPriority { metaDivider }
        metaRow(
          icon: .calendar,
          title: "Data",
          value: dueDateLabel,
          active: true,
          valueColor: dueDate.map { TaskMapper.dateColor(for: $0, done: subtask.done) }
        ) { _ in showDatePicker = true }
      }

      if hasDeadline {
        if hasPriority || hasDueDate { metaDivider }
        metaRow(
          icon: .target,
          title: "Prazo",
          value: deadlineLabel,
          active: true,
          valueColor: deadline.map { TaskMapper.deadlineColor(for: $0, done: done) }
        ) { _ in showDeadlinePicker = true }
      }

      if hasLabels {
        if hasPriority || hasDueDate || hasDeadline { metaDivider }
        metaRow(
          icon: .tag,
          title: "Etiquetas",
          value: labelsSummary,
          active: true,
          valueColor: LabelIdOrder.resolve(selectedLabelIds, from: labels, id: \.id).first?.color
        ) { showLabelsMenu(anchor: $0) }
      }

      if hasFilledMeta { metaDivider }
      valorMetaRow
      metaDivider
      metaRow(
        icon: .money,
        title: "Conta",
        value: accountLabel,
        active: selectedAccountId != nil,
        valueColor: selectedAccountId != nil ? c.accent : nil
      ) { showAccountMenu(anchor: $0) }
      metaDivider
      cashFlowIncludeRow

      if showPills {
        metaDivider
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            if !hasDueDate {
              fieldPill("Data", icon: .calendar) { _ in showDatePicker = true }
            }
            if !hasDeadline {
              fieldPill("Prazo", icon: .target) { _ in showDeadlinePicker = true }
            }
            if !hasPriority {
              fieldPill("Prioridade", icon: .flag) { showPriorityMenu(anchor: $0) }
            }
            if !hasLabels {
              fieldPill("Etiquetas", icon: .tag) { showLabelsMenu(anchor: $0) }
            }
            if showAttachmentPill {
              fieldPill("Anexo", icon: .attachment) { showAttachmentMenu(anchor: $0) }
            }
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
        }
      }
    }
    .background(c.surface)
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .overlay(RoundedRectangle(cornerRadius: 14).stroke(c.textPrimary.opacity(0.06)))
  }

  private var valorMetaRow: some View {
    let c = theme.colors
    let hasValor = parsedValor != nil
    return HStack(spacing: 12) {
      StackedIcons.image(.money)
        .font(AppTypography.body)
        .foregroundStyle(hasValor ? c.accent : c.textTertiary)
        .frame(width: 22)
      Text("Valor")
        .font(AppTypography.metadataLabel)
        .foregroundStyle(c.textPrimary)
      Spacer(minLength: 8)
      TextField("0,00", text: $valorText)
        .font(AppTypography.metadataLabel)
        .foregroundStyle(hasValor ? c.accent : c.textTertiary)
        .keyboardType(.decimalPad)
        .multilineTextAlignment(.trailing)
        .focused($valorFieldFocused)
        .onSubmit { _Concurrency.Task { await flushPending() } }
        .onChange(of: valorFieldFocused) { _, focused in
          if !focused {
            _Concurrency.Task { await flushPending() }
          }
        }
      Color.clear
        .frame(width: 12)
        .accessibilityHidden(true)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
  }

  private var cashFlowIncludeRow: some View {
    let c = theme.colors
    let binding = Binding(
      get: { includeInCashFlow },
      set: { setIncludeInCashFlow($0) }
    )
    return HStack(spacing: 12) {
      StackedIcons.image(.cashFlow)
        .font(AppTypography.body)
        .foregroundStyle(c.textTertiary)
        .frame(width: 22)
      VStack(alignment: .leading, spacing: 2) {
        Text("A pagar e fluxo")
          .font(AppTypography.metadataLabel)
          .foregroundStyle(c.textPrimary)
        Text("Incluir valores desta subtarefa no Dinheiro")
          .font(AppTypography.metaSmall)
          .foregroundStyle(c.textTertiary)
      }
      Spacer(minLength: 8)
      SettingsSwitchToggle(isOn: binding, tint: c.actionAccent)
        .frame(width: 51, height: 44)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Incluir em A pagar e no fluxo de caixa")
    .accessibilityValue(includeInCashFlow ? "Ativado" : "Desativado")
  }

  private func loadCashFlowPreference() async {
    // Preferência já vem da subtarefa; se o select ainda não tinha a coluna, recarrega o pai
    // só para sincronizar o interruptor geral da tarefa (não sobrescreve a subtarefa).
    includeInCashFlowReady = true
    if let refreshed = try? await TaskRepository.shared.fetchTaskById(parentTaskId),
       let sid = persistSubtaskId,
       let match = refreshed.subtasks.first(where: { $0.id == sid })
    {
      includeInCashFlow = match.includeInCashFlow
    }
  }

  private func setIncludeInCashFlow(_ enabled: Bool) {
    includeInCashFlow = enabled
    guard includeInCashFlowReady else { return }
    _Concurrency.Task {
      do {
        try await SubtaskRepository.shared.updateIncludeInCashFlow(
          id: persistSubtaskId,
          taskId: parentTaskId,
          order: subtask.order,
          enabled: enabled
        )
        await MoneyStore.shared.load()
      } catch {
        saveError = error.localizedDescription
        includeInCashFlow = !enabled
      }
    }
  }

  private var accountLabel: String {
    if let id = selectedAccountId, let account = moneyStore.accounts.first(where: { $0.id == id }) {
      return moneyStore.displayName(for: account)
    }
    return "Nenhuma"
  }

  private var metaDivider: some View {
    Divider().overlay(theme.colors.textTertiary.opacity(0.12))
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
    var label = TaskMapper.dayLabel(for: dueDate)
    if let dueTimeDate {
      label += " · \(TaskMapper.formatTimeDisplay(TaskMapper.timeString(from: dueTimeDate)))"
    }
    return label
  }

  private var deadlineLabel: String {
    guard let deadline else { return "Sem prazo" }
    return TaskMapper.deadlineChipLabel(for: deadline)
  }

  private var currentTimeString: String? {
    guard dueDate != nil, let dueTimeDate else { return nil }
    return TaskMapper.timeString(from: dueTimeDate)
  }

  private var labelsSummary: String {
    let names = LabelIdOrder.resolve(selectedLabelIds, from: labels, id: \.id).map(\.name)
    if names.isEmpty { return "Nenhuma" }
    if names.count == 1 { return names[0] }
    return "\(names[0]) +\(names.count - 1)"
  }

  private func reloadLabels() async {
    labels = (try? await LabelRepository.shared.fetchLabels()) ?? []
  }

  private func showAttachmentMenu(anchor: CGRect) {
    presentAttachmentSourceMenu(anchor: anchor) { request in
      attachmentPickRequest = request
    }
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
          .font(AppTypography.metadataLabel)
          .foregroundStyle(c.textPrimary)
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
        StackedIcons.icon(icon, size: 14, color: c.textSecondary)
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

  private func showPriorityMenu(anchor: CGRect) {
    presentAnchoredPopover(anchorRect: anchor, items: [
      PopoverMenuItem(id: "none", icon: Hugeicons.flag01, label: "Sem prioridade",
                      selected: priority == nil, iconColor: theme.colors.textTertiary),
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

  private func showLabelsMenu(anchor: CGRect) {
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
      presentAnchoredPopover(anchorRect: anchor, items: items, allowsToggle: true) { result in
        guard let result else { return }
        selectedLabelIds = LabelIdOrder.toggle(selectedLabelIds, id: result)
        _Concurrency.Task { await flushPending() }
      }
    }
  }

  private func showAccountMenu(anchor: CGRect) {
    let c = theme.colors
    var items: [PopoverMenuItem] = [
      PopoverMenuItem(
        id: "none",
        icon: Hugeicons.cancel01,
        label: "Nenhuma",
        selected: selectedAccountId == nil,
        iconColor: c.textTertiary
      )
    ]
    items.append(contentsOf: moneyStore.accounts.map { account in
      PopoverMenuItem(
        id: account.id,
        icon: Hugeicons.money01,
        label: moneyStore.displayName(for: account),
        selected: selectedAccountId == account.id,
        iconColor: c.accent
      )
    })
    presentAnchoredPopover(anchorRect: anchor, items: items) { result in
      guard let result else { return }
      selectedAccountId = result == "none" ? nil : result
      persistObligationLink(subtaskId: persistSubtaskId)
      _Concurrency.Task { await flushPending() }
    }
  }

  private func persistObligationLink(subtaskId: String?) {
    guard let subtaskId, !subtaskId.isEmpty else { return }
    MoneyStore.shared.setAccount(
      forSubtaskId: subtaskId,
      accountId: selectedAccountId,
      valor: parsedValor
    )
  }

  private static func sameValor(_ lhs: Double?, _ rhs: Double?) -> Bool {
    switch (lhs, rhs) {
    case (nil, nil):
      return true
    case let (a?, b?):
      return abs(a - b) < 0.000_1
    default:
      return false
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
      time: currentTimeString,
      deadline: deadline,
      labelIds: selectedLabelIds,
      valor: parsedValor
    )
  }

  private func notifyChanged(resolvedId: String?) async {
    await onChanged(currentSnapshot(resolvedId: resolvedId ?? persistSubtaskId))
  }

  private func toggleDone() async {
    let newValue = !done
    done = newValue
    if newValue {
      HapticService.taskCompleted()
    } else {
      HapticService.light()
    }
    do {
      var activeId = persistSubtaskId
      let resolved = try await SubtaskRepository.shared.persistSubtask(
        id: activeId,
        taskId: parentTaskId,
        order: subtask.order,
        payload: TogglePayload(
          concluida: newValue,
          data_conclusao: newValue ? TaskMapper.isoTimestamp(Date()) : nil
        )
      )
      if let resolved {
        activeId = resolved
        resolvedSubtaskId = resolved
      }
      await notifyChanged(resolvedId: activeId)
      if let activeId {
        MoneyStore.shared.handleToggleDone(
          subtaskId: activeId,
          done: newValue,
          valor: parsedValor,
          title: title.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        if newValue {
          await NotificationService.shared.cancelSubtaskNotification(id: activeId)
          TaskCalendarSync.remove(subtaskId: activeId)
        } else {
          await NotificationService.shared.syncSubtaskNotification(
            id: activeId,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? subtask.title : title,
            dueDate: dueDate,
            time: currentTimeString,
            done: false
          )
          TaskCalendarSync.syncAfterSubtaskMutation(
            subtaskId: activeId,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? subtask.title : title,
            dueDate: dueDate,
            time: currentTimeString,
            done: false
          )
        }
      }
    } catch {
      done = !newValue
      saveError = error.localizedDescription
    }
  }

  private struct TogglePayload: Encodable {
    let concluida: Bool
    let data_conclusao: String?
  }

  private func resignValorField() {
    valorFieldFocused = false
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }

  private func flushPending(playSaveHaptic: Bool = false) async {
    resignValorField()
    try? await _Concurrency.Task.sleep(for: .milliseconds(80))
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
      || currentTimeString != subtask.time
      || deadline != subtask.deadline
      || selectedLabelIds != subtask.labelIds
    let valorChanged = !Self.sameValor(parsedValor, subtask.valor)
    let accountChanged = selectedAccountId != initialAccountId

    guard titleChanged || descChanged || metaChanged || valorChanged || accountChanged else { return }

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
        let deadlineISO = deadline.map { TaskMapper.dateString($0) }
        let savedTime = currentTimeString
        try await SubtaskRepository.shared.updateMetadata(
          id: activeId,
          taskId: parentTaskId,
          order: subtask.order,
          priority: priority,
          dueDateISO: dueISO,
          time: savedTime,
          deadlineISO: deadlineISO,
          labelIds: selectedLabelIds
        )
        if let activeId {
          await NotificationService.shared.syncSubtaskNotification(
            id: activeId,
            title: trimmedTitle.isEmpty ? subtask.title : trimmedTitle,
            dueDate: dueDate,
            time: savedTime,
            done: done
          )
          TaskCalendarSync.syncAfterSubtaskMutation(
            subtaskId: activeId,
            title: trimmedTitle.isEmpty ? subtask.title : trimmedTitle,
            dueDate: dueDate,
            time: savedTime,
            done: done
          )
        }
      }

      if valorChanged {
        try await SubtaskRepository.shared.updateValor(
          id: activeId,
          taskId: parentTaskId,
          order: subtask.order,
          valor: parsedValor
        )
        if let activeId {
          MoneyStore.shared.updateLinkedValor(subtaskId: activeId, valor: parsedValor)
        }
        _Concurrency.Task { await MoneyStore.shared.load() }
      }

      persistObligationLink(subtaskId: activeId)

      await notifyChanged(resolvedId: activeId)
      if playSaveHaptic {
        HapticService.saved()
      }
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
