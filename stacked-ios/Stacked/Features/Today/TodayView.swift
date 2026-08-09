import SwiftUI

// Paridade lib/screens/today_screen.dart
struct TodayView: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @AppStorage(ShowCompletedPreferences.todayKey) private var showCompleted = false
  @AppStorage(TimelineRailStorage.key) private var timelineRailEnabled = TimelineRailStorage.defaultEnabled
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

  var body: some View {
    let c = theme.colors

    TodayScreenBody(
      colors: c,
      showCompleted: showCompleted,
      timelineRailEnabled: timelineRailEnabled,
      displayMode: displayMode,
      t2RowsPlaceholder: t2RowsPlaceholder,
      reduceMotion: reduceMotion,
      completedExpanded: $completedExpanded,
      allowRowHeavyWork: allowRowHeavyWork,
      detailRoute: $detailRoute,
      subtaskDetailRoute: $subtaskDetailRoute,
      taskDetailZoom: taskDetailZoom
    )
    .stackedTabletCentered()
    .stackedListCanvasBackground(theme)
    .stackedListRowWorkGate($allowRowHeavyWork)
    .onAppear {
      ScrollHitchProbe.noteScreen("Hoje")
      openPendingTaskIfNeeded()
    }
    .onChange(of: router.pendingTaskId) { _, _ in openPendingTaskIfNeeded() }
    .taskDetailCover(item: $detailRoute, namespace: taskDetailZoom, onDismiss: {
      _Concurrency.Task {
        await TaskDetailDismissRefresh.afterDismiss(tab: .today) {
          await store.loadToday()
          await store.loadInbox()
        }
      }
    }) { route in
      TaskDetailView(taskId: route.taskId, seed: route.seed)
        .environment(ThemeManager.shared)
    }
    .sheet(item: $subtaskDetailRoute) { route in
      SubtaskDetailView(subtask: route.subtask, parentTaskId: route.parentTaskId) { snapshot in
        await SubtaskSaveHandler.handle(snapshot) { await store.loadToday() }
      }
      .environment(ThemeManager.shared)
    }
  }

  private func openPendingTaskIfNeeded() {
    guard let id = router.consumeTaskId() else { return }
    guard TaskIdentity.isValidUUID(id) else { return }
    detailRoute = TaskDetailRoute(taskId: id)
  }
}

// MARK: - Screen body

private struct TodayScreenBody: View {
  let colors: AppThemeColors
  let showCompleted: Bool
  let timelineRailEnabled: Bool
  let displayMode: ProjectDisplayMode
  let t2RowsPlaceholder: Bool
  let reduceMotion: Bool
  @Binding var completedExpanded: Bool
  let allowRowHeavyWork: Bool
  @Binding var detailRoute: TaskDetailRoute?
  @Binding var subtaskDetailRoute: SubtaskDetailRoute?
  var taskDetailZoom: Namespace.ID

  var body: some View {
    TodaySwiftUIListContent(
      colors: colors,
      showCompleted: showCompleted,
      timelineRailEnabled: timelineRailEnabled,
      displayMode: displayMode,
      t2RowsPlaceholder: t2RowsPlaceholder,
      reduceMotion: reduceMotion,
      completedExpanded: $completedExpanded,
      allowRowHeavyWork: allowRowHeavyWork,
      detailRoute: $detailRoute,
      subtaskDetailRoute: $subtaskDetailRoute,
      taskDetailZoom: taskDetailZoom
    )
  }
}

// MARK: - SwiftUI list shell (empty gate + list chrome)

private struct TodaySwiftUIListContent: View {
  @State private var store = TaskStore.shared

  let colors: AppThemeColors
  let showCompleted: Bool
  let timelineRailEnabled: Bool
  let displayMode: ProjectDisplayMode
  let t2RowsPlaceholder: Bool
  let reduceMotion: Bool
  @Binding var completedExpanded: Bool
  let allowRowHeavyWork: Bool
  @Binding var detailRoute: TaskDetailRoute?
  @Binding var subtaskDetailRoute: SubtaskDetailRoute?
  var taskDetailZoom: Namespace.ID

  private var isEmpty: Bool {
    !store.todayLoading
      && store.todayError == nil
      && store.todayOverdueItems.isEmpty
      && store.todayTimeline.isEmpty
      && (store.todayCompleted.isEmpty || !showCompleted)
  }

