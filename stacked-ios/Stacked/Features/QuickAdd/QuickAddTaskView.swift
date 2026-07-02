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
  @State private var sheetHeight: CGFloat = 300

  private let pillRadius: CGFloat = 22
  private let pillHeight: CGFloat = 44
  private let sendWidth: CGFloat = 64

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
      .reportSheetHeight($sheetHeight)
      .presentationDetents([.height(sheetHeight)])
      .presentationDragIndicator(.visible)
      // SUBSTITUIDO_FASE8A: host local de popover no coordinateSpace "quickAddSheet"
      .popoverHostScope(coordinateSpaceName: "quickAddSheet")
      .onAppear {
        DispatchQueue.main.async { titleFocused = true }
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

  private var sheetContent: some View {
    let c = theme.colors
    let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

    return VStack(spacing: 0) {
        // SUBSTITUIDO_FASE7C: grabber Capsule custom — o sheet usa presentationDragIndicator nativo.
        fieldBox(verticalPadding: 13) {
          TextField("Nome da tarefa", text: $title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(c.textPrimary)
            .tint(c.accent)
            .focused($titleFocused)
            .submitLabel(.done)
            .onSubmit {
              if hasTitle { _Concurrency.Task { await save() } }
            }
        }
        .padding(.horizontal, 16)

        fieldBox(verticalPadding: 11) {
          TextField("Descrição", text: $descriptionText, axis: .vertical)
            .font(.system(size: 14))
            .foregroundStyle(c.textSecondary)
            .tint(c.accent)
            .lineLimit(1...3)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)

        Divider()
          .frame(height: 0.5)
          .overlay(c.textTertiary.opacity(0.15))
          .padding(.top, 14)

        HStack(alignment: .center, spacing: 10) {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
              metadataPill(
                icon: .tag,
                active: !selectedLabelIds.isEmpty,
                activeColor: labelPillColor,
                activeLabel: labelPillName,
                badge: selectedLabelIds.count > 1 ? "\(selectedLabelIds.count)" : nil
              ) { showLabelsMenu(anchor: $0) }

              metadataPill(
                icon: .calendar,
                active: dueDate != nil,
                activeColor: datePillColor,
                activeLabel: dueDate != nil ? dueDateLabel : nil
              ) { _ in
                titleFocused = false
                showDatePicker = true
              }

              metadataPill(
                icon: .flag,
                active: priority != nil,
                activeColor: priorityColor,
                activeLabel: priority != nil ? priorityLabel : nil,
                subtleBg: true
              ) { showPriorityMenu(anchor: $0) }

              metadataPill(
                icon: .money,
                active: false,
                activeColor: c.accent,
                subtleBg: true
              ) { _ in }

              if !projectOnSecondLine {
                projectPillInline
              }
            }
            .padding(.vertical, 2)
          }

          sendButton(hasTitle: hasTitle)
        }
        .padding(.horizontal, 14)
        .padding(.top, 9)
        .padding(.bottom, projectOnSecondLine ? 6 : 9)

        if projectOnSecondLine {
          HStack {
            projectPillInline
            Spacer()
          }
          .padding(.horizontal, 14)
          .padding(.bottom, 9)
        }

        if let error {
          Text(error)
            .font(.system(size: 12))
            .foregroundStyle(AppColors.priorityHigh)
            .padding(.horizontal, 14)
            .padding(.bottom, 4)
        }
    }
  }

  // SUBSTITUIDO_FASE1B: panel com LiquidGlass.sheetPanel + spacers de teclado/safe area
  // private var panel: some View { ... LiquidGlass.sheetPanel ... Color.clear.frame(height: bottomInset) ... }

  private func fieldBox<Content: View>(
    verticalPadding: CGFloat,
    @ViewBuilder content: () -> Content
  ) -> some View {
    let c = theme.colors
    return content()
      .padding(.horizontal, 14)
      .padding(.vertical, verticalPadding)
      .background(c.surfaceVariant.opacity(0.45))
      .clipShape(RoundedRectangle(cornerRadius: PopoverStyle.radius))
      .overlay(
        RoundedRectangle(cornerRadius: PopoverStyle.radius)
          .stroke(c.textPrimary.opacity(0.08), lineWidth: 0.8)
      )
  }

  private func metadataPill(
    icon: StackedIconKey,
    active: Bool,
    activeColor: Color,
    activeLabel: String? = nil,
    badge: String? = nil,
    subtleBg: Bool = false,
    action: @escaping (CGRect) -> Void
  ) -> some View {
    AnchoredTapButton(action: action) {
      pillContent(
        icon: icon,
        active: active,
        activeColor: activeColor,
        activeLabel: activeLabel,
        badge: badge,
        subtleBg: subtleBg
      )
    }
  }

  private func pillContent(
    icon: StackedIconKey,
    active: Bool,
    activeColor: Color,
    activeLabel: String? = nil,
    badge: String? = nil,
    subtleBg: Bool = false
  ) -> some View {
    let c = theme.colors
    let hasText = activeLabel != nil || badge != nil
    let bg = (active && !subtleBg) ? activeColor.opacity(0.12) : c.surfaceVariant.opacity(0.4)
    let iconColor = active ? activeColor : c.textSecondary

    return HStack(spacing: hasText ? 5 : 0) {
      StackedIcons.icon(icon, size: 16, color: iconColor)
      if let activeLabel {
        Text(activeLabel)
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(activeColor)
          .lineLimit(1)
      }
      if let badge {
        Text(badge)
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(activeColor)
      }
    }
    .padding(14)
    .frame(width: hasText ? nil : pillHeight, height: pillHeight)
    .background(bg)
    .clipShape(RoundedRectangle(cornerRadius: pillRadius))
    .overlay(
      RoundedRectangle(cornerRadius: pillRadius)
        .stroke(c.textTertiary.opacity(0.12), lineWidth: 1)
    )
  }

  private var projectPillInline: some View {
    let c = theme.colors
    let active = selectedProjectId != nil
    let dot = projects.first(where: { $0.id == selectedProjectId })?.color ?? c.textPrimary.opacity(0.28)
    let bg = active ? dot.opacity(0.12) : c.surfaceVariant.opacity(0.4)

    return AnchoredTapButton { rect in
      showProjectMenu(anchor: rect)
    } label: {
      HStack(spacing: 6) {
        Circle().fill(dot).frame(width: 7, height: 7)
        Text(projectPillLabel)
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(active ? dot : c.textSecondary)
          .lineLimit(1)
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 14)
      .frame(minHeight: pillHeight)
      .background(bg)
      .clipShape(RoundedRectangle(cornerRadius: pillRadius))
      .overlay(
        RoundedRectangle(cornerRadius: pillRadius)
          .stroke(c.textTertiary.opacity(0.12), lineWidth: 1)
      )
    }
  }

  private var projectOnSecondLine: Bool {
    guard selectedProjectId != nil, selectedSectionId != nil else { return false }
    return projectPillLabel.count > 18
  }

  private func sendButton(hasTitle: Bool) -> some View {
    let c = theme.colors
    return Button {
      _Concurrency.Task { await save() }
    } label: {
      Group {
        if saving {
          ProgressView().tint(c.background)
        } else {
          StackedIcons.icon(.arrowUp, size: 18, color: hasTitle ? c.background : c.background.opacity(0.45))
        }
      }
      .frame(width: sendWidth, height: pillHeight)
      .background(hasTitle ? c.accent : c.accent.opacity(0.28))
      .clipShape(RoundedRectangle(cornerRadius: pillRadius))
    }
    .buttonStyle(PressableStyle(cornerRadius: pillRadius))
    .disabled(!hasTitle || saving)
    .accessibilityLabel("Salvar tarefa")
  }

  private var projectPillLabel: String {
    guard let id = selectedProjectId,
          let p = projects.first(where: { $0.id == id }) else { return "Inbox" }
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
    presentAnchoredPopover(anchorRect: anchor, items: [
      PopoverMenuItem(id: "high", icon: Hugeicons.flag01, label: "Prioridade 1",
                      selected: priority == .high, iconColor: AppColors.priorityHigh),
      PopoverMenuItem(id: "medium", icon: Hugeicons.flag01, label: "Prioridade 2",
                      selected: priority == .medium, iconColor: AppColors.priorityMedium),
      PopoverMenuItem(id: "low", icon: Hugeicons.flag01, label: "Prioridade 3",
                      selected: priority == .low, iconColor: AppColors.priorityLow),
      PopoverMenuItem(id: "none", icon: Hugeicons.flag01, label: "Sem prioridade",
                      selected: priority == nil, iconColor: Color(hex: 0x6B6E76)),
    ], preferAbove: true) { result in
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
    presentAnchoredPopover(anchorRect: anchor, items: items, allowsToggle: true, preferAbove: true) { result in
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
    presentAnchoredPopover(anchorRect: anchor, items: items, preferAbove: true) { result in
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
