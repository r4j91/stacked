import SwiftUI
import Hugeicons

// Paridade lib/screens/quick_add_task_sheet.dart
struct QuickAddTaskView: View {
  @Environment(ThemeManager.self) private var theme

  var initialProjectId: String?
  var initialSectionId: String?
  var onSaved: () -> Void
  var onDismiss: () -> Void

  @FocusState private var titleFocused: Bool
  @State private var title = ""
  @State private var descriptionText = ""
  @State private var priority: Priority?
  @State private var dueDate: Date?
  @State private var dueTime: Date?
  @State private var selectedProjectId: String?
  @State private var selectedSectionId: String?
  @State private var selectedLabelIds: Set<String> = []
  @State private var projects: [Project] = []
  @State private var sections: [ProjectSection] = []
  @State private var labels: [TaskLabel] = []
  @State private var saving = false
  @State private var error: String?
  @State private var showDatePicker = false

  private let iconCircleSize: CGFloat = 44
  private let metadataIconSize: CGFloat = 23
  private let sendCircleSize: CGFloat = 44
  private let capsuleRadius: CGFloat = 22
  private let actionRowTopInset: CGFloat = 10
  private let actionRowBottomInset: CGFloat = 10
  private let actionRowHorizontalInset: CGFloat = 14

  init(
    initialProjectId: String? = nil,
    initialSectionId: String? = nil,
    onSaved: @escaping () -> Void,
    onDismiss: @escaping () -> Void
  ) {
    self.initialProjectId = initialProjectId
    self.initialSectionId = initialSectionId
    self.onSaved = onSaved
    self.onDismiss = onDismiss
  }

