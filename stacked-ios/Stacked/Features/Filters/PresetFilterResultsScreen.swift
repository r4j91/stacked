import SwiftUI

/// Drill-down de filtro preset — sempre sincroniza via FiltersStore.
struct PresetFilterResultsScreen: View {
  let kind: TaskFilterKind
  let taskDetailNamespace: Namespace.ID
  let onTaskTap: (String) -> Void
  let onSubtaskTap: (SubtaskDetailRoute) -> Void

  @Environment(ThemeManager.self) private var theme
  @Bindable private var store = FiltersStore.shared
  @State private var allowRowHeavyWork = false

  private let rowInsets = EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)

  private var results: [FilterResultItem] {
    store.filterResults
  }

  private var isLoading: Bool {
    store.filterLoading
  }

  private var deferHeavyRowWork: Bool {
    !allowRowHeavyWork
  }

  var body: some View {
    let c = theme.colors

    List {
      if isLoading {
        TaskListSkeleton(rowCount: 6)
      } else if let err = store.filterError, results.isEmpty {
        Section {
          LoadErrorView(message: err) {
            loadFilter()
          }
          .listRowBackground(Color.clear)
        }
      } else if results.isEmpty {
        Section {
          EmptyStateView(
            icon: kind.stackedIcon,
            title: "Nenhum item",
            subtitle: "Nada neste filtro por enquanto."
          )
          .stackedListEmptyStateRow()
        }
      } else {
        Section {
          ForEach(results) { item in
            resultRow(item, canPostpone: kind != .completedToday)
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
      deferHeavyWork: deferHeavyRowWork,
      onToggle: {
        store.complete(task)
      },
      onTap: {
        onTaskTap(task.id)
      },
      onSubtaskTap: { sub in
        onSubtaskTap(SubtaskDetailRoute(subtask: sub, parentTaskId: task.id))
      }
    )
    .id(task.id)
    .taskDetailZoomSource(id: task.id, namespace: taskDetailNamespace)
    .taskCompleteRemovalTransition()
    .listRowInsets(rowInsets)
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
    .taskContextMenu(
      task: task,
      onEdit: { onTaskTap(task.id) },
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
