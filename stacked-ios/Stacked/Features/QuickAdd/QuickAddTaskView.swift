import SwiftUI
import Hugeicons
import PhotosUI
import UniformTypeIdentifiers

// Paridade lib/screens/quick_add_task_sheet.dart
struct QuickAddTaskView: View {
  @Environment(ThemeManager.self) private var theme

  var initialProjectId: String?
  var initialSectionId: String?
  var onSaved: (QuickAddSaveSummary) -> Void
  var onDismiss: () -> Void

  @FocusState private var titleFocused: Bool
  @AppStorage(ProductivityPreferences.quickAddDescriptionKey) private var showDescriptionField = false
  @State private var title = ""
  @State private var descriptionText = ""
  @State private var priority: Priority?
  @State private var dueDate: Date?
  @State private var dueTime: Date?
  @State private var deadline: Date?
  @State private var selectedProjectId: String?
  @State private var selectedSectionId: String?
  @State private var selectedLabelIds: Set<String> = []
  @State private var projects: [Project] = []
  @State private var sections: [ProjectSection] = []
  @State private var labels: [TaskLabel] = []
  @State private var saving = false
  @State private var error: String?
  @State private var showDatePicker = false
  @State private var showDeadlinePicker = false
  @State private var pendingAttachments: [PendingAttachment] = []
  @State private var photoItems: [PhotosPickerItem] = []
  @State private var showPhotosPicker = false
  @State private var showFileImporter = false

