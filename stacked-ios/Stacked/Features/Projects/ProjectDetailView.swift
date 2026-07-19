import SwiftUI
import Hugeicons

// Paridade lib/screens/project_detail_screen.dart
struct ProjectDetailView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.scenePhase) private var scenePhase

  @AppStorage(ProjectDisplayMode.storageKey) private var displayMode = ProjectDisplayMode.defaultRawValue
  @AppStorage private var showCompleted: Bool
  @AppStorage(UIKitTaskListStorage.key) private var useUIKitTaskList = UIKitTaskListStorage.defaultEnabled
  @AppStorage(TaskRowLayoutStorage.key) private var taskRowLayoutRaw = TaskRowLayoutStorage.defaultRawValue
  /// PERF_FASEB3_3A — T2 desligado do path ativo.
  // @AppStorage(ScrollPerfDebugStorage.t2RowsPlaceholderKey) private var t2RowsPlaceholder = false
  private var t2RowsPlaceholder: Bool { ScrollPerfDebugStorage.t2RowsPlaceholder }
  @State private var store: ProjectDetailStore
  @State private var completedExpanded: Bool
  @State private var detailRoute: TaskDetailRoute?
  @State private var subtaskDetailRoute: SubtaskDetailRoute?
  @State private var whatsAppCopyTask: Task?
  @State private var showQuickAdd = false
  @State private var showProjectOptions = false
  @State private var showNewSection = false
  @State private var newSectionName = ""
  @State private var renameSectionTarget: ProjectSection?
  @State private var renameSectionName = ""
  @State private var deleteSectionTarget: ProjectSection?
  @State private var collapsedSectionIds: Set<String>
  @State private var allowRowHeavyWork = false
  @State private var revealListContent = false
  @State private var editMode: EditMode = .inactive
  @Namespace private var taskDetailZoom

  let projectId: String
  let projectColorHex: String?
  let projectName: String
  let initialSnapshot: ProjectDetailSnapshot

  init(
    projectId: String,
    projectName: String,
    projectColorHex: String? = nil,
    initialSnapshot: ProjectDetailSnapshot? = nil
  ) {
    let snap = initialSnapshot
      ?? ProjectDetailCache.shared.snapshot(for: projectId)
      ?? ProjectDetailSnapshot(sections: [], pending: [], completed: [])
    self.projectId = projectId
    self.projectName = projectName
    self.initialSnapshot = snap
    self.projectColorHex = projectColorHex
    let completedKey = ShowCompletedPreferences.projectKey(projectId: projectId)
    if UserDefaults.standard.object(forKey: completedKey) == nil,
       UserDefaults.standard.bool(forKey: "show_completed_tasks") {
      UserDefaults.standard.set(true, forKey: completedKey)
    }
    _showCompleted = AppStorage(wrappedValue: true, completedKey)
    _completedExpanded = State(
      initialValue: ProjectDetailPreferences.completedExpanded(projectId: projectId)
    )
    _collapsedSectionIds = State(
      initialValue: ProjectDetailPreferences.collapsedSectionIds(projectId: projectId)
    )
    _store = State(
      initialValue: ProjectDetailStore(
        projectId: projectId,
        projectName: projectName,
        initialSnapshot: snap
      )
    )
  }

  private var sections: [ProjectSection] { usesStore ? store.sections : initialSnapshot.sections }
  private var pending: [Task] { usesStore ? store.pending : initialSnapshot.pending }
  private var completed: [Task] { usesStore ? store.completed : initialSnapshot.completed }
  private var isLoading: Bool {
    usesStore
      ? store.isLoading
      : initialSnapshot.pending.isEmpty && initialSnapshot.completed.isEmpty
        && !ProjectDetailCache.shared.hasSnapshot(for: store.projectId)
  }
  private var loadError: String? { usesStore ? store.error : nil }

  @State private var usesStore = false

  private var deferHeavyRowWork: Bool {
    !allowRowHeavyWork
  }

  private var hasLocalContent: Bool {
    !initialSnapshot.pending.isEmpty || !initialSnapshot.completed.isEmpty
  }

  private var displayModeEnum: ProjectDisplayMode { ProjectDisplayMode.from(displayMode) }

  private var taskReorderMode: Bool { editMode == .active }

  /// UIKit só com conteúdo real; ordenar / skeleton / erro ficam no SwiftUI List.
  private var prefersUIKitList: Bool {
    useUIKitTaskList
      && revealListContent
      && !isLoading
      && loadError == nil
      && !taskReorderMode
      && (!pending.isEmpty || (showCompleted && !completed.isEmpty) || !sections.isEmpty)
  }

  var body: some View {
    let c = theme.colors

    Group {
      if prefersUIKitList {
        projectUIKitList
      } else {
        projectSwiftUIList
      }
    }
    .environment(\.editMode, $editMode)
    .onAppear { ScrollHitchProbe.noteScreen("Projeto") }
    .onChange(of: scenePhase) { _, phase in
      guard phase == .active else { return }
      store.refreshRelativeDateChips()
    }
    .background(c.background.ignoresSafeArea(.all))
    .stackedDrillDownNavChrome(title: projectName, background: c.background)
    .stackedDrillDownGlassBackButton()
    .toolbar {
      DrillDownBackToolbarItem()

      ToolbarItem(id: "stacked-project-toolbar", placement: .topBarTrailing) {
        HStack(spacing: 6) {
          if taskReorderMode {
            Button("Concluir") {
              HapticService.selection()
              editMode = .inactive
            }
            .font(AppTypography.body)
            .foregroundStyle(c.accent)
          }

          if !taskReorderMode {
            LiquidGlass.toolbarPill(navBarColor: c.surfaceVariant, textPrimary: c.textPrimary) {
              HStack(spacing: 5) {
                StackedIcons.image(displayModeEnum.menuIcon)
                  .resizable()
                  .scaledToFit()
                  .frame(width: 16, height: 16)
                  .foregroundStyle(c.accent)
                Text(displayModeEnum.label)
                  .font(.system(size: 12, weight: .semibold))
                  .foregroundStyle(c.accent)
              }
            }
            .allowsHitTesting(false)
          }

          if !taskReorderMode {
            AnchoredTapButton { rect in
              openToolbarMenu(anchor: rect)
            } label: {
              LiquidGlass.toolbarPill(navBarColor: c.surfaceVariant, textPrimary: c.textPrimary) {
                StackedIcons.image(.more)
                  .font(.system(size: 16, weight: .medium))
                  .foregroundStyle(c.textPrimary)
              }
            }
            .buttonStyle(PressableStyle(cornerRadius: 20))
          }
        }
      }
      .sharedBackgroundVisibility(.hidden)
    }
    .refreshable { await store.load() }
    .task(id: store.projectId) {
      await NavigationPushMotion.awaitSettle()
      guard !_Concurrency.Task.isCancelled else { return }
      var transaction = Transaction()
      transaction.disablesAnimations = true
      withTransaction(transaction) {
        revealListContent = true
        // Labels/async pesados só após 1º frame da lista (paridade stackedListRowWorkGate).
        allowRowHeavyWork = false
        store.adoptSnapshot(initialSnapshot)
        usesStore = true
      }
      try? await _Concurrency.Task.sleep(for: .milliseconds(150))
      guard !_Concurrency.Task.isCancelled else { return }
      allowRowHeavyWork = true
      if hasLocalContent {
        _Concurrency.Task {
          try? await _Concurrency.Task.sleep(for: .milliseconds(450))
          guard !_Concurrency.Task.isCancelled else { return }
          await store.load()
        }
      } else {
        await store.load()
      }
    }
    .quickAddFloating(
      isPresented: $showQuickAdd,
      initialProjectId: store.projectId,
      onSaved: { _ in _Concurrency.Task { await store.load() } }
    )
    .sheet(item: $subtaskDetailRoute) { route in
      SubtaskDetailView(subtask: route.subtask, parentTaskId: route.parentTaskId) { snapshot in
        guard let snapshot else { return }
        TaskStore.shared.applySubtaskPatch(snapshot)
        store.applySubtaskPatch(snapshot)
      }
      .environment(ThemeManager.shared)
    }
    .sheet(item: $whatsAppCopyTask) { task in
      WhatsAppCopyPreviewSheet(
        taskTitle: task.title,
        message: whatsAppMessage(for: task)
      )
      .environment(ThemeManager.shared)
      .presentationBackground(theme.colors.background)
      .presentationDragIndicator(.visible)
    }
    .sheet(isPresented: $showProjectOptions) {
      ProjectOptionsSheet(
        project: Project(
          id: store.projectId,
          name: store.projectName,
          color: AppColors.parseHex(projectColorHex, fallback: Color(hex: 0x5FD3DC))
        ),
        onEdited: { _Concurrency.Task { await store.load() } },
        onDeleted: { dismiss() }
      )
      .environment(ThemeManager.shared)
      .presentationDetents([.medium, .large])
      .stackedEditableSheetPresentation(background: theme.colors.background)
    }
    .alert("Nova seção", isPresented: $showNewSection) {
      TextField("Nome da seção", text: $newSectionName)
      Button("Criar") {
        let name = newSectionName
        newSectionName = ""
        _Concurrency.Task { await store.createSection(name: name) }
      }
      Button("Cancelar", role: .cancel) { newSectionName = "" }
    }
    .alert("Renomear seção", isPresented: renameSectionAlertPresented) {
      TextField("Nome da seção", text: $renameSectionName)
      Button("Salvar") {
        guard let section = renameSectionTarget else { return }
        let name = renameSectionName
        renameSectionTarget = nil
        renameSectionName = ""
        _Concurrency.Task { await store.renameSection(section, name: name) }
      }
      Button("Cancelar", role: .cancel) {
        renameSectionTarget = nil
        renameSectionName = ""
      }
    }
    .alert(
      "Excluir seção?",
      isPresented: deleteSectionAlertPresented,
      presenting: deleteSectionTarget
    ) { section in
      Button("Excluir", role: .destructive) {
        deleteSectionTarget = nil
        _Concurrency.Task { await store.deleteSection(section) }
      }
      Button("Cancelar", role: .cancel) {
        deleteSectionTarget = nil
      }
    } message: { section in
      Text("As tarefas de \"\(section.name)\" ficarão sem seção.")
    }
    .fullScreenCover(item: $detailRoute, onDismiss: {
      _Concurrency.Task { await store.load() }
    }) { route in
      TaskDetailZoom.cover(route: route, namespace: taskDetailZoom) {
        TaskDetailView(taskId: route.taskId, seed: route.seed)
        .environment(ThemeManager.shared)
      }
    }
  }

  private var renameSectionAlertPresented: Binding<Bool> {
    Binding(
      get: { renameSectionTarget != nil },
      set: { if !$0 { renameSectionTarget = nil; renameSectionName = "" } }
    )
  }

  private var deleteSectionAlertPresented: Binding<Bool> {
    Binding(
      get: { deleteSectionTarget != nil },
      set: { if !$0 { deleteSectionTarget = nil } }
    )
  }

  private func tasks(in sectionId: String?) -> [Task] {
    pending.filter { $0.sectionId == sectionId }
  }

  /// Agrupa pendentes uma vez por body (scroll/section headers).
  private var pendingSectionBuckets: (bySectionId: [String: [Task]], uncategorized: [Task]) {
    var bySectionId: [String: [Task]] = [:]
    var uncategorized: [Task] = []
    bySectionId.reserveCapacity(sections.count)
    for task in pending {
      if let sectionId = task.sectionId, !sectionId.isEmpty {
        bySectionId[sectionId, default: []].append(task)
      } else {
        uncategorized.append(task)
      }
    }
    return (bySectionId, uncategorized)
  }

  private func ensureStoreLinked() {
    guard !usesStore else { return }
    usesStore = true
    store.adoptSnapshot(initialSnapshot)
  }

  private func whatsAppMessage(for task: Task) -> String {
    WhatsAppRoutineMessageBuilder.compose(
      taskTitle: task.title,
      dueDate: task.dueDate,
      description: task.description
    )
  }

  private func openToolbarMenu(anchor: CGRect) {
    presentAnchoredPopover(
      anchorRect: anchor,
      items: toolbarMenuItems,
      alignTrailing: true
    ) { value in
      handleToolbarAction(value)
    }
  }

  private var toolbarMenuItems: [PopoverMenuItem] {
    [
      PopoverMenuItem(
        id: "toggle_completed",
        icon: showCompleted ? Hugeicons.eyeOff : Hugeicons.eye,
        label: showCompleted ? "Ocultar concluídas" : "Mostrar concluídas"
      ),
      PopoverMenuItem(id: "mode_cards", icon: Hugeicons.grid, label: "Balões",
                      selected: displayModeEnum == .cards),
      PopoverMenuItem(id: "mode_cards_refined", icon: Hugeicons.grid, label: "Balões+",
                      selected: displayModeEnum == .cardsRefined),
      PopoverMenuItem(id: "mode_cards_light", icon: Hugeicons.grid, label: "Balões light",
                      selected: displayModeEnum == .cardsLight),
      PopoverMenuItem(id: "mode_list", icon: Hugeicons.listView, label: "Lista",
                      selected: displayModeEnum == .list),
      PopoverMenuItem(id: "mode_list_premium", icon: Hugeicons.listView, label: "Lista premium",
                      selected: displayModeEnum == .listPremium),
      PopoverMenuItem(id: "mode_list_comfort", icon: Hugeicons.listView, label: "Lista+",
                      selected: displayModeEnum == .listComfort),
      PopoverMenuItem(id: "reorder_tasks", icon: Hugeicons.arrowUp01, label: "Ordenar tarefas"),
      PopoverMenuItem(id: "add_task", icon: Hugeicons.add01, label: "Nova tarefa"),
      PopoverMenuItem(id: "add_section", icon: Hugeicons.add01, label: "Nova seção"),
      PopoverMenuItem(id: "project_options", icon: Hugeicons.settings01, label: "Opções do projeto"),
    ]
  }

  private func handleToolbarAction(_ value: String?) {
    guard let value else { return }
    switch value {
    case "toggle_completed": showCompleted.toggle()
    case "mode_cards": displayMode = ProjectDisplayMode.cards.rawValue
    case "mode_cards_refined": displayMode = ProjectDisplayMode.cardsRefined.rawValue
    case "mode_cards_light": displayMode = ProjectDisplayMode.cardsLight.rawValue
    case "mode_list": displayMode = ProjectDisplayMode.list.rawValue
    case "mode_list_premium": displayMode = ProjectDisplayMode.listPremium.rawValue
    case "mode_list_comfort": displayMode = ProjectDisplayMode.listComfort.rawValue
    case "add_task": showQuickAdd = true
    case "add_section": showNewSection = true
    case "project_options": showProjectOptions = true
    case "reorder_tasks": enterTaskReorderMode()
    default: break
    }
  }

  private func enterTaskReorderMode() {
    guard !pending.isEmpty else { return }
    ensureStoreLinked()
    collapsedSectionIds.removeAll()
    HapticService.selection()
    editMode = .active
  }

  private func moveTasks(in sectionId: String?, from source: IndexSet, to destination: Int) {
    ensureStoreLinked()
    store.moveTasks(in: sectionId, from: source, to: destination)
  }

  private var rowInsets: EdgeInsets {
    displayModeEnum.taskListRowInsets
  }

  private var projectUIKitList: some View {
    let c = theme.colors
    let mode = displayModeEnum
    return UIKitHostedTaskList(
      sections: projectUIKitSections,
      showProject: false,
      style: mode.taskRowStyle,
      flatSubtaskQueue: mode.flatSubtaskQueue,
      rowInsets: rowInsets,
      background: c.background,
      onToggleSection: handleUIKitSectionToggle,
      onRenameSection: { section in
        renameSectionTarget = section
        renameSectionName = section.name
      },
      onDeleteSection: { section in
        deleteSectionTarget = section
      },
      onToggle: toggleProjectTask,
      onTap: { detailRoute = TaskDetailRoute(task: $0) },
      onSubtaskTap: { task, sub in
        subtaskDetailRoute = SubtaskDetailRoute(subtask: sub, parentTaskId: task.id)
      },
      onSubtaskChanged: { store.applySubtaskPatch($0) },
      onSubtaskDeleted: { task, sub in
        store.removeSubtask(parentId: task.id, subtask: sub)
        TaskStore.shared.removeSubtask(parentId: task.id, subtask: sub)
      },
      onEdit: { detailRoute = TaskDetailRoute(task: $0) },
      onComplete: toggleProjectTask,
      onDuplicate: { task in
        ensureStoreLinked()
        store.duplicate(task)
      },
      onDelete: { task in
        ensureStoreLinked()
        store.delete(task)
      },
      onRefresh: {
        ensureStoreLinked()
        _Concurrency.Task { await store.load() }
      },
      onWhatsAppCopy: { whatsAppCopyTask = $0 }
    )
    // Remonta o host UIKit ao trocar Balões/Lista ou layout dos cards —
    // senão o diffable reusa cells com o estilo/layout antigo até sair/voltar.
    .id("\(displayMode)-\(taskRowLayoutRaw)")
    // Full-bleed embaixo — sem faixa preta do safe area atrás do dock.
    .ignoresSafeArea(edges: .bottom)
    .stackedScrollEdgeChrome()
  }

  private func handleUIKitSectionToggle(_ id: String) {
    if id == "completed" {
      AppMotion.animate(AppMotion.snappy, reduceMotion: reduceMotion) {
        completedExpanded.toggle()
        ProjectDetailPreferences.setCompletedExpanded(completedExpanded, projectId: projectId)
      }
    } else {
      toggleSection(id)
    }
  }

  private func toggleProjectTask(_ task: Task) {
    ensureStoreLinked()
    if task.done { store.uncomplete(task) } else { store.complete(task) }
  }

  private var projectUIKitSections: [UIKitTaskSection] {
    let buckets = pendingSectionBuckets
    var result: [UIKitTaskSection] = []

    for section in sections {
      let tasks = buckets.bySectionId[section.id] ?? []
      let expanded = isSectionExpanded(section.id)
      result.append(
        UIKitTaskSection(
          id: section.id,
          header: .collapsible(
            title: section.name.uppercased(),
            count: tasks.count,
            expanded: expanded
          ),
          tasks: tasks,
          projectSection: section
        )
      )
    }

    if !buckets.uncategorized.isEmpty {
      let id = ProjectSectionCollapse.uncategorizedId
      let showHeader = !sections.isEmpty
      if showHeader {
        result.append(
          UIKitTaskSection(
            id: id,
            header: .collapsible(
              title: "SEM SEÇÃO",
              count: buckets.uncategorized.count,
              expanded: isSectionExpanded(id)
            ),
            tasks: buckets.uncategorized
          )
        )
      } else {
        result.append(
          UIKitTaskSection(id: id, title: nil, tasks: buckets.uncategorized)
        )
      }
    }

    if showCompleted && !completed.isEmpty {
      result.append(
        UIKitTaskSection(
          id: "completed",
          header: .collapsible(
            title: "CONCLUÍDAS",
            count: completed.count,
            expanded: completedExpanded
          ),
          tasks: completed,
          dimmed: true
        )
      )
    }

    return result
  }

  @ViewBuilder
  private var projectSwiftUIList: some View {
    List {
      if revealListContent {
        if isLoading {
          TaskListSkeleton(rowCount: 6)
        } else if let err = loadError {
          Section {
            LoadErrorView(message: err) {
              _Concurrency.Task { await store.load() }
            }
            .listRowBackground(Color.clear)
          }
        } else {
          let buckets = pendingSectionBuckets
          ForEach(sections) { section in
            projectSectionBlock(
              section: section,
              tasks: buckets.bySectionId[section.id] ?? []
            )
          }

          if !buckets.uncategorized.isEmpty {
            projectSectionBlock(
              id: ProjectSectionCollapse.uncategorizedId,
              title: "SEM SEÇÃO",
              tasks: buckets.uncategorized,
              showsHeader: !sections.isEmpty
            )
          }

          if pending.isEmpty && completed.isEmpty && sections.isEmpty {
            Section {
              EmptyStateView(icon: .checkCircle, title: "Projeto em dia", subtitle: "Nenhuma tarefa pendente")
              .stackedListEmptyStateRow()
            }
          }

          if showCompleted && !completed.isEmpty {
            Section {
              CollapsibleSectionHeader(
                title: "CONCLUÍDAS",
                count: completed.count,
                expanded: completedExpanded,
                onToggle: {
                  AppMotion.animate(AppMotion.snappy, reduceMotion: reduceMotion) {
                    completedExpanded.toggle()
                    ProjectDetailPreferences.setCompletedExpanded(
                      completedExpanded,
                      projectId: projectId
                    )
                  }
                }
              )
              .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 0, trailing: 16))
              .listRowSeparator(.hidden)
              .listRowBackground(Color.clear)

              if completedExpanded {
                ForEach(completed) { task in
                  completedProjectTaskRow(task)
                }
              }
            }
          }
        }
      } else {
        TaskListSkeleton(rowCount: 6)
      }

      Section {
        ListTailSpacer()
          .listRowInsets(EdgeInsets())
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .stackedDrillDownListChrome()
  }

  private func isSectionExpanded(_ id: String) -> Bool {
    !collapsedSectionIds.contains(id)
  }

  private func toggleSection(_ id: String) {
    AppMotion.animate(AppMotion.subtaskChevronTurnSpring, reduceMotion: reduceMotion) {
      if collapsedSectionIds.contains(id) {
        collapsedSectionIds.remove(id)
      } else {
        collapsedSectionIds.insert(id)
      }
    }
    ProjectDetailPreferences.setCollapsedSectionIds(collapsedSectionIds, projectId: projectId)
  }

  @ViewBuilder
  private func projectSectionBlock(
    section: ProjectSection,
    tasks: [Task]
  ) -> some View {
    CollapsibleSectionHeader(
      title: section.name.uppercased(),
      count: tasks.count,
      expanded: isSectionExpanded(section.id),
      onToggle: { toggleSection(section.id) },
      section: section,
      onRename: { section in
        renameSectionTarget = section
        renameSectionName = section.name
      },
      onDelete: { section in
        deleteSectionTarget = section
      }
    )
    .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 0, trailing: 8))
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)

    if isSectionExpanded(section.id) {
      if taskReorderMode {
        ForEach(tasks) { task in
          projectTaskRow(task)
        }
        .onMove { source, destination in
          moveTasks(in: section.id, from: source, to: destination)
        }
      } else {
        ForEach(tasks) { task in
          projectTaskRow(task)
        }
      }
    }
  }

  @ViewBuilder
  private func projectSectionBlock(
    id: String,
    title: String,
    tasks: [Task],
    showsHeader: Bool = true
  ) -> some View {
    if showsHeader {
      CollapsibleSectionHeader(
        title: title,
        count: tasks.count,
        expanded: isSectionExpanded(id),
        onToggle: { toggleSection(id) }
      )
      .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 0, trailing: 16))
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
    }

    if !showsHeader || isSectionExpanded(id) {
      if taskReorderMode {
        ForEach(tasks) { task in
          projectTaskRow(task)
        }
        .onMove { source, destination in
          moveTasks(in: nil, from: source, to: destination)
        }
      } else {
        ForEach(tasks) { task in
          projectTaskRow(task)
        }
      }
    }
  }

  @ViewBuilder
  private func projectTaskRow(_ task: Task) -> some View {
    // PERF_FASEB3_ETAPA2 T2 — sem menu/zoom no placeholder.
    if t2RowsPlaceholder {
      projectTaskRowBody(task)
        .id(task.id)
        .listRowInsets(rowInsets)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    } else if taskReorderMode {
      projectTaskRowBody(task)
        .id(task.id)
        .taskDetailZoomSource(id: task.id, namespace: taskDetailZoom, active: detailRoute?.taskId == task.id)
        .taskCompleteRemovalTransition()
        .listRowInsets(rowInsets)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    } else {
      projectTaskRowBody(task)
        .id(task.id)
        .taskDetailZoomSource(id: task.id, namespace: taskDetailZoom, active: detailRoute?.taskId == task.id)
        .taskCompleteRemovalTransition()
        .listRowInsets(rowInsets)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .taskContextMenu(
          task: task,
          onEdit: { detailRoute = TaskDetailRoute(task: task) },
          onComplete: {
            ensureStoreLinked()
            store.complete(task)
          },
          onDuplicate: {
            ensureStoreLinked()
            store.duplicate(task)
          },
          onDelete: {
            ensureStoreLinked()
            store.delete(task)
          },
          onRefresh: {
            ensureStoreLinked()
            _Concurrency.Task { await store.load() }
          }
        )
    }
  }

  @ViewBuilder
  private func projectTaskRowBody(_ task: Task) -> some View {
    let mode = displayModeEnum
    // PERF_FASEB3_ETAPA2 T2
    if t2RowsPlaceholder {
      TaskRowScrollPlaceholder(
        task: task,
        showProject: false,
        style: mode.taskRowStyle
      )
    } else {
      TaskRow(
        task: task,
        style: mode.taskRowStyle,
        flatSubtaskQueue: mode.flatSubtaskQueue,
        showProject: false,
        deferHeavyWork: deferHeavyRowWork,
        rowInteractionsEnabled: !taskReorderMode,
        onToggle: {
          ensureStoreLinked()
          store.complete(task)
        },
        onTap: taskReorderMode ? nil : {
          detailRoute = TaskDetailRoute(task: task)
        },
        onSubtaskTap: { sub in
          subtaskDetailRoute = SubtaskDetailRoute(subtask: sub, parentTaskId: task.id)
        },
        onSubtaskChanged: { snapshot in
          store.applySubtaskPatch(snapshot)
        },
        onSubtaskDeleted: { sub in
          store.removeSubtask(parentId: task.id, subtask: sub)
          TaskStore.shared.removeSubtask(parentId: task.id, subtask: sub)
        },
        onWhatsAppCopy: {
          whatsAppCopyTask = task
        }
      )
    }
  }

  @ViewBuilder
  private func completedProjectTaskRow(_ task: Task) -> some View {
    let mode = displayModeEnum
    TaskRow(
      task: task,
      style: mode.taskRowStyle,
      flatSubtaskQueue: mode.flatSubtaskQueue,
      showProject: false,
      deferHeavyWork: deferHeavyRowWork,
      onToggle: {
        ensureStoreLinked()
        store.uncomplete(task)
      },
      onTap: { detailRoute = TaskDetailRoute(task: task) },
      onSubtaskTap: { sub in
        subtaskDetailRoute = SubtaskDetailRoute(subtask: sub, parentTaskId: task.id)
      },
      onSubtaskChanged: { snapshot in
        store.applySubtaskPatch(snapshot)
      },
      onSubtaskDeleted: { sub in
        store.removeSubtask(parentId: task.id, subtask: sub)
        TaskStore.shared.removeSubtask(parentId: task.id, subtask: sub)
      },
      onWhatsAppCopy: {
        whatsAppCopyTask = task
      }
    )
    .id(task.id)
    .taskDetailZoomSource(id: task.id, namespace: taskDetailZoom, active: detailRoute?.taskId == task.id)
    .opacity(0.7)
    .listRowInsets(rowInsets)
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
    .taskContextMenu(
      task: task,
      onEdit: { detailRoute = TaskDetailRoute(task: task) },
      onComplete: {
        ensureStoreLinked()
        store.uncomplete(task)
      },
      onDuplicate: {
        ensureStoreLinked()
        store.duplicate(task)
      },
      onDelete: {
        ensureStoreLinked()
        store.delete(task)
      },
      onRefresh: {
        ensureStoreLinked()
        _Concurrency.Task { await store.load() }
      }
    )
  }
}
