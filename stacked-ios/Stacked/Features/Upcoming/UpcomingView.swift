import SwiftUI

// Paridade lib/screens/upcoming_screen.dart
struct UpcomingView: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @AppStorage(UIKitTaskListStorage.key) private var useUIKitTaskList = UIKitTaskListStorage.defaultEnabled
  @AppStorage(TimelineRailStorage.key) private var timelineRailEnabled = TimelineRailStorage.defaultEnabled
  @AppStorage(ProjectDisplayMode.storageKey) private var displayModeRaw = ProjectDisplayMode.defaultRawValue
  @State private var store = UpcomingStore.shared
  @State private var allowRowHeavyWork = false
  @State private var detailRoute: TaskDetailRoute?
  @State private var subtaskDetailRoute: SubtaskDetailRoute?
  @Namespace private var taskDetailZoom

  private var displayMode: ProjectDisplayMode { ProjectDisplayMode.from(displayModeRaw) }

  /// UIKit na lista de schedule (inclui subtarefas avulsas e eventos).
  private var prefersUIKitList: Bool {
    guard useUIKitTaskList,
          !store.isLoading,
          store.error == nil || !store.groupedSchedule.isEmpty,
          !store.groupedSchedule.isEmpty
    else { return false }
    return true
  }

  var body: some View {
    let c = theme.colors

    VStack(spacing: 0) {
      if store.mode != .agenda {
        calendarSection
          .padding(.horizontal, AppSpacing.sm)
          .padding(.bottom, AppSpacing.sm)
      }

      if prefersUIKitList {
        UIKitHostedTaskList(
          sections: upcomingUIKitSections,
          showProject: true,
          style: displayMode.taskRowStyle,
          flatSubtaskQueue: displayMode.flatSubtaskQueue,
          rowInsets: rowInsets,
          background: c.background,
          leadingChrome: {
            AnyView(upcomingListChrome)
          },
          supportsTimelineRail: true,
          onToggle: { store.complete($0) },
          onTap: { detailRoute = TaskDetailRoute(task: $0) },
          onSubtaskTap: { task, sub in
            subtaskDetailRoute = SubtaskDetailRoute(subtask: sub, parentTaskId: task.id)
          },
          onSubtaskChanged: { store.applySubtaskPatch($0) },
          onSubtaskDeleted: { task, sub in store.removeSubtask(parentId: task.id, subtask: sub) },
          onEdit: { detailRoute = TaskDetailRoute(task: $0) },
          onComplete: { store.complete($0) },
          onDuplicate: { task in
            _Concurrency.Task {
              _ = try? await TaskRepository.shared.duplicateTask(task)
              await store.load()
            }
          },
          onDelete: { store.delete($0) },
          onRefresh: { _Concurrency.Task { await store.load() } },
          onScheduledSubtaskToggle: { store.completeScheduledSubtask($0) },
          onScheduledSubtaskTap: { entry in
            subtaskDetailRoute = SubtaskDetailRoute(subtask: entry.subtask, parentTaskId: entry.parent.id)
          },
          onCalendarEventTap: { EventKitCalendarService.shared.openInCalendar($0) },
          pinPlainSectionHeaders: true
        )
        .stackedScrollEdgeChrome()
      } else {
        upcomingSwiftUIList
      }
    }
    .stackedTabletCentered()
    .background(c.background)
    .refreshable { await store.load() }
    .stackedListRowWorkGate($allowRowHeavyWork)
    .fullScreenCover(item: $detailRoute, onDismiss: {
      _Concurrency.Task {
        await TaskDetailDismissRefresh.afterDismiss(tab: .upcoming) {
          await store.load()
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
        await SubtaskSaveHandler.handle(snapshot, patch: store.applySubtaskPatch) { await store.load() }
      }
      .environment(ThemeManager.shared)
    }
  }

  private var upcomingUIKitSections: [UIKitTaskSection] {
    store.groupedSchedule.map { group in
      UIKitTaskSection(
        id: String(Int(group.day.timeIntervalSince1970)),
        header: .plain(TaskMapper.dayLabel(for: group.day).uppercased()),
        tasks: [],
        scheduleItems: group.items
      )
    }
  }

  private var upcomingListChrome: some View {
    VStack(alignment: .leading, spacing: AppSpacing.sm) {
      ScreenHeader(title: "Em breve", subtitle: NavTab.upcoming.subtitle)
      modeToggle
        .padding(.horizontal, AppSpacing.lg)
    }
  }

  @ViewBuilder
  private var upcomingSwiftUIList: some View {
    let c = theme.colors
    List {
      Section {
        ScreenHeader(title: "Em breve", subtitle: NavTab.upcoming.subtitle)
          .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }

      Section {
        modeToggle
          .listRowInsets(EdgeInsets(top: 0, leading: AppSpacing.lg, bottom: AppSpacing.sm, trailing: AppSpacing.lg))
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }

      if store.isLoading {
        Section {
          ProgressView()
            .tint(c.accent)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        }
      } else if let err = store.error, store.tasks.isEmpty && store.scheduledSubtasks.isEmpty {
        Section {
          LoadErrorView(message: err) {
            _Concurrency.Task { await store.load() }
          }
          .listRowBackground(Color.clear)
        }
      } else if store.groupedSchedule.isEmpty {
        Section {
          EmptyStateView(
            icon: .navUpcoming,
            title: "Nenhuma tarefa",
            subtitle: "Selecione outro dia ou adicione uma tarefa com data de vencimento."
          )
          .stackedListEmptyStateRow()
        }
      } else {
        ForEach(store.groupedSchedule, id: \.day) { group in
          Section {
            ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
              scheduleRow(
                item,
                connectsUp: index > 0,
                connectsDown: index < group.items.count - 1
              )
            }
          } header: {
            ListSectionHeader(text: TaskMapper.dayLabel(for: group.day).uppercased())
          }
        }
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    // Soft topo só no path SwiftUI (Home) — no UIKit o soft hitcha; sticky usa fill sólido.
    .stackedDashboardListChrome()
  }

  private var modeToggle: some View {
    let c = theme.colors
    return HStack(spacing: AppSpacing.xs) {
      ForEach(UpcomingCalendarMode.allCases) { mode in
        let selected = store.mode == mode
        Button {
          HapticService.selection()
          AppMotion.animate(AppMotion.snappy, reduceMotion: reduceMotion) {
            store.mode = mode
          }
        } label: {
          Text(mode.label)
            .font(AppTypography.modeToggleLabel(selected: selected))
            .foregroundStyle(selected ? c.accent : c.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(selected ? c.surfaceVariant : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
      }
    }
    .padding(AppSpacing.xs)
    .background(c.surface)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .overlay(RoundedRectangle(cornerRadius: 12).stroke(c.textPrimary.opacity(0.06)))
  }

  @ViewBuilder
  private var calendarSection: some View {
    switch store.mode {
    case .month:
      DatePicker(
        "",
        selection: Binding(
          get: { store.focusedDay },
          set: {
            HapticService.dateSelected()
            store.focusedDay = $0
            store.toggleDaySelection($0)
          }
        ),
        displayedComponents: .date
      )
      .datePickerStyle(.graphical)
      .tint(theme.colors.accent)
      .labelsHidden()

    case .week:
      WeekStripCalendar(
        focusedDay: store.focusedDay,
        selectedDay: store.selectedDay,
        daysWithTasks: store.daysWithTasks
      ) { day in
        HapticService.dateSelected()
        store.focusedDay = day
        store.toggleDaySelection(day)
      }

    case .agenda:
      EmptyView()
    }
  }

  private var rowInsets: EdgeInsets {
    displayMode.taskListRowInsets
  }

  private var railListInsets: EdgeInsets {
    var insets = rowInsets
    if timelineRailEnabled {
      insets.leading = max(4, insets.leading - 24)
    }
    return insets
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
    TaskRow(
      task: task,
      style: displayMode.taskRowStyle,
      flatSubtaskQueue: displayMode.flatSubtaskQueue,
      deferHeavyWork: !allowRowHeavyWork,
      onToggle: {
      store.complete(task)
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
      onComplete: { store.complete(task) },
      onDuplicate: {
        _Concurrency.Task {
          _ = try? await TaskRepository.shared.duplicateTask(task)
          await store.load()
        }
      },
      onDelete: { store.delete(task) },
      onRefresh: { _Concurrency.Task { await store.load() } }
    )
  }
}

// Faixa de 7 dias — paridade modo semana
private struct WeekStripCalendar: View {
  @Environment(ThemeManager.self) private var theme
  let focusedDay: Date
  let selectedDay: Date?
  let daysWithTasks: Set<Date>
  let onSelect: (Date) -> Void

  private var weekDays: [Date] {
    let cal = Calendar.current
    let start = cal.dateInterval(of: .weekOfYear, for: focusedDay)?.start ?? focusedDay
    return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
  }

  var body: some View {
    let c = theme.colors
    HStack(spacing: 6) {
      ForEach(weekDays, id: \.timeIntervalSince1970) { day in
        let selected = selectedDay.map { TaskMapper.isSameDay($0, day) } ?? false
        let hasTasks = daysWithTasks.contains(TaskMapper.startOfDay(day))
        let isToday = TaskMapper.isSameDay(day, Date())

        Button {
          HapticService.selection()
          onSelect(day)
        } label: {
          VStack(spacing: AppSpacing.xs) {
            Text(shortWeekday(day))
              .font(AppTypography.metaSmall)
              .foregroundStyle(c.textTertiary)
            Text("\(Calendar.current.component(.day, from: day))")
              .font(AppTypography.calendarDayNumber(selected: selected))
              .foregroundStyle(selected ? c.accent : (isToday ? c.textPrimary : c.textSecondary))
            Circle()
              .fill(hasTasks ? c.accent : Color.clear)
              .frame(width: 5, height: 5)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, AppSpacing.sm)
          .background(selected ? c.surfaceVariant : Color.clear)
          .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.vertical, AppSpacing.xs)
  }

  private func shortWeekday(_ date: Date) -> String {
    let weekday = Calendar.current.component(.weekday, from: date)
    let labels = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
    return labels[weekday - 1]
  }
}
