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
  @Namespace private var taskDetailZoom

  let projectColorHex: String?

  init(projectId: String, projectName: String, projectColorHex: String? = nil) {
    _store = State(initialValue: ProjectDetailStore(projectId: projectId, projectName: projectName))
    self.projectColorHex = projectColorHex
  }

  private var isListMode: Bool { displayMode == "list" }

  var body: some View {
    let c = theme.colors

    List {
      if store.isLoading {
        Section {
          ProgressView()
            .tint(c.accent)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        }
      } else if let err = store.error {
        Section {
          LoadErrorView(message: err) {
            _Concurrency.Task { await store.load() }
          }
          .listRowBackground(Color.clear)
        }
      } else {
        ForEach(store.sections) { section in
          let tasks = store.tasks(in: section.id)
          if !tasks.isEmpty {
            projectSectionBlock(section: section, tasks: tasks)
          }
        }

        let uncategorized = store.tasks(in: nil)
        if !uncategorized.isEmpty {
          projectSectionBlock(
            id: ProjectSectionCollapse.uncategorizedId,
            title: "SEM SEÇÃO",
            tasks: uncategorized,
            showsHeader: !store.sections.isEmpty
          )
        }

        if store.pending.isEmpty && store.completed.isEmpty {
          Section {
            EmptyStateView(icon: .checkCircle, title: "Projeto em dia", subtitle: "Nenhuma tarefa pendente")
            .listRowBackground(Color.clear)
          }
        }

        if showCompleted && !store.completed.isEmpty {
          Section {
            CollapsibleSectionHeader(
              title: "CONCLUÍDAS",
              count: store.completed.count,
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
              ForEach(store.completed) { task in
                completedProjectTaskRow(task)
              }
            }
          }
        }
      }

      Section {
        ListTailSpacer()
          .listRowInsets(EdgeInsets())
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }
    }
    .listStyle(.plain)
    .stackedListTailInset()
    .stackedTabletCentered()
    .scrollContentBackground(.hidden)
    .background(c.background)
    .navigationTitle(store.projectName)
    .navigationBarTitleDisplayMode(.large)
    .navigationBarBackButtonHidden(false)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        HStack(spacing: 6) {
          if isListMode {
            AnchoredTapButton { rect in
              openToolbarMenu(anchor: rect)
            } label: {
              LiquidGlass.toolbarPill(navBarColor: c.surfaceVariant, textPrimary: c.textPrimary) {
                HStack(spacing: 5) {
                  StackedIcons.image(.list)
                    .font(.system(size: 16))
                    .foregroundStyle(c.accent)
                  Text("Lista")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(c.accent)
                }
              }
            }
            .buttonStyle(PressableStyle(cornerRadius: 20))
          }

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
    .refreshable { await store.load() }
    .task { await store.load() }
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
                      selected: displayMode == "cards"),
      PopoverMenuItem(id: "mode_list", icon: Hugeicons.listView, label: "Lista",
                      selected: displayMode == "list"),
      PopoverMenuItem(id: "add_task", icon: Hugeicons.add01, label: "Nova tarefa"),
      PopoverMenuItem(id: "add_section", icon: Hugeicons.add01, label: "Nova seção"),
      PopoverMenuItem(id: "project_options", icon: Hugeicons.settings01, label: "Opções do projeto"),
    ]
  }

  private func handleToolbarAction(_ value: String?) {
    guard let value else { return }
    switch value {
    case "toggle_completed": showCompleted.toggle()
    case "mode_cards": displayMode = "cards"
    case "mode_list": displayMode = "list"
    case "add_task": showQuickAdd = true
    case "add_section": showNewSection = true
    case "project_options": showProjectOptions = true
    default: break
    }
  }

  private var rowInsets: EdgeInsets {
    isListMode
      ? EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
      : EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
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
    TaskRow(
      task: task,
      style: isListMode ? .list : .card,
      showProject: false,
      onToggle: {
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
    .id(task.id)
    .taskDetailZoomSource(id: task.id, namespace: taskDetailZoom)
    .taskCompleteRemovalTransition()
    .listRowInsets(rowInsets)
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
    .taskContextMenu(
      task: task,
      onEdit: { detailRoute = TaskDetailRoute(taskId: task.id) },
      onComplete: { store.complete(task) },
      onDuplicate: { store.duplicate(task) },
      onDelete: { store.delete(task) },
      onRefresh: { _Concurrency.Task { await store.load() } }
    )
    .swipeActions(edge: .leading, allowsFullSwipe: true) {
      Button {
        store.complete(task)
      } label: {
        Label("Concluir", systemImage: "checkmark")
      }
      .tint(AppColors.dateDueToday)
    }
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
      Button {
        HapticService.light()
        _Concurrency.Task { await store.postpone(task) }
      } label: {
        Label("Adiar", systemImage: "clock")
      }
      .tint(AppColors.priorityMedium)

      Button(role: .destructive) {
        HapticService.warning()
        store.delete(task)
      } label: {
        Label("Excluir", systemImage: "trash")
      }
    }
  }

  @ViewBuilder
  private func completedProjectTaskRow(_ task: Task) -> some View {
    TaskRow(
      task: task,
      style: isListMode ? .list : .card,
      showProject: false,
      onToggle: { store.uncomplete(task) },
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
      onComplete: { store.uncomplete(task) },
      onDuplicate: { store.duplicate(task) },
      onDelete: { store.delete(task) },
      onRefresh: { _Concurrency.Task { await store.load() } }
    )
    .swipeActions(edge: .leading, allowsFullSwipe: true) {
      Button {
        store.uncomplete(task)
      } label: {
        Label("Reabrir", systemImage: "arrow.uturn.backward")
      }
      .tint(AppColors.dateDueToday)
    }
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
      Button {
        HapticService.light()
        _Concurrency.Task { await store.postpone(task) }
      } label: {
        Label("Adiar", systemImage: "clock")
      }
      .tint(AppColors.priorityMedium)

      Button(role: .destructive) {
        HapticService.warning()
        store.delete(task)
      } label: {
        Label("Excluir", systemImage: "trash")
      }
    }
  }
}
