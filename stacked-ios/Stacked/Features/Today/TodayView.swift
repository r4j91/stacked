import SwiftUI

// Paridade lib/screens/today_screen.dart
struct TodayView: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @AppStorage(ShowCompletedPreferences.todayKey) private var showCompleted = false
  @AppStorage(UIKitTaskListStorage.key) private var useUIKitTaskList = UIKitTaskListStorage.defaultEnabled
  @AppStorage(ProjectDisplayMode.storageKey) private var displayModeRaw = ProjectDisplayMode.defaultRawValue
  /// PERF_FASEB3_3A — T2 desligado do path ativo (sempre false via ScrollPerfDebugStorage).
  // @AppStorage(ScrollPerfDebugStorage.t2RowsPlaceholderKey) private var t2RowsPlaceholder = false
  private var t2RowsPlaceholder: Bool { ScrollPerfDebugStorage.t2RowsPlaceholder }
  @State private var store = TaskStore.shared
  @State private var router = AppNavigationRouter.shared
  @State private var completedExpanded = false
  @State private var allowRowHeavyWork = false
  @State private var detailRoute: TaskDetailRoute?
  @State private var subtaskDetailRoute: SubtaskDetailRoute?
  @Namespace private var taskDetailZoom

  private var displayMode: ProjectDisplayMode { ProjectDisplayMode.from(displayModeRaw) }

  /// UIKit quando há conteúdo (inclui subtarefas avulsas e eventos de calendário).
  private var prefersUIKitList: Bool {
    guard useUIKitTaskList,
          !store.todayLoading || !store.todayTimeline.isEmpty || !store.todayOverdueItems.isEmpty,
          store.todayError == nil
    else { return false }
    return !store.todayOverdueItems.isEmpty
      || !store.todayTimeline.isEmpty
      || (showCompleted && !store.todayCompleted.isEmpty)
  }

  var body: some View {
    let c = theme.colors

    Group {
      if prefersUIKitList {
        uikitTodayBody(colors: c)
      } else {
        swiftUITodayBody(colors: c)
      }
    }
    .stackedTabletCentered()
    .background(c.background)
    .stackedListRowWorkGate($allowRowHeavyWork)
    .onAppear {
      ScrollHitchProbe.noteScreen("Hoje")
      openPendingTaskIfNeeded()
    }
    .onChange(of: router.pendingTaskId) { _, _ in openPendingTaskIfNeeded() }
    .fullScreenCover(item: $detailRoute, onDismiss: {
      _Concurrency.Task {
        await TaskDetailDismissRefresh.afterDismiss(tab: .today) {
          await store.loadToday()
          await store.loadInbox()
        }
      }
    }) { route in
      TaskDetailZoom.cover(route: route, namespace: taskDetailZoom) {
        TaskDetailView(taskId: route.taskId, seed: route.seed)
        .environment(ThemeManager.shared)
      }
    }
    .sheet(item: $subtaskDetailRoute) { route in
      SubtaskDetailView(subtask: route.subtask, parentTaskId: route.parentTaskId) { snapshot in
        await SubtaskSaveHandler.handle(snapshot) { await store.loadToday() }
      }
      .environment(ThemeManager.shared)
    }
  }

  @ViewBuilder
  private func uikitTodayBody(colors: AppThemeColors) -> some View {
    UIKitHostedTaskList(
      sections: todayUIKitSections,
      showProject: true,
      style: displayMode.taskRowStyle,
      flatSubtaskQueue: displayMode.flatSubtaskQueue,
      rowInsets: rowInsets,
      background: colors.background,
      leadingChrome: {
        AnyView(
          TaskListScreenHeader(
            title: "Hoje",
            subtitle: NavTab.today.subtitle,
            showCompletedKey: ShowCompletedPreferences.todayKey,
            showCompletedDefault: false
          )
          .padding(.top, 4)
          .padding(.bottom, 8)
        )
      },
      onToggleSection: { id in
        if id == "completed" {
          AppMotion.animate(AppMotion.snappy, reduceMotion: reduceMotion) {
            completedExpanded.toggle()
          }
        }
      },
      onToggle: { store.completeToday($0) },
      onTap: { detailRoute = TaskDetailRoute(task: $0) },
      onSubtaskTap: { task, sub in
        subtaskDetailRoute = SubtaskDetailRoute(subtask: sub, parentTaskId: task.id)
      },
      onSubtaskChanged: { store.applySubtaskPatch($0) },
      onSubtaskDeleted: { task, sub in store.removeSubtask(parentId: task.id, subtask: sub) },
      onEdit: { detailRoute = TaskDetailRoute(task: $0) },
      onComplete: { store.completeToday($0) },
      onDuplicate: { store.duplicateToday($0) },
      onDelete: { store.deleteToday($0) },
      onRefresh: { _Concurrency.Task { await store.loadToday() } },
      onScheduledSubtaskToggle: { store.completeScheduledSubtask($0) },
      onScheduledSubtaskTap: { entry in
        subtaskDetailRoute = SubtaskDetailRoute(subtask: entry.subtask, parentTaskId: entry.parent.id)
      },
      onCalendarEventTap: { EventKitCalendarService.shared.openInCalendar($0) }
    )
    .stackedScrollEdgeChrome()
  }

  private var todayUIKitSections: [UIKitTaskSection] {
    var sections: [UIKitTaskSection] = []

    if !store.todayOverdueItems.isEmpty {
      sections.append(
        UIKitTaskSection(
          id: "overdue",
          header: .plain("ATRASADAS"),
          tasks: [],
          scheduleItems: store.todayOverdueItems
        )
      )
    }
    if !store.todayTimeline.isEmpty {
      sections.append(
        UIKitTaskSection(
          id: "today",
          header: store.todayOverdueItems.isEmpty ? nil : .plain("HOJE"),
          tasks: [],
          scheduleItems: store.todayTimeline
        )
      )
    }
    if showCompleted, !store.todayCompleted.isEmpty {
      sections.append(
        UIKitTaskSection(
          id: "completed",
          header: .completedToggle(count: store.todayCompleted.count, expanded: completedExpanded),
          tasks: store.todayCompleted,
          dimmed: true
        )
      )
    }
    return sections
  }

  @ViewBuilder
  private func swiftUITodayBody(colors: AppThemeColors) -> some View {
    let timeline = store.todayTimeline

    List {
      Section {
        TaskListScreenHeader(
          title: "Hoje",
          subtitle: NavTab.today.subtitle,
          showCompletedKey: ShowCompletedPreferences.todayKey,
          showCompletedDefault: false
        )
          .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }

      if store.todayLoading && store.todayTimeline.isEmpty && store.todayOverdueItems.isEmpty {
        Section {
          ProgressView()
            .tint(colors.accent)
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
      } else if store.todayOverdueItems.isEmpty && timeline.isEmpty && (store.todayCompleted.isEmpty || !showCompleted) {
        Section {
          EmptyStateView(
            illustration: .todayClear,
            title: "Dia livre",
            subtitle: "Nada agendado para hoje. Aproveite o momento."
          )
          .stackedListEmptyStateRow()
        }
      } else {
        if !store.todayOverdueItems.isEmpty {
          Section {
            ForEach(store.todayOverdueItems) { item in
              scheduleRow(item)
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
            if !store.todayOverdueItems.isEmpty { ListSectionHeader(text: "HOJE") }
          }
        }

        if showCompleted && !store.todayCompleted.isEmpty {
          Section {
            Button {
              AppMotion.animate(AppMotion.snappy, reduceMotion: reduceMotion) { completedExpanded.toggle() }
            } label: {
              HStack {
                Text("Concluídas (\(store.todayCompleted.count))")
                  .font(AppTypography.completedSectionHeader)
                  .foregroundStyle(colors.textSecondary)
                Spacer()
                Image(systemName: completedExpanded ? "chevron.up" : "chevron.down")
                  .font(AppTypography.metaSmall.weight(.semibold))
                  .foregroundStyle(colors.textTertiary)
              }
            }
            .listRowBackground(Color.clear)

            if completedExpanded {
              ForEach(store.todayCompleted) { task in
                TaskRow(
                  task: task,
                  style: displayMode.taskRowStyle,
                  flatSubtaskQueue: displayMode.flatSubtaskQueue,
                  deferHeavyWork: !allowRowHeavyWork
                ) { }
                  .opacity(0.7)
                  .listRowInsets(rowInsets)
                  .listRowSeparator(.hidden)
                  .listRowBackground(Color.clear)
              }
            }
          }
        }
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .stackedListTailInset()
    .refreshable { await store.loadToday() }
  }

  private var rowInsets: EdgeInsets {
    displayMode.taskListRowInsets
  }

  private func openPendingTaskIfNeeded() {
    guard let id = router.consumeTaskId() else { return }
    guard TaskIdentity.isValidUUID(id) else { return }
    detailRoute = TaskDetailRoute(taskId: id)
  }

  @ViewBuilder
  private func scheduleRow(_ item: ScheduleItem) -> some View {
    switch item {
    case .task(let task):
      taskRow(task)
    case .subtask(let entry):
      FilterSubtaskRow(
        subtask: entry.subtask,
        parent: entry.parent,
        labelCatalog: entry.parent.labels,
        onToggle: { store.completeScheduledSubtask(entry) },
        onTap: { subtaskDetailRoute = SubtaskDetailRoute(subtask: entry.subtask, parentTaskId: entry.parent.id) }
      )
      .listRowInsets(rowInsets)
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
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
    // PERF_FASEB3_ETAPA2 T2
    if t2RowsPlaceholder {
      TaskRowScrollPlaceholder(task: task, showProject: true, style: displayMode.taskRowStyle)
        .id(task.id)
        .listRowInsets(rowInsets)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    } else {
      TaskRow(
        task: task,
        style: displayMode.taskRowStyle,
        flatSubtaskQueue: displayMode.flatSubtaskQueue,
        deferHeavyWork: !allowRowHeavyWork,
        onToggle: {
        store.completeToday(task)
      }, onTap: {
        detailRoute = TaskDetailRoute(task: task)
      }, onSubtaskTap: { sub in
        subtaskDetailRoute = SubtaskDetailRoute(subtask: sub, parentTaskId: task.id)
      }, onSubtaskChanged: { snapshot in
        store.applySubtaskPatch(snapshot)
      }, onSubtaskDeleted: { sub in
        store.removeSubtask(parentId: task.id, subtask: sub)
      })
      .id(task.id)
      .taskDetailZoomSource(id: task.id, namespace: taskDetailZoom, active: detailRoute?.taskId == task.id)
      .taskCompleteRemovalTransition()
      .listRowInsets(rowInsets)
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
      .taskContextMenu(
        task: task,
        onEdit: { detailRoute = TaskDetailRoute(task: task) },
        onComplete: { store.completeToday(task) },
        onDuplicate: { store.duplicateToday(task) },
        onDelete: { store.deleteToday(task) },
        onRefresh: { _Concurrency.Task { await store.loadToday() } }
      )
    }
  }
}