  var body: some View {
    // Empty fora do List: evita flash do separador de seção do UITableView/List.
    if isEmpty {
      ScrollView {
        VStack(spacing: 0) {
          TaskListScreenHeader(
            title: "Hoje",
            subtitle: NavTab.today.subtitle,
            showCompletedKey: ShowCompletedPreferences.todayKey,
            showCompletedDefault: false
          )
          .padding(.top, 4)
          .padding(.bottom, 8)

          EmptyStateView(
            illustration: .todayClear,
            title: "Dia livre",
            subtitle: "Nada agendado para hoje. Aproveite o momento."
          )
          .stackedStandaloneEmptyState()
          .frame(minHeight: 360)
        }
        .frame(maxWidth: .infinity)
      }
      .scrollContentBackground(.hidden)
      .refreshable { await store.loadToday() }
    } else {
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
            .listSectionSeparator(.hidden)
            .listRowBackground(Color.clear)
        }

        TodaySwiftUIStatusOrRows(
          colors: colors,
          showCompleted: showCompleted,
          timelineRailEnabled: timelineRailEnabled,
          displayMode: displayMode,
          t2RowsPlaceholder: t2RowsPlaceholder,
          reduceMotion: reduceMotion,
          completedExpanded: $completedExpanded,
          allowRowHeavyWork: allowRowHeavyWork,
          detailRoute: $detailRoute,
          subtaskDetailRoute: $subtaskDetailRoute,
          taskDetailZoom: taskDetailZoom
        )
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      .stackedListTailInset()
      .refreshable { await store.loadToday() }
    }
  }
}

// MARK: - Loading/error chrome vs timeline rows

private struct TodaySwiftUIStatusOrRows: View {
  @State private var store = TaskStore.shared

  let colors: AppThemeColors
  let showCompleted: Bool
  let timelineRailEnabled: Bool
  let displayMode: ProjectDisplayMode
  let t2RowsPlaceholder: Bool
  let reduceMotion: Bool
  @Binding var completedExpanded: Bool
  let allowRowHeavyWork: Bool
  @Binding var detailRoute: TaskDetailRoute?
  @Binding var subtaskDetailRoute: SubtaskDetailRoute?
  var taskDetailZoom: Namespace.ID

  var body: some View {
    if store.todayLoading && store.todayTimeline.isEmpty && store.todayOverdueItems.isEmpty {
      Section {
        ProgressView()
          .tint(colors.accent)
          .frame(maxWidth: .infinity)
          .listRowSeparator(.hidden)
          .listSectionSeparator(.hidden)
          .listRowBackground(Color.clear)
      }
    } else if let err = store.todayError {
      Section {
        LoadErrorView(message: err) {
          _Concurrency.Task { await store.loadToday() }
        }
        .listRowSeparator(.hidden)
        .listSectionSeparator(.hidden)
        .listRowBackground(Color.clear)
      }
    } else {
      TodayTimelineRows(
        colors: colors,
        showCompleted: showCompleted,
        timelineRailEnabled: timelineRailEnabled,
        displayMode: displayMode,
        t2RowsPlaceholder: t2RowsPlaceholder,
        reduceMotion: reduceMotion,
        completedExpanded: $completedExpanded,
        allowRowHeavyWork: allowRowHeavyWork,
        detailRoute: $detailRoute,
        subtaskDetailRoute: $subtaskDetailRoute,
        taskDetailZoom: taskDetailZoom
      )
    }
  }
}

private struct TodayTimelineRows: View {
  @State private var store = TaskStore.shared

  let colors: AppThemeColors
  let showCompleted: Bool
  let timelineRailEnabled: Bool
  let displayMode: ProjectDisplayMode
  let t2RowsPlaceholder: Bool
  let reduceMotion: Bool
  @Binding var completedExpanded: Bool
  let allowRowHeavyWork: Bool
  @Binding var detailRoute: TaskDetailRoute?
  @Binding var subtaskDetailRoute: SubtaskDetailRoute?
  var taskDetailZoom: Namespace.ID

  private var rowInsets: EdgeInsets { displayMode.taskListRowInsets }

