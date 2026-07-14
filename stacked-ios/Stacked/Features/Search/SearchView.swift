import SwiftUI

// Paridade lib/screens/search_screen.dart
struct SearchView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme
  @State private var store = SearchStore.shared
  @State private var allowRowHeavyWork = false
  @State private var detailRoute: TaskDetailRoute?
  @State private var subtaskDetailRoute: SubtaskDetailRoute?
  @State private var dismissedTaskId: String?
  @State private var labelCatalog: [TaskLabel] = []
  @FocusState private var searchFocused: Bool
  @Namespace private var taskDetailZoom

  var body: some View {
    let c = theme.colors

    NavigationStack {
      Group {
        if store.isLoading {
          ProgressView().tint(c.accent)
        } else if let err = store.error, store.allTasks.isEmpty {
          LoadErrorView(message: err) {
            _Concurrency.Task { await store.load() }
          }
        } else if store.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
              .font(.system(size: 36))
              .foregroundStyle(c.textTertiary)
            Text("Buscar tarefas")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(c.textSecondary)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if store.groupedResults.isEmpty {
          EmptyStateView(icon: .search, title: "Nenhum resultado", subtitle: "Tente outro termo de busca")
            .stackedStandaloneEmptyState()
        } else {
          List {
            ForEach(store.groupedResults, id: \.title) { group in
              Section {
                ForEach(group.tasks) { task in
                  searchTaskRow(task)
                }
              } header: {
                ListSectionHeader(text: group.title.uppercased())
              }
            }
          }
          .listStyle(.plain)
          .scrollContentBackground(.hidden)
          .stackedScrollEdgeChrome()
        }
      }
      .stackedTabletCentered()
      .background(c.background)
      .navigationTitle("Buscar")
      .navigationBarTitleDisplayMode(.inline)
      .searchable(text: $store.query, prompt: "Título, projeto ou etiqueta")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancelar") { dismiss() }
            .foregroundStyle(c.accent)
        }
      }
      .stackedListRowWorkGate($allowRowHeavyWork)
      .task {
        await NavigationPushMotion.awaitSettle()
        guard !_Concurrency.Task.isCancelled else { return }
        async let loadReq: Void = store.load()
        async let labelsReq: [TaskLabel] = LabelCatalogCache.labels()
        _ = await loadReq
        labelCatalog = await labelsReq
        searchFocused = true
      }
      .fullScreenCover(item: $detailRoute, onDismiss: {
        let taskId = dismissedTaskId
        dismissedTaskId = nil
        _Concurrency.Task {
          if let taskId {
            await store.syncTask(taskId)
          }
        }
      }) { route in
        TaskDetailZoom.cover(route: route, namespace: taskDetailZoom) {
          TaskDetailView(taskId: route.taskId)
            .environment(ThemeManager.shared)
            .onAppear { dismissedTaskId = route.taskId }
        }
      }
      .sheet(item: $subtaskDetailRoute) { route in
        SubtaskDetailView(subtask: route.subtask, parentTaskId: route.parentTaskId) { snapshot in
          await SubtaskSaveHandler.handle(snapshot, patch: store.applySubtaskPatch) { await store.load() }
        }
        .environment(ThemeManager.shared)
      }
    }
  }

  private var rowInsets: EdgeInsets {
    EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
  }

  @ViewBuilder
  private func searchTaskRow(_ task: Task) -> some View {
    TaskRow(
      task: task,
      allLabels: labelCatalog,
      deferHeavyWork: !allowRowHeavyWork,
      onToggle: { store.complete(task) },
      onTap: {
        dismissedTaskId = task.id
        detailRoute = TaskDetailRoute(taskId: task.id)
      },
      onSubtaskTap: { sub in
        subtaskDetailRoute = SubtaskDetailRoute(subtask: sub, parentTaskId: task.id)
      },
      onSubtaskChanged: { snapshot in
        store.applySubtaskPatch(snapshot)
      },
      onSubtaskDeleted: { sub in
        store.removeSubtask(parentId: task.id, subtask: sub)
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
  }
}
