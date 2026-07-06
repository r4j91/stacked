import SwiftUI

/// Drill-down de filtro preset — snapshot local; store sincroniza após a transição.
struct PresetFilterResultsScreen: View {
  let kind: TaskFilterKind
  let initialTasks: [Task]
  let taskDetailNamespace: Namespace.ID
  let onTaskTap: (String) -> Void
  let onSubtaskTap: (SubtaskDetailRoute) -> Void

  @Environment(ThemeManager.self) private var theme
  @Bindable private var store = FiltersStore.shared
  @State private var usesStore = false
  @State private var allowRowHeavyWork = false

  private let rowInsets = EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)

  private var tasks: [Task] {
    usesStore ? store.filterTasks : initialTasks
  }

  private var isLoading: Bool {
    usesStore ? store.filterLoading : initialTasks.isEmpty && !store.hasPresetFilterCache(kind)
  }

  private var deferHeavyRowWork: Bool {
    !allowRowHeavyWork
  }

  var body: some View {
    let c = theme.colors

    List {
      if isLoading {
        TaskListSkeleton(rowCount: 6)
      } else if let err = store.filterError, tasks.isEmpty, usesStore {
        Section {
          LoadErrorView(message: err) {
            loadFilter()
          }
          .listRowBackground(Color.clear)
        }
      } else if tasks.isEmpty {
        Section {
          EmptyStateView(
            icon: kind.stackedIcon,
            title: "Nenhuma tarefa",
            subtitle: "Nada neste filtro por enquanto."
          )
          .listRowBackground(Color.clear)
        }
      } else {
        Section {
          ForEach(tasks) { task in
            taskRow(task, canPostpone: kind != .completedToday)
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
    .refreshable {
      await store.openFilter(kind)
      await store.loadDashboard()
      usesStore = true
    }
    .task(id: kind) {
      await NavigationPushMotion.awaitSettle()
      guard !_Concurrency.Task.isCancelled else { return }
      var transaction = Transaction()
      transaction.disablesAnimations = true
      withTransaction(transaction) {
        allowRowHeavyWork = true
        store.adoptPresetFilterSession(kind, tasks: initialTasks)
        usesStore = true
      }
      if initialTasks.isEmpty && !store.hasPresetFilterCache(kind) {
        await store.openFilter(kind)
      }
    }
  }

  private func loadFilter() {
    usesStore = true
    _Concurrency.Task {
      await store.openFilter(kind)
    }
  }

  @ViewBuilder
  private func taskRow(_ task: Task, canPostpone: Bool) -> some View {
    TaskRow(
      task: task,
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
        ensureStoreLinked()
        store.complete(task)
      },
      onDuplicate: {
        _Concurrency.Task {
          ensureStoreLinked()
          _ = try? await TaskRepository.shared.duplicateTask(task)
          await store.openFilter(kind)
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
          await store.openFilter(kind)
          await store.loadDashboard()
        }
      }
    )
    .swipeActions(edge: .leading, allowsFullSwipe: true) {
      if !task.done {
        Button {
          ensureStoreLinked()
          store.complete(task)
        } label: {
          Label("Concluir", systemImage: "checkmark")
        }
        .tint(AppColors.dateDueToday)
      }
    }
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
      if canPostpone {
        Button {
          HapticService.light()
          _Concurrency.Task {
            ensureStoreLinked()
            await store.postpone(task)
          }
        } label: {
          Label("Adiar", systemImage: "clock")
        }
        .tint(AppColors.priorityMedium)
      }

      Button(role: .destructive) {
        HapticService.warning()
        ensureStoreLinked()
        store.delete(task)
      } label: {
        Label("Excluir", systemImage: "trash")
      }
    }
  }

  private func ensureStoreLinked() {
    guard !usesStore else { return }
    usesStore = true
    store.adoptPresetFilterSession(kind, tasks: initialTasks)
  }
}