  private var railListInsets: EdgeInsets {
    var insets = rowInsets
    if timelineRailEnabled {
      insets.leading = max(4, insets.leading - 24)
    }
    return insets
  }

  var body: some View {
    let timeline = store.todayTimeline

    if !store.todayOverdueItems.isEmpty {
      Section {
        scheduleSectionRows(store.todayOverdueItems)
      } header: {
        ListSectionHeader(text: "ATRASADAS")
      }
    }

    if !timeline.isEmpty {
      Section {
        scheduleSectionRows(timeline)
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
          ForEach(Array(store.todayCompleted.enumerated()), id: \.element.id) { index, task in
            TaskRow(
              task: task,
              style: displayMode.taskRowStyle,
              flatSubtaskQueue: displayMode.flatSubtaskQueue,
              deferHeavyWork: !allowRowHeavyWork
            ) { }
              .opacity(0.7)
              .timelineRail(
                enabled: timelineRailEnabled,
                nodeColor: TimelineRailNodeColor.forTask(task),
                connectsUp: index > 0,
                connectsDown: index < store.todayCompleted.count - 1
              )
              .listRowInsets(railListInsets)
              .listRowSeparator(.hidden)
              .listRowBackground(Color.clear)
          }
        }
      }
    }
  }

  @ViewBuilder
  private func scheduleSectionRows(_ items: [ScheduleItem]) -> some View {
    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
      scheduleRow(
        item,
        connectsUp: index > 0,
        connectsDown: index < items.count - 1
      )
    }
  }

  @ViewBuilder
  private func scheduleRow(
    _ item: ScheduleItem,
    connectsUp: Bool = false,
    connectsDown: Bool = false
  ) -> some View {
    switch item {
    case .task(let task):
      taskRow(task, connectsUp: connectsUp, connectsDown: connectsDown)
    case .subtask(let entry):
      FilterSubtaskRow(
        subtask: entry.subtask,
        parent: entry.parent,
        labelCatalog: entry.parent.labels,
        style: displayMode.taskRowStyle,
        onToggle: { store.completeScheduledSubtask(entry) },
        onTap: { subtaskDetailRoute = SubtaskDetailRoute(subtask: entry.subtask, parentTaskId: entry.parent.id) }
      )
      .timelineRail(
        enabled: timelineRailEnabled,
        nodeColor: TimelineRailNodeColor.forSubtask(entry.subtask),
        connectsUp: connectsUp,
        connectsDown: connectsDown
      )
      .listRowInsets(railListInsets)
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
    case .calendarEvent(let event):
      CalendarEventRow(event: event) {
        EventKitCalendarService.shared.openInCalendar(event)
      }
      .timelineRail(
        enabled: timelineRailEnabled,
        nodeColor: AppColors.priorityLow,
        connectsUp: connectsUp,
        connectsDown: connectsDown
      )
      .listRowInsets(railListInsets)
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
    }
  }

  @ViewBuilder
  private func taskRow(
    _ task: Task,
    connectsUp: Bool = false,
    connectsDown: Bool = false
  ) -> some View {
    // PERF_FASEB3_ETAPA2 T2
    if t2RowsPlaceholder {
      TaskRowScrollPlaceholder(task: task, showProject: true, style: displayMode.taskRowStyle)
        .id(task.id)
        .timelineRail(
          enabled: timelineRailEnabled,
          nodeColor: TimelineRailNodeColor.forTask(task),
          connectsUp: connectsUp,
          connectsDown: connectsDown
        )
        .listRowInsets(railListInsets)
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
      .timelineRail(
        enabled: timelineRailEnabled,
        nodeColor: TimelineRailNodeColor.forTask(task),
        connectsUp: connectsUp,
        connectsDown: connectsDown
      )
      .listRowInsets(railListInsets)
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
      .taskContextMenu(
        task: task,
        onEdit: { detailRoute = TaskDetailRoute(task: task) },
        onComplete: { store.completeToday(task) },
        onDuplicate: { store.duplicateToday(task) },
        onDelete: { store.deleteToday(task) },
        onRefresh: { _Concurrency.Task { await store.loadToday() } },
        onPostpone: { _Concurrency.Task { try? await store.postponeToday(task) } }
      )
    }
  }
}
