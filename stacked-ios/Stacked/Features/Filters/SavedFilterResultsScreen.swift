import SwiftUI
import Hugeicons

/// Drill-down de filtro salvo — dados iniciais locais; store sincroniza após a transição.
struct SavedFilterResultsScreen: View {
  let filter: SavedFilter
  let initialPending: [FilterResultItem]
  let initialCompleted: [FilterResultItem]
  let taskDetailNamespace: Namespace.ID
  let onTaskTap: (String) -> Void
  let onSubtaskTap: (SubtaskDetailRoute) -> Void
  let onEditFilter: (SavedFilter) -> Void

  @Environment(ThemeManager.self) private var theme
  @Bindable private var store = FiltersStore.shared
  @AppStorage("show_completed_tasks") private var showCompleted = false
  @State private var usesStore = false

  private let rowInsets = EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)

  private var pendingResults: [FilterResultItem] {
    usesStore ? store.filterResults : initialPending
  }

  private var completedResults: [FilterResultItem] {
    usesStore ? store.filterCompletedResults : initialCompleted
  }

  private var isLoading: Bool {
    usesStore ? store.filterLoading : initialPending.isEmpty && initialCompleted.isEmpty && !store.hasSavedFilterCache(filter.id)
  }

  var body: some View {
    let c = theme.colors

    List {
      if isLoading {
        Section {
          ProgressView()
            .tint(c.accent)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        }
      } else if let err = store.filterError, pendingResults.isEmpty, usesStore {
        Section {
          LoadErrorView(message: err) {
            loadFilter()
          }
          .listRowBackground(Color.clear)
        }
      } else if pendingResults.isEmpty && (!showCompleted || completedResults.isEmpty) {
        Section {
          EmptyStateView(icon: .navFilters, title: "Nenhum item", subtitle: "Nada neste filtro por enquanto.")
            .listRowBackground(Color.clear)
        }
      } else {
        Section {
          ForEach(pendingResults) { item in
            resultRow(item, canPostpone: true)
          }
        }
        if showCompleted && !completedResults.isEmpty {
          Section {
            Text("Concluídas")
              .font(AppTypography.completedSectionHeader)
              .foregroundStyle(c.textSecondary)
              .listRowInsets(rowInsets)
              .listRowSeparator(.hidden)
              .listRowBackground(Color.clear)
            ForEach(completedResults) { item in
              resultRow(item, canPostpone: false)
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
    .scrollContentBackground(.hidden)
    .stackedListTailInset()
    .stackedTabletCentered()
    .background(c.background)
    .navigationTitle(filter.name)
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
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
    }
    .refreshable {
      await store.openSavedFilter(filter)
      await store.loadDashboard()
      usesStore = true
    }
    .task(id: filter.id) {
      try? await _Concurrency.Task.sleep(for: AppMotion.navigationPushSettle)
      guard !_Concurrency.Task.isCancelled else { return }
      var transaction = Transaction()
      transaction.disablesAnimations = true
      withTransaction(transaction) {
        store.adoptSavedFilterSession(filter, pending: initialPending, completed: initialCompleted)
        usesStore = true
      }
      if !store.hasSavedFilterCache(filter.id) {
        await store.openSavedFilter(filter)
      }
    }
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
    TaskRow(task: task, onToggle: {
      ensureStoreLinked()
      store.complete(task)
    }, onTap: {
      onTaskTap(task.id)
    }, onSubtaskTap: { sub in
      onSubtaskTap(SubtaskDetailRoute(subtask: sub, parentTaskId: task.id))
    })
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
    store.adoptSavedFilterSession(filter, pending: initialPending, completed: initialCompleted)
  }
}
