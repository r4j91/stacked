import SwiftUI

/// Drill-down de filtro preset — sempre sincroniza via FiltersStore.
struct PresetFilterResultsScreen: View {
  let kind: TaskFilterKind
  let taskDetailNamespace: Namespace.ID
  var activeZoomTaskId: String? = nil
  let onTaskTap: (Task) -> Void
  let onSubtaskTap: (SubtaskDetailRoute) -> Void

  @Environment(ThemeManager.self) private var theme
  @AppStorage(UIKitTaskListStorage.key) private var useUIKitTaskList = UIKitTaskListStorage.defaultEnabled
  @AppStorage(ProjectDisplayMode.storageKey) private var displayModeRaw = ProjectDisplayMode.defaultRawValue
  @Bindable private var store = FiltersStore.shared
  @State private var allowRowHeavyWork = false

  private var displayMode: ProjectDisplayMode { ProjectDisplayMode.from(displayModeRaw) }

  private var rowInsets: EdgeInsets {
    displayMode.taskListRowInsets
  }

  private var results: [FilterResultItem] {
    store.filterResults
  }

  private var isLoading: Bool {
    store.filterLoading
  }

  private var deferHeavyRowWork: Bool {
    !allowRowHeavyWork
  }

  private var prefersUIKitList: Bool {
    useUIKitTaskList && !isLoading && !results.isEmpty
  }

  var body: some View {
    let c = theme.colors

    Group {
      if isLoading {
        presetLoadingList
      } else if let err = store.filterError, results.isEmpty {
        presetErrorList(err)
      } else if results.isEmpty {
        presetEmptyList
      } else if prefersUIKitList {
        uikitPresetBody(colors: c)
      } else {
        presetResultsList(colors: c)
      }
    }
    .stackedDrillDownListChrome()
    .background(c.background)
    .stackedDrillDownNavChrome(title: kind.title, background: c.background)
    .stackedDrillDownGlassBackButton()
    .toolbar {
      DrillDownBackToolbarItem()
    }
    .refreshable {
      await store.openFilter(kind)
      await store.loadDashboard()
    }
    .task(id: kind) {
      await NavigationPushMotion.awaitSettle()
      guard !_Concurrency.Task.isCancelled else { return }
      var transaction = Transaction()
      transaction.disablesAnimations = true
      withTransaction(transaction) {
        allowRowHeavyWork = true
        store.adoptPresetFilterSession(kind)
      }
      await store.openFilter(kind)
    }
  }

  private var presetLoadingList: some View {
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

  private func presetErrorList(_ err: String) -> some View {
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

  private var presetEmptyList: some View {
    List {
      Section {
        EmptyStateView(
          icon: kind.stackedIcon,
          title: "Nenhum item",
          subtitle: "Nada neste filtro por enquanto."
        )
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
  private func presetResultsList(colors: AppThemeColors) -> some View {
    List {
      Section {
        ForEach(results) { item in
          resultRow(item, canPostpone: kind != .completedToday)
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

  @ViewBuilder
  private func uikitPresetBody(colors: AppThemeColors) -> some View {
    UIKitHostedTaskList(
      sections: [
        UIKitTaskSection(
          id: "results",
          header: nil,
          tasks: [],
          filterItems: results
        ),
      ],
      showProject: true,
      style: displayMode.taskRowStyle,
      flatSubtaskQueue: displayMode.flatSubtaskQueue,
      rowInsets: rowInsets,
      background: colors.background,
      onToggle: { store.complete($0) },
      onTap: { onTaskTap($0) },
      onSubtaskTap: { task, sub in
        onSubtaskTap(SubtaskDetailRoute(subtask: sub, parentTaskId: task.id))
      },
      onSubtaskChanged: { store.applySubtaskPatch($0) },
      onSubtaskDeleted: { task, sub in
        store.removeSubtask(parentId: task.id, subtask: sub)
        TaskStore.shared.removeSubtask(parentId: task.id, subtask: sub)
      },
      onEdit: { onTaskTap($0) },
      onComplete: { store.complete($0) },
      onDuplicate: { task in
        _Concurrency.Task {
          _ = try? await TaskRepository.shared.duplicateTask(task)
          await store.openFilter(kind)
          await store.loadDashboard()
        }
      },
      onDelete: { store.delete($0) },
      onRefresh: {
        _Concurrency.Task {
          await store.openFilter(kind)
          await store.loadDashboard()
        }
      },
      onFilterSubtaskToggle: { sub, parent, index in
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
    _Concurrency.Task {
      await store.openFilter(kind)
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
        style: displayMode.taskRowStyle,
        onToggle: {
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
      flatSubtaskQueue: displayMode.flatSubtaskQueue,
      deferHeavyWork: deferHeavyRowWork,
      onToggle: {
        store.complete(task)
      },
      onTap: {
        onTaskTap(task)
      },
      onSubtaskTap: { sub in
        onSubtaskTap(SubtaskDetailRoute(subtask: sub, parentTaskId: task.id))
      },
      onSubtaskDeleted: { sub in
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
      onEdit: { onTaskTap(task) },
      onComplete: {
        store.complete(task)
      },
      onDuplicate: {
        _Concurrency.Task {
          _ = try? await TaskRepository.shared.duplicateTask(task)
          await store.openFilter(kind)
          await store.loadDashboard()
        }
      },
      onDelete: {
        store.delete(task)
      },
      onRefresh: {
        _Concurrency.Task {
          await store.openFilter(kind)
          await store.loadDashboard()
        }
      }
    )
  }
}
