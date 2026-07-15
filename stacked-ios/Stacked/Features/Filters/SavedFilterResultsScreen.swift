import SwiftUI
import Hugeicons

/// Drill-down de filtro salvo — dados iniciais locais; store sincroniza após a transição.
struct SavedFilterResultsScreen: View {
  let filter: SavedFilter
  let initialPending: [FilterResultItem]
  let initialCompleted: [FilterResultItem]
  let taskDetailNamespace: Namespace.ID
  var activeZoomTaskId: String? = nil
  let onTaskTap: (String) -> Void
  let onSubtaskTap: (SubtaskDetailRoute) -> Void
  let onEditFilter: (SavedFilter) -> Void

  @Environment(ThemeManager.self) private var theme
  @AppStorage(UIKitTaskListStorage.key) private var useUIKitTaskList = UIKitTaskListStorage.defaultEnabled
  @AppStorage(ProjectDisplayMode.storageKey) private var displayModeRaw = ProjectDisplayMode.defaultRawValue
  @Bindable private var store = FiltersStore.shared
  @AppStorage private var showCompleted: Bool
  @State private var usesStore = false
  @State private var allowRowHeavyWork = false

  private var displayMode: ProjectDisplayMode { ProjectDisplayMode.from(displayModeRaw) }

  init(
    filter: SavedFilter,
    initialPending: [FilterResultItem],
    initialCompleted: [FilterResultItem],
    taskDetailNamespace: Namespace.ID,
    activeZoomTaskId: String? = nil,
    onTaskTap: @escaping (String) -> Void,
    onSubtaskTap: @escaping (SubtaskDetailRoute) -> Void,
    onEditFilter: @escaping (SavedFilter) -> Void
  ) {
    self.filter = filter
    self.initialPending = initialPending
    self.initialCompleted = initialCompleted
    self.taskDetailNamespace = taskDetailNamespace
    self.activeZoomTaskId = activeZoomTaskId
    self.onTaskTap = onTaskTap
    self.onSubtaskTap = onSubtaskTap
    self.onEditFilter = onEditFilter
    _showCompleted = AppStorage(
      wrappedValue: false,
      ShowCompletedPreferences.savedFilterKey(filterId: filter.id)
    )
  }

  private var rowInsets: EdgeInsets {
    displayMode.taskListRowInsets
  }

  private var pendingResults: [FilterResultItem] {
    usesStore ? store.filterResults : initialPending
  }

  private var completedResults: [FilterResultItem] {
    usesStore ? store.filterCompletedResults : initialCompleted
  }

  private var isLoading: Bool {
    usesStore ? store.filterLoading : initialPending.isEmpty && initialCompleted.isEmpty && !store.hasSavedFilterCache(filter.id)
  }

  private var deferHeavyRowWork: Bool {
    !allowRowHeavyWork
  }

  private var prefersUIKitList: Bool {
    useUIKitTaskList
      && !isLoading
      && (!pendingResults.isEmpty || (showCompleted && !completedResults.isEmpty))
  }

  var body: some View {
    let c = theme.colors

    Group {
      if isLoading {
        filterLoadingList
      } else if let err = store.filterError, pendingResults.isEmpty, usesStore {
        filterErrorList(err)
      } else if pendingResults.isEmpty && (!showCompleted || completedResults.isEmpty) {
        filterEmptyList
      } else if prefersUIKitList {
        uikitFilterBody(colors: c)
      } else {
        filterResultsList(colors: c)
      }
    }
    .stackedDrillDownListChrome()
    .background(c.background)
    .stackedDrillDownNavChrome(title: filter.name, background: c.background)
    .stackedDrillDownGlassBackButton()
    .toolbar {
      DrillDownBackToolbarItem()

      ToolbarItem(id: "stacked-filter-toolbar", placement: .topBarTrailing) {
        AnchoredTapButton { rect in
          openOptions(anchor: rect)
        } label: {
          LiquidGlass.toolbarPill(navBarColor: c.surfaceVariant, textPrimary: c.textPrimary) {
            StackedIcons.image(.more)
              .font(.system(size: 16, weight: .medium))
              .foregroundStyle(c.textPrimary)
          }
        }
        .buttonStyle(PressableStyle(cornerRadius: 20))
      }
      .sharedBackgroundVisibility(.hidden)
    }
    .refreshable {
      await store.openSavedFilter(filter)
      await store.loadDashboard()
      usesStore = true
    }
    .task(id: filter.id) {
      await NavigationPushMotion.awaitSettle()
      guard !_Concurrency.Task.isCancelled else { return }
      var transaction = Transaction()
      transaction.disablesAnimations = true
      withTransaction(transaction) {
        allowRowHeavyWork = true
        store.adoptSavedFilterSession(filter, pending: initialPending, completed: initialCompleted)
        usesStore = true
      }
      if initialPending.isEmpty && initialCompleted.isEmpty && !store.hasSavedFilterCache(filter.id) {
        await store.openSavedFilter(filter)
      }
    }
  }

