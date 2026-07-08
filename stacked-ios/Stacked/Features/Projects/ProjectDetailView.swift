import SwiftUI
import Hugeicons

// Paridade lib/screens/project_detail_screen.dart
struct ProjectDetailView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @AppStorage("display_mode") private var displayMode = "cards"
  @AppStorage("show_completed_tasks") private var showCompleted = false
  @State private var store: ProjectDetailStore
  @State private var completedExpanded = false
  @State private var detailRoute: TaskDetailRoute?
  @State private var subtaskDetailRoute: SubtaskDetailRoute?
  @State private var showQuickAdd = false
  @State private var showProjectOptions = false
  @State private var showNewSection = false
  @State private var newSectionName = ""
  @State private var renameSectionTarget: ProjectSection?
  @State private var renameSectionName = ""
  @State private var deleteSectionTarget: ProjectSection?
  @State private var collapsedSectionIds: Set<String> = []
  @State private var allowRowHeavyWork = false
  @State private var revealListContent = false
  @Namespace private var taskDetailZoom

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
    self.projectName = projectName
    self.initialSnapshot = snap
    self.projectColorHex = projectColorHex
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

  var body: some View {
    let c = theme.colors

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
          ForEach(sections) { section in
            projectSectionBlock(section: section, tasks: tasks(in: section.id))
          }

          let uncategorized = tasks(in: nil)
          if !uncategorized.isEmpty {
            projectSectionBlock(
              id: ProjectSectionCollapse.uncategorizedId,
              title: "SEM SEÇÃO",
              tasks: uncategorized,
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
    .background(c.background)
    .stackedDrillDownNavChrome(title: projectName, background: c.background)
    .stackedDrillDownGlassBackButton()
    .toolbar {
      DrillDownBackToolbarItem()

      ToolbarItem(id: "stacked-project-toolbar", placement: .topBarTrailing) {
        HStack(spacing: 6) {
          AnchoredTapButton { rect in
            openToolbarMenu(anchor: rect)
          } label: {
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
          }
          .buttonStyle(PressableStyle(cornerRadius: 20))

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
        allowRowHeavyWork = true
        store.adoptSnapshot(initialSnapshot)
        usesStore = true
      }
      if hasLocalContent {
        _Concurrency.Task {
          try? await _Concurrency.Task.sleep(for: .milliseconds(600))
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
      onSaved: { _Concurrency.Task { await store.load() } }
    )
    .sheet(item: $subtaskDetailRoute) { route in
      SubtaskDetailView(subtask: route.subtask, parentTaskId: route.parentTaskId) { snapshot in
        await SubtaskSaveHandler.handle(snapshot, patch: store.applySubtaskPatch) { await store.load() }
      }
      .environment(ThemeManager.shared)
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
      .presentationDragIndicator(.visible)
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
        TaskDetailView(taskId: route.taskId)
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

  private func ensureStoreLinked() {
    guard !usesStore else { return }
    usesStore = true
    store.adoptSnapshot(initialSnapshot)
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
      PopoverMenuItem(id: "mode_list", icon: Hugeicons.listView, label: "Lista",
                      selected: displayModeEnum == .list),
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
    case "mode_list": displayMode = ProjectDisplayMode.list.rawValue
    case "add_task": showQuickAdd = true
    case "add_section": showNewSection = true
    case "project_options": showProjectOptions = true
    default: break
    }
  }

  private var rowInsets: EdgeInsets {
    displayModeEnum.usesCardStyle
      ? EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
      : EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
  }

  private func isSectionExpanded(_ id: String) -> Bool {
    !collapsedSectionIds.contains(id)
  }

  private func toggleSection(_ id: String) {
    if collapsedSectionIds.contains(id) {
      collapsedSectionIds.remove(id)
    } else {
      collapsedSectionIds.insert(id)
    }
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
      ForEach(tasks) { task in
        projectTaskRow(task)
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
      ForEach(tasks) { task in
        projectTaskRow(task)
      }
    }
  }

  @ViewBuilder
  private func projectTaskRow(_ task: Task) -> some View {
    projectTaskRowBody(task)
      .id(task.id)
      .taskDetailZoomSource(id: task.id, namespace: taskDetailZoom)
      .taskCompleteRemovalTransition()
      .listRowInsets(rowInsets)
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
      .taskContextMenu(
        task: task,
        onEdit: { detailRoute = TaskDetailRoute(taskId: task.id) },
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
      .swipeActions(edge: .leading, allowsFullSwipe: true) {
        Button {
          ensureStoreLinked()
          store.complete(task)
        } label: {
          Label("Concluir", systemImage: "checkmark")
        }
        .tint(AppColors.dateDueToday)
      }
      .swipeActions(edge: .trailing, allowsFullSwipe: false) {
        Button {
          HapticService.light()
          ensureStoreLinked()
          _Concurrency.Task { await store.postpone(task) }
        } label: {
          Label("Adiar", systemImage: "clock")
        }
        .tint(AppColors.priorityMedium)

        Button(role: .destructive) {
          HapticService.warning()
          ensureStoreLinked()
          store.delete(task)
        } label: {
          Label("Excluir", systemImage: "trash")
        }
      }
  }

  @ViewBuilder
  private func projectTaskRowBody(_ task: Task) -> some View {
    let mode = displayModeEnum
    TaskRow(
      task: task,
      style: mode.usesCardStyle ? .card : .list,
      flatSubtaskPanel: mode.flatSubtaskPanel,
      showProject: false,
      deferHeavyWork: deferHeavyRowWork,
      onToggle: {
        ensureStoreLinked()
        store.complete(task)
      },
      onTap: {
        detailRoute = TaskDetailRoute(taskId: task.id)
      },
      onSubtaskTap: { sub in
        subtaskDetailRoute = SubtaskDetailRoute(subtask: sub, parentTaskId: task.id)
      },
      onSubtaskChanged: {
        _Concurrency.Task { await store.load() }
      }
    )
  }

  @ViewBuilder
  private func completedProjectTaskRow(_ task: Task) -> some View {
    let mode = displayModeEnum
    TaskRow(
      task: task,
      style: mode.usesCardStyle ? .card : .list,
      flatSubtaskPanel: mode.flatSubtaskPanel,
      showProject: false,
      deferHeavyWork: deferHeavyRowWork,
      onToggle: {
        ensureStoreLinked()
        store.uncomplete(task)
      },
      onTap: { detailRoute = TaskDetailRoute(taskId: task.id) },
      onSubtaskTap: { sub in
        subtaskDetailRoute = SubtaskDetailRoute(subtask: sub, parentTaskId: task.id)
      },
      onSubtaskChanged: {
        _Concurrency.Task { await store.load() }
      }
    )
    .id(task.id)
    .taskDetailZoomSource(id: task.id, namespace: taskDetailZoom)
    .opacity(0.7)
    .listRowInsets(rowInsets)
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
    .taskContextMenu(
      task: task,
      onEdit: { detailRoute = TaskDetailRoute(taskId: task.id) },
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
    .swipeActions(edge: .leading, allowsFullSwipe: true) {
      Button {
        ensureStoreLinked()
        store.uncomplete(task)
      } label: {
        Label("Reabrir", systemImage: "arrow.uturn.backward")
      }
      .tint(AppColors.dateDueToday)
    }
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
      Button {
        HapticService.light()
        ensureStoreLinked()
        _Concurrency.Task { await store.postpone(task) }
      } label: {
        Label("Adiar", systemImage: "clock")
      }
      .tint(AppColors.priorityMedium)

      Button(role: .destructive) {
        HapticService.warning()
        ensureStoreLinked()
        store.delete(task)
      } label: {
        Label("Excluir", systemImage: "trash")
      }
    }
  }
}