  var body: some View {
    sheetContent
      .frame(maxWidth: .infinity)
      .background(panelSurface, in: RoundedRectangle(cornerRadius: capsuleRadius, style: .continuous))
      .popoverHostScope(coordinateSpaceName: "quickAddSheet", placement: .quickAddSheet)
      .onAppear {
        DispatchQueue.main.async { titleFocused = true }
      }
      .onChange(of: showDatePicker) { _, isShowing in
        guard !isShowing else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
          titleFocused = true
        }
      }
      .task { await loadPickers() }
      .stackedTaskDatePickerSheet(
        isPresented: $showDatePicker,
        initialDate: dueDate,
        initialTime: dueTime,
        showRecurrence: false
      ) { date, time in
        dueDate = date
        dueTime = time
      }
  }

  // SUBSTITUIDO_FASE1B: overlay custom com scrim + LiquidGlass.sheetPanel + keyboard manual
  // var body: some View {
  //   ZStack(alignment: .bottom) {
  //     Color.black.opacity(0.32).ignoresSafeArea().onTapGesture { onDismiss() }
  //     panel.transition(.move(edge: .bottom).combined(with: .opacity))
  //   }
  //   .ignoresSafeArea(.keyboard)
  //   .observeKeyboardHeight($keyboardHeight)
  //   .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) { titleFocused = true } }
  // }

  // SUBSTITUIDO_FASE8B: layout Todoist — projeto primeiro, ícones planos, painel colado no teclado.
  private var sheetContent: some View {
    let c = theme.colors
    let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

    return VStack(spacing: 0) {
      Capsule()
        .fill(c.textTertiary.opacity(0.35))
        .frame(width: 36, height: 4)
        .padding(.top, 6)
        .padding(.bottom, 18)

      TextField("Nome da tarefa", text: $title)
        .font(.title3.weight(.semibold))
        .foregroundStyle(c.textPrimary)
        .tint(c.accent)
        .focused($titleFocused)
        .submitLabel(.done)
        .padding(.horizontal, 16)
        .padding(.top, 0)
        .padding(.bottom, 6)
        .onSubmit {
          if hasTitle { _Concurrency.Task { await save() } }
        }

      Divider()
        .frame(height: 1)
        .overlay(hairlineColor)

      HStack(spacing: 6) {
        projectChip

        metadataIconButton(
          icon: .tag,
          active: !selectedLabelIds.isEmpty,
          activeColor: labelPillColor
        ) { showLabelsMenu(anchor: $0) }

        metadataIconButton(
          icon: .calendar,
          active: dueDate != nil,
          activeColor: datePillColor
        ) { _ in
          titleFocused = false
          showDatePicker = true
        }

        metadataIconButton(
          icon: .flag,
          active: priority != nil,
          activeColor: priorityColor
        ) { showPriorityMenu(anchor: $0) }

        metadataIconButton(
          icon: .money,
          active: false,
          activeColor: c.accent
        ) { _ in }

        Spacer(minLength: 4)

        sendButton(hasTitle: hasTitle)
      }
      .padding(.horizontal, actionRowHorizontalInset)
      .padding(.top, actionRowTopInset)
      .padding(.bottom, actionRowBottomInset)

      if let error {
        Text(error)
          .font(.system(size: 12))
          .foregroundStyle(AppColors.priorityHigh)
          .padding(.horizontal, 14)
          .padding(.top, 2)
          .padding(.bottom, 2)
      }
    }
  }

  private var panelSurface: Color {
    theme.colors.surface
  }

  private var hairlineColor: Color {
    theme.colors.textTertiary.opacity(0.15)
  }

  private func metadataIconButton(
    icon: StackedIconKey,
    active: Bool,
    activeColor: Color,
    action: @escaping (CGRect) -> Void
  ) -> some View {
    let c = theme.colors
    let iconColor = active ? activeColor : c.textSecondary

    return AnchoredTapButton(action: action) {
      StackedIcons.icon(icon, size: metadataIconSize, color: iconColor)
        .frame(width: iconCircleSize, height: iconCircleSize)
        .background(
          active
            ? activeColor.opacity(0.15)
            : c.surfaceVariant.opacity(0.45)
        )
        .clipShape(Circle())
    }
    .accessibilityLabel(accessibilityLabel(for: icon))
  }

  private func accessibilityLabel(for icon: StackedIconKey) -> String {
    switch icon {
    case .tag: "Etiquetas"
    case .calendar: "Data"
    case .flag: "Prioridade"
    case .money: "Parcelas"
    default: "Metadado"
    }
  }

  private var projectChip: some View {
    let c = theme.colors
    let active = selectedProjectId != nil
    let dot = projects.first(where: { $0.id == selectedProjectId })?.color ?? c.textSecondary
    let name = projectPillLabel

    return AnchoredTapButton { rect in
      showProjectMenu(anchor: rect)
    } label: {
      HStack(spacing: 6) {
        StackedIcons.icon(.navInbox, size: 17, color: active ? dot : c.textSecondary)
        Text(name)
          .font(.system(size: 14.5, weight: .medium))
          .foregroundStyle(active ? dot : c.textSecondary)
          .lineLimit(1)
      }
      .padding(.horizontal, 12)
      .frame(height: iconCircleSize)
      .background(c.surfaceVariant.opacity(active ? 0.55 : 0.35))
      .clipShape(Capsule())
    }
    .accessibilityLabel("Projeto")
  }

  private func sendButton(hasTitle: Bool) -> some View {
    let c = theme.colors
    return Button {
      _Concurrency.Task { await save() }
    } label: {
      Group {
        if saving {
          ProgressView().tint(hasTitle ? c.background : c.textSecondary)
        } else {
          StackedIcons.icon(
            .arrowUp,
            size: 19,
            color: hasTitle ? c.background : c.textSecondary
          )
        }
      }
      .frame(width: sendCircleSize, height: sendCircleSize)
      .background(hasTitle ? c.accent : c.surfaceVariant)
      .clipShape(Circle())
    }
    .buttonStyle(PressableStyle(cornerRadius: sendCircleSize / 2))
    .animation(AppMotion.snappy, value: hasTitle)
    .disabled(!hasTitle || saving)
    .accessibilityLabel("Salvar tarefa")
  }

  // SUBSTITUIDO_FASE8B: fieldBox / metadataPill / projectPillInline / segunda linha de projeto removidos.
  // private func fieldBox<Content: View>(...) { ... }
  // private func metadataPill(...) { ... }
  // private func pillContent(...) { ... }
  // private var projectPillInline: some View { ... }
  // private var projectOnSecondLine: Bool { ... }

  private var projectPillLabel: String {
    guard let id = selectedProjectId,
          let p = projects.first(where: { $0.id == id }) else { return "Entrada" }
    if let sid = selectedSectionId,
       let s = sections.first(where: { $0.id == sid }) {
      return "\(p.name) › \(s.name)"
    }
    return p.name
  }

  private var dueDateLabel: String {
    guard let dueDate else { return "" }
    return TaskMapper.dayLabel(for: dueDate)
  }

  private var priorityLabel: String {
    switch priority {
    case .high: "P1"
    case .medium: "P2"
    case .low: "P3"
    case nil: ""
    }
  }

  private var priorityColor: Color {
    priority?.color ?? theme.colors.textTertiary
  }

  private var datePillColor: Color {
    guard let dueDate else { return theme.colors.textTertiary }
    return TaskMapper.dateColor(for: dueDate)
  }

  private var labelPillName: String? {
    guard selectedLabelIds.count == 1,
          let id = selectedLabelIds.first,
          let label = labels.first(where: { $0.id == id }) else { return nil }
    return label.name
  }

  private var labelPillColor: Color {
    labels.first(where: { selectedLabelIds.contains($0.id) })?.color ?? theme.colors.accent
  }

  private func showPriorityMenu(anchor: CGRect) {
    presentMetadataPopover(anchor: anchor, items: [
      PopoverMenuItem(id: "high", icon: Hugeicons.flag01, label: "Prioridade 1",
                      selected: priority == .high, iconColor: AppColors.priorityHigh),
      PopoverMenuItem(id: "medium", icon: Hugeicons.flag01, label: "Prioridade 2",
                      selected: priority == .medium, iconColor: AppColors.priorityMedium),
      PopoverMenuItem(id: "low", icon: Hugeicons.flag01, label: "Prioridade 3",
                      selected: priority == .low, iconColor: AppColors.priorityLow),
      PopoverMenuItem(id: "none", icon: Hugeicons.flag01, label: "Sem prioridade",
                      selected: priority == nil, iconColor: Color(hex: 0x6B6E76)),
    ]) { result in
      guard let result else { return }
      switch result {
      case "high": priority = .high
      case "medium": priority = .medium
      case "low": priority = .low
      case "none": priority = nil
      default: break
      }
    }
  }

  private func showLabelsMenu(anchor: CGRect) {
    let items = labels.map { label in
      PopoverMenuItem(
        id: label.id,
        icon: Hugeicons.tag01,
        label: label.name,
        selected: selectedLabelIds.contains(label.id),
        iconColor: label.color
      )
    }
    presentMetadataPopover(anchor: anchor, items: items, allowsToggle: true) { result in
      guard let result else { return }
      if selectedLabelIds.contains(result) {
        selectedLabelIds.remove(result)
      } else {
        selectedLabelIds.insert(result)
      }
    }
  }

  private func showProjectMenu(anchor: CGRect) {
    var items: [PopoverMenuItem] = [
      PopoverMenuItem(id: "inbox", icon: Hugeicons.inbox, label: "Inbox",
                      selected: selectedProjectId == nil),
    ]
    for project in projects {
      items.append(PopoverMenuItem(
        id: "project:\(project.id)",
        icon: Hugeicons.folder01,
        label: project.name,
        hasArrow: true,
        selected: selectedProjectId == project.id,
        iconColor: project.color,
        loadChildren: {
          let secs = (try? await SectionRepository.shared.fetchSections(projectId: project.id)) ?? []
          guard !secs.isEmpty else { return nil }
          var sectionItems = [
            PopoverMenuItem(id: "section:\(project.id):", icon: Hugeicons.arrowRight02, label: "Sem seção"),
          ]
          sectionItems += secs.map { s in
            PopoverMenuItem(id: "section:\(project.id):\(s.id)", icon: Hugeicons.arrowRight02, label: s.name)
          }
          return sectionItems
        }
      ))
    }
    presentMetadataPopover(anchor: anchor, items: items) { result in
      guard let result else { return }
      if result == "inbox" {
        selectedProjectId = nil
        selectedSectionId = nil
        sections = []
        return
      }
      if result.hasPrefix("project:") {
        let id = String(result.dropFirst(8))
        selectedProjectId = id
        selectedSectionId = nil
        _Concurrency.Task {
          sections = (try? await SectionRepository.shared.fetchSections(projectId: id)) ?? []
        }
        return
      }
      if result.hasPrefix("section:") {
        let payload = String(result.dropFirst(8))
        let parts = payload.split(separator: ":", maxSplits: 1).map(String.init)
        selectedProjectId = parts.first
        selectedSectionId = parts.count > 1 && !parts[1].isEmpty ? parts[1] : nil
      }
    }
  }

  private func presentMetadataPopover(
    anchor: CGRect,
    items: [PopoverMenuItem],
    allowsToggle: Bool = false,
    onSelect: @escaping (String?) -> Void
  ) {
    presentAnchoredPopover(
      anchorRect: anchor,
      items: items,
      allowsToggle: allowsToggle,
      preferAbove: true,
      onSelect: onSelect
    )
  }

  private func loadPickers() async {
    selectedProjectId = initialProjectId
    selectedSectionId = initialSectionId
    projects = (try? await ProjectRepository.shared.fetchProjects()) ?? []
    labels = (try? await LabelRepository.shared.fetchLabels()) ?? []
    if let pid = initialProjectId {
      sections = (try? await SectionRepository.shared.fetchSections(projectId: pid)) ?? []
    }
  }

  private func save() async {
    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    saving = true
    error = nil

    var dueISO: String?
    var hora: String?
    if let dueDate {
      dueISO = TaskMapper.dateString(dueDate)
      if let dueTime {
        let cal = Calendar.current
        let h = cal.component(.hour, from: dueTime)
        let m = cal.component(.minute, from: dueTime)
        hora = String(format: "%02d:%02d", h, m)
      }
    }

    do {
      _ = try await TaskRepository.shared.createTask(.init(
        title: trimmed,
        description: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
        priority: priority,
        projectId: selectedProjectId,
        sectionId: selectedSectionId,
        dueDateISO: dueISO,
        time: hora,
        labelIds: Array(selectedLabelIds)
      ))
      HapticService.taskCreated()
      onSaved()
      onDismiss()
    } catch {
      self.error = error.localizedDescription
      saving = false
    }
  }
}

private extension String {
  var nilIfEmpty: String? {
    let t = trimmingCharacters(in: .whitespacesAndNewlines)
    return t.isEmpty ? nil : t
  }
}