  private struct PendingAttachment: Identifiable {
    let id = UUID()
    let data: Data
    let fileName: String
    let mimeType: String
  }

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
    onSaved: @escaping (QuickAddSaveSummary) -> Void,
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
      .background { KeyboardFloatingPanelStyle.chrome(colors: theme.colors, cornerRadius: capsuleRadius) }
      .popoverHostScope(coordinateSpaceName: "quickAddSheet", placement: .quickAddSheet)
      .onAppear {
        DispatchQueue.main.async { titleFocused = true }
      }
      .onChange(of: showDatePicker) { _, isShowing in
        guard !isShowing else { return }
        DispatchQueue.main.async { titleFocused = true }
      }
      .onChange(of: showDeadlinePicker) { _, isShowing in
        guard !isShowing else { return }
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
      .stackedTaskDatePickerSheet(
        isPresented: $showDeadlinePicker,
        initialDate: deadline,
        showRecurrence: false,
        showsTime: false,
        title: "Prazo"
      ) { date, _ in
        deadline = date
      }
      .onChange(of: photoItems) { _, newItems in
        guard !newItems.isEmpty else { return }
        _Concurrency.Task {
          await ingestPhotos(newItems)
          photoItems = []
        }
      }
      .photosPicker(
        isPresented: $showPhotosPicker,
        selection: $photoItems,
        maxSelectionCount: 5,
        matching: .images
      )
      .fileImporter(
        isPresented: $showFileImporter,
        allowedContentTypes: [.pdf, .image, .jpeg, .png, .webP, .heic],
        allowsMultipleSelection: true
      ) { result in
        switch result {
        case .success(let urls):
          _Concurrency.Task { await ingestFiles(urls) }
        case .failure(let err):
          error = err.localizedDescription
        }
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
      TextField("Nome da tarefa", text: $title)
        .font(.title3.weight(.semibold))
        .foregroundStyle(c.textPrimary)
        .tint(c.accent)
        .focused($titleFocused)
        .submitLabel(.done)
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)

      if showDescriptionField {
        TextField("Adicionar notas...", text: $descriptionText, axis: .vertical)
          .font(AppTypography.commentBody)
          .foregroundStyle(c.textSecondary)
          .tint(c.accent)
          .lineLimit(1...3)
          .padding(.horizontal, 16)
          .padding(.bottom, 6)
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
          icon: .target,
          active: deadline != nil,
          activeColor: deadlinePillColor
        ) { _ in
          titleFocused = false
          showDeadlinePicker = true
        }

        ZStack(alignment: .topTrailing) {
          metadataIconButton(
            icon: .attachment,
            active: !pendingAttachments.isEmpty,
            activeColor: theme.colors.textPrimary
          ) { showAttachmentMenu(anchor: $0) }

          if !pendingAttachments.isEmpty {
            Text("\(pendingAttachments.count)")
              .font(.system(size: 9, weight: .bold))
              .foregroundStyle(theme.colors.background)
              .padding(3)
              .background(theme.colors.accent)
              .clipShape(Circle())
              .offset(x: 2, y: -2)
              .allowsHitTesting(false)
          }
        }

        metadataIconButton(
          icon: .flag,
          active: priority != nil,
          activeColor: priorityColor
        ) { showPriorityMenu(anchor: $0) }

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

  /// Pílulas dos botões — contraste sutil sobre o painel escurecido.
  private func actionPillBackground(colors: AppThemeColors) -> Color {
    KeyboardFloatingPanelStyle.chipBackground(colors)
  }

  private func actionPillBackground(activeColor: Color) -> Color {
    activeColor.opacity(0.15)
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
            ? actionPillBackground(activeColor: activeColor)
            : actionPillBackground(colors: c)
        )
        .clipShape(Circle())
        .overlay {
          if !active {
            Circle()
              .strokeBorder(c.textPrimary.opacity(0.06), lineWidth: 0.6)
          }
        }
    }
    .accessibilityLabel(accessibilityLabel(for: icon))
  }

  private func accessibilityLabel(for icon: StackedIconKey) -> String {
    switch icon {
    case .tag: "Etiquetas"
    case .calendar: "Data"
    case .target: "Prazo"
    case .flag: "Prioridade"
    case .money: "Parcelas"
    default: "Metadado"
    }
  }

  private var projectChip: some View {
    let c = theme.colors
    let active = selectedProjectId != nil
    let tint = projects.first(where: { $0.id == selectedProjectId })?.color ?? c.textSecondary
    let iconColor = active ? tint : c.textSecondary

    return AnchoredTapButton { rect in
      showProjectMenu(anchor: rect)
    } label: {
      StackedIcons.icon(.navInbox, size: metadataIconSize, color: iconColor)
        .frame(width: iconCircleSize, height: iconCircleSize)
        .background(
          active
            ? actionPillBackground(activeColor: tint)
            : actionPillBackground(colors: c)
        )
        .clipShape(Circle())
        .overlay {
          if !active {
            Circle()
              .strokeBorder(c.textPrimary.opacity(0.06), lineWidth: 0.6)
          }
        }
    }
    .accessibilityLabel(active ? "Projeto: \(projectPillLabel)" : "Projeto")
  }

  private func sendButton(hasTitle: Bool) -> some View {
    let c = theme.colors
    return Button {
      _Concurrency.Task { await save() }
    } label: {
      Group {
        if saving {
          // SUBSTITUIDO_TEMAS_JADE: ProgressView().tint(hasTitle ? c.background : c.textSecondary)
          ProgressView().tint(hasTitle ? c.onActionAccent : c.textSecondary)
        } else {
          StackedIcons.icon(
            .arrowUp,
            size: 19,
            // SUBSTITUIDO_TEMAS_JADE: color: hasTitle ? c.background : c.textSecondary
            color: hasTitle ? c.onActionAccent : c.textSecondary
          )
        }
      }
      .frame(width: sendCircleSize, height: sendCircleSize)
      // SUBSTITUIDO_TEMAS_JADE: .background(hasTitle ? c.accent : actionPillBackground(colors: c))
      .background(hasTitle ? c.actionAccent : actionPillBackground(colors: c))
      .clipShape(Circle())
      .overlay {
        if !hasTitle {
          Circle()
            .strokeBorder(c.textPrimary.opacity(0.06), lineWidth: 0.6)
        }
      }
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

  private var deadlinePillColor: Color {
    guard let deadline else { return theme.colors.textTertiary }
    return TaskMapper.deadlineColor(for: deadline)
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
                      selected: priority == nil, iconColor: theme.colors.textTertiary),
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

  private func showAttachmentMenu(anchor: CGRect) {
    presentAttachmentSourceMenu(anchor: anchor) { request in
      switch request {
      case .photo:
        showPhotosPicker = true
      case .file:
        showFileImporter = true
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
    // NET_FASEC_ETAPA2 — caminho otimista (antes: await create + calendário + dismiss).
    // saving = true
    // error = nil
    // do {
    //   guard try await persistTask() != nil else {
    //     saving = false
    //     return
    //   }
    //   HapticService.taskCreated()
    //   onSaved(...)
    //   onDismiss()
    // } catch {
    //   self.error = error.localizedDescription
    //   saving = false
    // }
    let flowStart = Date()
    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }

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
    let deadlineISO = deadline.map { TaskMapper.dateString($0) }

    let input = TaskRepository.CreateTaskInput(
      title: trimmed,
      description: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
      priority: priority,
      projectId: selectedProjectId,
      sectionId: selectedSectionId,
      dueDateISO: dueISO,
      time: hora,
      deadlineISO: deadlineISO,
      labelIds: Array(selectedLabelIds)
    )

    let clientId = UUID().uuidString.lowercased()
    let projectName: String = {
      guard let pid = selectedProjectId,
            let p = projects.first(where: { $0.id == pid }) else { return "Sem projeto" }
      return p.name
    }()
    let taskLabels = labels.filter { selectedLabelIds.contains($0.id) }
    var local = Task(
      id: clientId,
      title: trimmed,
      description: input.description,
      project: projectName,
      projectId: selectedProjectId,
      sectionId: selectedSectionId,
      priority: priority,
      time: hora,
      labels: taskLabels,
      subtasks: [],
      dueDate: dueDate,
      deadline: deadline,
      done: false,
      commentCount: 0,
      recurrence: nil
    )
    TaskMapper.applyDisplayMemos(to: &local)

    TaskStore.shared.insertOptimistic(local)
    HapticService.taskCreated()
    let summary = QuickAddSaveSummary(
      projectId: selectedProjectId,
      dueDateISO: dueISO
    )
    onSaved(summary)
    NetLog.record(
      operation: "quickadd.save.critical_path",
      step: .flowSave,
      durationMs: Int(Date().timeIntervalSince(flowStart) * 1000),
      result: .success,
      detail: "id=\(clientId) dismiss"
    )
    onDismiss()

    let attachmentsToUpload = pendingAttachments
    TaskOptimisticSync.enqueueCreate(id: clientId, input: input, projectName: projectName)
    if !attachmentsToUpload.isEmpty {
      _Concurrency.Task {
        await TaskOptimisticSync.waitUntilReady(taskId: clientId)
        guard !TaskOptimisticSync.isFailed(clientId) else { return }
        for file in attachmentsToUpload {
          _ = try? await AttachmentRepository.shared.upload(
            taskId: clientId,
            data: file.data,
            fileName: file.fileName,
            mimeType: file.mimeType
          )
        }
      }
    }
  }

  private func ingestPhotos(_ items: [PhotosPickerItem]) async {
    for item in items {
      guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
      guard Int64(data.count) <= AttachmentLimits.maxBytes else {
        error = AttachmentError.tooLarge.localizedDescription
        continue
      }
      pendingAttachments.append(
        PendingAttachment(
          data: data,
          fileName: "foto-\(UUID().uuidString.prefix(8)).jpg",
          mimeType: "image/jpeg"
        )
      )
    }
  }

  private func ingestFiles(_ urls: [URL]) async {
    for url in urls {
      let accessed = url.startAccessingSecurityScopedResource()
      defer { if accessed { url.stopAccessingSecurityScopedResource() } }
      guard let data = try? Data(contentsOf: url) else { continue }
      guard Int64(data.count) <= AttachmentLimits.maxBytes else {
        error = AttachmentError.tooLarge.localizedDescription
        continue
      }
      let ext = url.pathExtension.lowercased()
      let mime: String
      if ext == "pdf" {
        mime = "application/pdf"
      } else if ["png"].contains(ext) {
        mime = "image/png"
      } else if ["webp"].contains(ext) {
        mime = "image/webp"
      } else if ["heic", "heif"].contains(ext) {
        mime = "image/heic"
      } else {
        mime = "image/jpeg"
      }
      guard AttachmentLimits.isAllowedMime(mime) else {
        error = AttachmentError.unsupportedType.localizedDescription
        continue
      }
      pendingAttachments.append(
        PendingAttachment(data: data, fileName: url.lastPathComponent, mimeType: mime)
      )
    }
  }
}

private extension String {
  var nilIfEmpty: String? {
    let t = trimmingCharacters(in: .whitespacesAndNewlines)
    return t.isEmpty ? nil : t
  }
}
