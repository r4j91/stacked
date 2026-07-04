import SwiftUI

// Paridade lib/screens/inbox_screen.dart
struct InboxView: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @AppStorage("show_completed_tasks") private var showCompleted = false
  @State private var store = TaskStore.shared
  @State private var completedExpanded = false
  @State private var detailRoute: TaskDetailRoute?
  @State private var subtaskDetailRoute: SubtaskDetailRoute?
  @Namespace private var taskDetailZoom

  var body: some View {
    let c = theme.colors
    let count = store.inboxPending.count
    let subtitle = "\(count) \(count == 1 ? "tarefa" : "tarefas")"

    List {
      Section {
        TaskListScreenHeader(title: "Caixa de entrada", subtitle: subtitle)
          .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }

      if store.inboxLoading {
        Section {
          ProgressView()
            .tint(c.accent)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        }
      } else if let err = store.inboxError {
        Section {
          LoadErrorView(message: err) {
            _Concurrency.Task { await store.loadInbox() }
          }
          .listRowBackground(Color.clear)
        }
      } else if store.inboxPending.isEmpty && (store.inboxCompleted.isEmpty || !showCompleted) {
        Section {
          EmptyStateView(icon: .navInbox, title: "Inbox limpo", subtitle: "Nenhuma tarefa sem data ou projeto")
          .listRowBackground(Color.clear)
        }
      } else {
        Section {
          ForEach(store.inboxPending) { task in
            taskRow(task)
          }
        }

        if showCompleted && !store.inboxCompleted.isEmpty {
          Section {
            Button {
              // SUBSTITUIDO_FASE2: withAnimation { completedExpanded.toggle() }
              AppMotion.animate(AppMotion.snappy, reduceMotion: reduceMotion) { completedExpanded.toggle() }
            } label: {
              HStack {
                Text("Concluídas (\(store.inboxCompleted.count))")
                  .font(AppTypography.completedSectionHeader)
                  .foregroundStyle(c.textSecondary)
                Spacer()
                Image(systemName: completedExpanded ? "chevron.up" : "chevron.down")
                  .font(AppTypography.metaSmall.weight(.semibold))
                  .foregroundStyle(c.textTertiary)
              }
            }
            .listRowBackground(Color.clear)

            if completedExpanded {
              ForEach(store.inboxCompleted) { task in
                TaskRow(task: task) { }
                  .opacity(0.7)
                  .listRowInsets(rowInsets)
                  .listRowSeparator(.hidden)
                  .listRowBackground(Color.clear)
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
    .scrollContentBackground(.hidden)
    .stackedListTailInset()
    .stackedTabletCentered()
    .background(c.background)
    .refreshable { await store.loadInbox() }
    .fullScreenCover(item: $detailRoute, onDismiss: {
      _Concurrency.Task {
        await store.loadInbox()
        await store.loadToday()
      }
    }) { route in
      TaskDetailZoom.cover(route: route, namespace: taskDetailZoom) {
        TaskDetailView(taskId: route.taskId)
        .environment(ThemeManager.shared)
      }
    }
    .sheet(item: $subtaskDetailRoute) { route in
      SubtaskDetailView(subtask: route.subtask) {
        _Concurrency.Task { await store.loadInbox() }
      }
      .environment(ThemeManager.shared)
    }
  }

  private var rowInsets: EdgeInsets {
    EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
  }

  @ViewBuilder
  private func taskRow(_ task: Task) -> some View {
    TaskRow(task: task, onToggle: {
      store.completeInbox(task)
    }, onTap: {
      detailRoute = TaskDetailRoute(taskId: task.id)
    }, onSubtaskTap: { sub in
      subtaskDetailRoute = SubtaskDetailRoute(subtask: sub)
    }, onSubtaskChanged: {
      _Concurrency.Task { await store.loadInbox() }
    })
    .id(task.id)
    .taskDetailZoomSource(id: task.id, namespace: taskDetailZoom)
    .taskCompleteRemovalTransition()
    .listRowInsets(rowInsets)
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
    .taskContextMenu(
      task: task,
      onEdit: { detailRoute = TaskDetailRoute(taskId: task.id) },
      onComplete: { store.completeInbox(task) },
      onDuplicate: { store.duplicateInbox(task) },
      onDelete: { store.deleteInbox(task) },
      onRefresh: { _Concurrency.Task { await store.loadInbox() } }
    )
    .swipeActions(edge: .leading, allowsFullSwipe: true) {
      Button {
        store.completeInbox(task)
      } label: {
        Label("Concluir", systemImage: "checkmark")
      }
      .tint(AppColors.dateDueToday)
    }
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
      Button {
        HapticService.light()
        _Concurrency.Task { try? await store.postponeInbox(task) }
      } label: {
        Label("Adiar", systemImage: "clock")
      }
      .tint(AppColors.priorityMedium)

      Button(role: .destructive) {
        HapticService.warning()
        store.deleteInbox(task)
      } label: {
        Label("Excluir", systemImage: "trash")
      }
    }
  }
}
