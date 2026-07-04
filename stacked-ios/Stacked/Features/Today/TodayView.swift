import SwiftUI

// Paridade lib/screens/today_screen.dart
struct TodayView: View {
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
    let overdue = store.todayOverdue
    let timeline = store.todayTimeline

    List {
      Section {
        TaskListScreenHeader(title: "Hoje", subtitle: NavTab.today.subtitle)
          .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }

      if store.todayLoading {
        Section {
          ProgressView()
            .tint(c.accent)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        }
      } else if let err = store.todayError {
        Section {
          LoadErrorView(message: err) {
            _Concurrency.Task { await store.loadToday() }
          }
          .listRowBackground(Color.clear)
        }
      } else if overdue.isEmpty && timeline.isEmpty && (store.todayCompleted.isEmpty || !showCompleted) {
        Section {
          EmptyStateView(icon: .sun, title: "Tudo em dia", subtitle: "Nenhuma tarefa para hoje")
          .listRowBackground(Color.clear)
        }
      } else {
        if !overdue.isEmpty {
          Section {
            ForEach(overdue) { task in
              taskRow(task)
            }
          } header: {
            ListSectionHeader(text: "ATRASADAS")
          }
        }

        if !timeline.isEmpty {
          Section {
            ForEach(timeline) { item in
              scheduleRow(item)
            }
          } header: {
            if !overdue.isEmpty { ListSectionHeader(text: "HOJE") }
          }
        }

        if showCompleted && !store.todayCompleted.isEmpty {
          Section {
            Button {
              // SUBSTITUIDO_FASE2: withAnimation { completedExpanded.toggle() }
              AppMotion.animate(AppMotion.snappy, reduceMotion: reduceMotion) { completedExpanded.toggle() }
            } label: {
              HStack {
                Text("Concluídas (\(store.todayCompleted.count))")
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
              ForEach(store.todayCompleted) { task in
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
    .refreshable { await store.loadToday() }
    .task { await store.loadToday() }
    .fullScreenCover(item: $detailRoute, onDismiss: {
      _Concurrency.Task {
        await store.loadToday()
        await store.loadInbox()
      }
    }) { route in
      TaskDetailZoom.cover(route: route, namespace: taskDetailZoom) {
        TaskDetailView(taskId: route.taskId)
        .environment(ThemeManager.shared)
      }
    }
    .sheet(item: $subtaskDetailRoute) { route in
      SubtaskDetailView(subtask: route.subtask) {
        _Concurrency.Task { await store.loadToday() }
      }
      .environment(ThemeManager.shared)
    }
  }

  private var rowInsets: EdgeInsets {
    EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
  }

  @ViewBuilder
  private func scheduleRow(_ item: ScheduleItem) -> some View {
    switch item {
    case .task(let task):
      taskRow(task)
    case .calendarEvent(let event):
      CalendarEventRow(event: event) {
        EventKitCalendarService.shared.openInCalendar(event)
      }
      .listRowInsets(rowInsets)
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
    }
  }

  @ViewBuilder
  private func taskRow(_ task: Task) -> some View {
    TaskRow(task: task, onToggle: {
      store.completeToday(task)
    }, onTap: {
      detailRoute = TaskDetailRoute(taskId: task.id)
    }, onSubtaskTap: { sub in
      subtaskDetailRoute = SubtaskDetailRoute(subtask: sub)
    }, onSubtaskChanged: {
      _Concurrency.Task { await store.loadToday() }
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
      onComplete: { store.completeToday(task) },
      onDuplicate: { store.duplicateToday(task) },
      onDelete: { store.deleteToday(task) },
      onRefresh: { _Concurrency.Task { await store.loadToday() } }
    )
    .swipeActions(edge: .leading, allowsFullSwipe: true) {
      Button {
        store.completeToday(task)
      } label: {
        Label("Concluir", systemImage: "checkmark")
      }
      .tint(AppColors.dateDueToday)
    }
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
      Button {
        HapticService.light()
        _Concurrency.Task { try? await store.postponeToday(task) }
      } label: {
        Label("Adiar", systemImage: "clock")
      }
      .tint(AppColors.priorityMedium)

      Button(role: .destructive) {
        HapticService.warning()
        store.deleteToday(task)
      } label: {
        Label("Excluir", systemImage: "trash")
      }
    }
  }
}