  private var filterLoadingList: some View {
    List {
      TaskListSkeleton(rowCount: 6)
      Section {
        ListTailSpacer()
          .listRowInsets(EdgeInsets())
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
  }

  private func filterErrorList(_ err: String) -> some View {
    List {
      Section {
        LoadErrorView(message: err) { loadFilter() }
          .listRowBackground(Color.clear)
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
  }

  private var filterEmptyList: some View {
    List {
      Section {
        EmptyStateView(icon: .navFilters, title: "Nenhum item", subtitle: "Nada neste filtro por enquanto.")
          .stackedListEmptyStateRow()
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
  }

  @ViewBuilder
  private func filterResultsList(colors: AppThemeColors) -> some View {
    List {
      Section {
        ForEach(pendingResults) { item in
          resultRow(item, canPostpone: true)
        }
      }
      if showCompleted && !completedResults.isEmpty {
        Section {
          Text("Concluídas")
            .font(AppTypography.completedSectionHeader)
            .foregroundStyle(colors.textSecondary)
            .listRowInsets(rowInsets)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
          ForEach(completedResults) { item in
            resultRow(item, canPostpone: false)
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
    .scrollContentBackground(.hidden)
  }

  private var filterUIKitSections: [UIKitTaskSection] {
    var sections: [UIKitTaskSection] = [
      UIKitTaskSection(
        id: "pending",
        header: nil,
        tasks: [],
        filterItems: pendingResults
      ),
    ]
    if showCompleted, !completedResults.isEmpty {
      sections.append(
        UIKitTaskSection(
          id: "completed",
          header: .plain("Concluídas"),
          tasks: [],
          dimmed: true,
          filterItems: completedResults
        )
      )
    }
    return sections
  }

  @ViewBuilder
  private func uikitFilterBody(colors: AppThemeColors) -> some View {
    UIKitHostedTaskList(
      sections: filterUIKitSections,
      showProject: true,
      style: displayMode.taskRowStyle,
      flatSubtaskQueue: displayMode.flatSubtaskPanel,
      rowInsets: rowInsets,
      background: colors.background,
      onToggle: {
        ensureStoreLinked()
        store.complete($0)
      },
      onTap: { onTaskTap($0.id) },
      onSubtaskTap: { task, sub in
        onSubtaskTap(SubtaskDetailRoute(subtask: sub, parentTaskId: task.id))
      },
      onSubtaskChanged: { snapshot in
        ensureStoreLinked()
        store.adoptSavedFilterSession(filter, pending: pendingResults, completed: completedResults)
        store.applySubtaskPatch(snapshot)
      },
      onSubtaskDeleted: { task, sub in
        ensureStoreLinked()
        store.removeSubtask(parentId: task.id, subtask: sub)
        TaskStore.shared.removeSubtask(parentId: task.id, subtask: sub)
      },
      onEdit: { onTaskTap($0.id) },
      onComplete: {
        ensureStoreLinked()
        store.complete($0)
      },
      onDuplicate: { task in
        _Concurrency.Task {
          ensureStoreLinked()
          _ = try? await TaskRepository.shared.duplicateTask(task)
          await store.openSavedFilter(filter)
          await store.loadDashboard()
        }
      },
      onDelete: {
        ensureStoreLinked()
        store.delete($0)
      },
      onRefresh: {
        _Concurrency.Task {
          ensureStoreLinked()
          await store.openSavedFilter(filter)
          await store.loadDashboard()
        }
      },
      onFilterSubtaskToggle: { sub, parent, index in
        ensureStoreLinked()
        store.adoptSavedFilterSession(filter, pending: pendingResults, completed: completedResults)
        store.completeSubtask(parent: parent, sub: sub, at: index)
      },
      onFilterSubtaskTap: { sub, parent in
        onSubtaskTap(SubtaskDetailRoute(subtask: sub, parentTaskId: parent.id))
      },
      labelCatalog: store.pickerLabels
    )
    .stackedScrollEdgeChrome()
  }

  private func loadFilter() {
    usesStore = true
    _Concurrency.Task {
      await store.openSavedFilter(filter)
    }
  }

  private func openOptions(anchor: CGRect) {
    let items: [PopoverMenuItem] = [
      PopoverMenuItem(
        id: "toggle_completed",
        icon: showCompleted ? Hugeicons.eyeOff : Hugeicons.eye,
        label: showCompleted ? "Ocultar concluídas" : "Mostrar concluídas",
        iconColor: theme.colors.textSecondary
      ),
      PopoverMenuItem(id: "edit", icon: Hugeicons.edit01, label: "Editar filtro"),
      PopoverMenuItem(id: "delete", icon: Hugeicons.delete01, label: "Excluir filtro", destructive: true),
    ]
    presentAnchoredPopover(anchorRect: anchor, items: items, alignTrailing: true) { result in
      guard let result else { return }
      switch result {
      case "toggle_completed":
        showCompleted.toggle()
      case "edit":
        onEditFilter(filter)
      case "delete":
        _Concurrency.Task {
          try? await store.deleteSavedFilter(filter)
        }
      default:
        break
      }
    }
  }

  @ViewBuilder
  private func resultRow(_ item: FilterResultItem, canPostpone: Bool) -> some View {
    switch item {
    case .task(let task):
      taskRow(task, canPostpone: canPostpone)
    case .subtask(let sub, let parent, let index):
      FilterSubtaskRow(
        subtask: sub,
        parent: parent,
        labelCatalog: store.pickerLabels,
        onToggle: {
          usesStore = true
          store.adoptSavedFilterSession(filter, pending: pendingResults, completed: completedResults)
          store.completeSubtask(parent: parent, sub: sub, at: index)
        },
        onTap: { onSubtaskTap(SubtaskDetailRoute(subtask: sub, parentTaskId: parent.id)) }
      )
      .id(item.id)
      .listRowInsets(rowInsets)
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
    }
  }

  @ViewBuilder
  private func taskRow(_ task: Task, canPostpone: Bool) -> some View {
    TaskRow(
      task: task,
      style: displayMode.taskRowStyle,
      flatSubtaskPanel: displayMode.flatSubtaskPanel,
      deferHeavyWork: deferHeavyRowWork,
      onToggle: {
        ensureStoreLinked()
        store.complete(task)
      },
      onTap: {
        onTaskTap(task.id)
      },
      onSubtaskTap: { sub in
        onSubtaskTap(SubtaskDetailRoute(subtask: sub, parentTaskId: task.id))
      },
      onSubtaskDeleted: { sub in
        ensureStoreLinked()
        store.removeSubtask(parentId: task.id, subtask: sub)
        TaskStore.shared.removeSubtask(parentId: task.id, subtask: sub)
      }
    )
    .id(task.id)
    .taskDetailZoomSource(id: task.id, namespace: taskDetailNamespace, active: activeZoomTaskId == task.id)
    .taskCompleteRemovalTransition()
    .listRowInsets(rowInsets)
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
    .taskContextMenu(
      task: task,
      onEdit: { onTaskTap(task.id) },
      onComplete: {
        ensureStoreLinked()
        store.complete(task)
      },
      onDuplicate: {
        _Concurrency.Task {
          ensureStoreLinked()
          _ = try? await TaskRepository.shared.duplicateTask(task)
          await store.openSavedFilter(filter)
          await store.loadDashboard()
        }
      },
      onDelete: {
        ensureStoreLinked()
        store.delete(task)
      },
      onRefresh: {
        _Concurrency.Task {
          ensureStoreLinked()
          await store.openSavedFilter(filter)
          await store.loadDashboard()
        }
      }
    )
  }

  private func ensureStoreLinked() {
    guard !usesStore else { return }
    usesStore = true
    store.adoptSavedFilterSession(filter, pending: initialPending, completed: initialCompleted)
  }
}
