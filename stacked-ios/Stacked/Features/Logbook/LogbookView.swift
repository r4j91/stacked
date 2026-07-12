import SwiftUI

// Paridade lib/screens/logbook_screen.dart
struct LogbookView: View {
  @Environment(ThemeManager.self) private var theme

  @State private var tasks: [Task] = []
  @State private var loading = true
  @State private var allowRowHeavyWork = false
  @State private var detailRoute: TaskDetailRoute?
  @State private var subtaskDetailRoute: SubtaskDetailRoute?
  @Namespace private var taskDetailZoom

  private static let months = [
    "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
    "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro",
  ]

  var body: some View {
    let c = theme.colors
    let grouped = groupedTasks
    let keys = grouped.keys

    Group {
      if loading {
        ProgressView().tint(c.accent)
      } else if tasks.isEmpty {
        EmptyStateView(
          icon: .logbook,
          title: "Nenhuma tarefa concluída",
          subtitle: "As tarefas concluídas aparecerão aqui"
        )
        .stackedStandaloneEmptyState()
      } else {
        List {
          ForEach(keys, id: \.self) { key in
            Section {
              ForEach(grouped.groups[key] ?? []) { task in
                logbookTaskRow(task)
              }
            } header: {
              SectionLabel(text: key)
            }
          }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .stackedListTailInset()
        .stackedScrollEdgeChrome()
      }
    }
    .stackedTabletCentered()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(c.background)
    .navigationTitle("Registro")
    .navigationBarTitleDisplayMode(.large)
    .refreshable { await load() }
    .stackedListRowWorkGate($allowRowHeavyWork)
    .task {
      await NavigationPushMotion.awaitSettle()
      guard !_Concurrency.Task.isCancelled else { return }
      await load()
    }
    .fullScreenCover(item: $detailRoute, onDismiss: {
      _Concurrency.Task { await load() }
    }) { route in
      TaskDetailZoom.cover(route: route, namespace: taskDetailZoom) {
        TaskDetailView(taskId: route.taskId)
        .environment(ThemeManager.shared)
      }
    }
    .sheet(item: $subtaskDetailRoute) { route in
      SubtaskDetailView(subtask: route.subtask, parentTaskId: route.parentTaskId) { snapshot in
        await SubtaskSaveHandler.handle(snapshot, patch: { patchLogbookSubtask($0) }) { await load() }
      }
      .environment(ThemeManager.shared)
    }
  }

  private var rowInsets: EdgeInsets {
    EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
  }

  @ViewBuilder
  private func logbookTaskRow(_ task: Task) -> some View {
    TaskRow(
      task: task,
      deferHeavyWork: !allowRowHeavyWork,
      onToggle: { uncomplete(task) },
      onTap: { detailRoute = TaskDetailRoute(taskId: task.id) },
      onSubtaskTap: { sub in
        subtaskDetailRoute = SubtaskDetailRoute(subtask: sub, parentTaskId: task.id)
      },
      onSubtaskChanged: { snapshot in
        patchLogbookSubtask(snapshot)
      }
    )
    .id(task.id)
    .taskDetailZoomSource(id: task.id, namespace: taskDetailZoom)
    .opacity(0.85)
    .listRowInsets(rowInsets)
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
    .taskContextMenu(
      task: task,
      onEdit: { detailRoute = TaskDetailRoute(taskId: task.id) },
      onComplete: { uncomplete(task) },
      onDuplicate: { duplicate(task) },
      onDelete: { delete(task) },
      onRefresh: { _Concurrency.Task { await load() } }
    )
  }

  private func patchLogbookSubtask(_ snapshot: SubtaskSaveSnapshot) {
    SubtaskListPatch.apply(snapshot, to: &tasks)
  }

  private func uncomplete(_ task: Task) {
    guard let i = tasks.firstIndex(where: { $0.id == task.id }) else { return }
    let snapshot = tasks[i]
    tasks.remove(at: i)
    HapticService.light()
    _Concurrency.Task {
      do {
        try await TaskRepository.shared.toggleTaskDone(id: task.id, done: false)
      } catch {
        tasks.insert(snapshot, at: min(i, tasks.count))
      }
    }
  }

  private func delete(_ task: Task) {
    tasks.removeAll { $0.id == task.id }
    HapticService.taskDeleted()
    _Concurrency.Task {
      try? await TaskRepository.shared.deleteTask(id: task.id)
    }
  }

  private func duplicate(_ task: Task) {
    _Concurrency.Task {
      _ = try? await TaskRepository.shared.duplicateTask(task)
      await load()
    }
  }

  private var groupedTasks: (keys: [String], groups: [String: [Task]]) {
    let now = Date()
    let today = Calendar.current.startOfDay(for: now)
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
    var groups: [String: [Task]] = [:]
    var keys: [String] = []

    for task in tasks {
      let label: String
      if let due = task.dueDate {
        let day = Calendar.current.startOfDay(for: due)
        if day == today {
          label = "Hoje"
        } else if day == yesterday {
          label = "Ontem"
        } else {
          let month = Self.months[Calendar.current.component(.month, from: due) - 1]
          var text = "\(Calendar.current.component(.day, from: due)) de \(month)"
          if Calendar.current.component(.year, from: due) != Calendar.current.component(.year, from: now) {
            text += " de \(Calendar.current.component(.year, from: due))"
          }
          label = text
        }
      } else {
        label = "Sem data"
      }

      if groups[label] == nil { keys.append(label) }
      groups[label, default: []].append(task)
    }

    return (keys, groups)
  }

  private func load() async {
    loading = tasks.isEmpty
    defer { loading = false }
    tasks = (try? await TaskRepository.shared.fetchLogbookTasks()) ?? []
  }
}
