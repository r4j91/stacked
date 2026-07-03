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
}

// Paridade lib/screens/search_screen.dart
struct SearchView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(ThemeManager.self) private var theme
  @State private var store = SearchStore.shared
  @State private var detailRoute: TaskDetailRoute?
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
        } else {
          List {
            ForEach(store.groupedResults, id: \.title) { group in
              Section {
                ForEach(group.tasks) { task in
                  TaskRow(task: task, onToggle: { }, onTap: {
                    detailRoute = TaskDetailRoute(taskId: task.id)
                  })
                  .taskDetailZoomSource(id: task.id, namespace: taskDetailZoom)
                  .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                  .listRowSeparator(.hidden)
                  .listRowBackground(Color.clear)
                }
              } header: {
                ListSectionHeader(text: group.title.uppercased())
              }
            }
          }
          .listStyle(.plain)
          .scrollContentBackground(.hidden)
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
      .fullScreenCover(item: $detailRoute) { route in
        TaskDetailZoom.cover(route: route, namespace: taskDetailZoom) {
          TaskDetailView(taskId: route.taskId) {
            _Concurrency.Task { await store.load() }
          }
          .environment(ThemeManager.shared)
        }
      }
    }
  }
}
