import SwiftUI

@MainActor
@Observable
final class SearchStore {
  static let shared = SearchStore()

  private(set) var allTasks: [Task] = []
  private(set) var isLoading = false
  private(set) var error: String?
  var query = ""

  private init() {}

  var results: [Task] {
    let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !q.isEmpty else { return [] }
    return allTasks.filter { task in
      task.title.lowercased().contains(q)
        || (task.description?.lowercased().contains(q) ?? false)
        || task.project.lowercased().contains(q)
        || task.labels.contains { $0.name.lowercased().contains(q) }
    }
  }

  var groupedResults: [(title: String, tasks: [Task])] {
    let today = TaskMapper.startOfDay(Date())
    var todayGroup: [Task] = []
    var upcomingGroup: [Task] = []
    var undatedGroup: [Task] = []

    for task in results {
      guard let due = task.dueDate else {
        undatedGroup.append(task)
        continue
      }
      let day = TaskMapper.startOfDay(due)
      if day <= today { todayGroup.append(task) }
      else { upcomingGroup.append(task) }
    }

    var groups: [(String, [Task])] = []
    if !todayGroup.isEmpty { groups.append(("Hoje", todayGroup)) }
    if !upcomingGroup.isEmpty { groups.append(("Em breve", upcomingGroup)) }
    if !undatedGroup.isEmpty { groups.append(("Sem data", undatedGroup)) }
    return groups
  }

  func applySubtaskPatch(_ snapshot: SubtaskSaveSnapshot) {
    SubtaskListPatch.apply(snapshot, to: &allTasks)
  }

  func load() async {
    isLoading = allTasks.isEmpty
    error = nil
    do {
      allTasks = try await TaskRepository.shared.fetchAllPendingTasks()
    } catch {
      self.error = error.localizedDescription
    }
    isLoading = false
  }

  func complete(_ task: Task) {
    guard let i = allTasks.firstIndex(where: { $0.id == task.id }) else { return }
    guard !allTasks[i].done else { return }

    let originalIndex = i
    let snapshot = allTasks[i]
    let taskId = task.id

    allTasks[i].done = true
    HapticService.taskCompleted()

    TaskCompletionMotion.afterDwell(
      animatedRemoval: { [self] in
        allTasks.removeAll { $0.id == taskId }
      },
      persist: { try await TaskRepository.shared.toggleTaskDone(id: taskId, done: true) },
      rollback: { [self] in
        var restored = snapshot
        restored.done = false
        allTasks.insert(restored, at: min(originalIndex, allTasks.count))
      }
    )
  }

  func delete(_ task: Task) {
    allTasks.removeAll { $0.id == task.id }
    HapticService.taskDeleted()
    _Concurrency.Task {
      try? await TaskRepository.shared.deleteTask(id: task.id)
    }
  }

  func duplicate(_ task: Task) {
    _Concurrency.Task {
      _ = try? await TaskRepository.shared.duplicateTask(task)
      await load()
    }
  }

  func postpone(_ task: Task) async {
    let iso = TaskMapper.postponedDateISO(for: task)
    try? await TaskRepository.shared.updateTaskDate(id: task.id, isoDate: iso)
    allTasks.removeAll { $0.id == task.id }
  }
}

// Paridade lib/screens/search_screen.dart
struct SearchView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme
  @State private var store = SearchStore.shared
  @State private var detailRoute: TaskDetailRoute?
  @State private var subtaskDetailRoute: SubtaskDetailRoute?
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
        } else if store.results.isEmpty {
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
      .task {
        await store.load()
        searchFocused = true
      }
      .fullScreenCover(item: $detailRoute, onDismiss: {
        _Concurrency.Task { await store.load() }
      }) { route in
        TaskDetailZoom.cover(route: route, namespace: taskDetailZoom) {
          TaskDetailView(taskId: route.taskId)
            .environment(ThemeManager.shared)
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
      onToggle: { store.complete(task) },
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
