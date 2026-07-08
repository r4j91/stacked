import SwiftUI

// Paridade lib/screens/upcoming_screen.dart
struct UpcomingView: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var store = UpcomingStore.shared
  @State private var detailRoute: TaskDetailRoute?
  @State private var subtaskDetailRoute: SubtaskDetailRoute?
  @Namespace private var taskDetailZoom

  var body: some View {
    let c = theme.colors

    VStack(spacing: 0) {
      if store.mode != .agenda {
        calendarSection
          .padding(.horizontal, AppSpacing.sm)
          .padding(.bottom, AppSpacing.sm)
      }

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

        if store.mode == .agenda {
          Section {
            HStack(spacing: 6) {
              Image(systemName: "list.bullet")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(c.accent)
              Text(store.agendaPeriodLabel)
                .font(AppTypography.completedSectionHeader)
                .foregroundStyle(c.accent)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: AppSpacing.xl, bottom: AppSpacing.sm, trailing: AppSpacing.xl))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
          }
        }

        if store.isLoading {
          Section {
            ProgressView()
              .tint(c.accent)
              .frame(maxWidth: .infinity)
              .listRowBackground(Color.clear)
          }
        } else if let err = store.error, store.tasks.isEmpty {
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
              ForEach(group.items) { item in
                scheduleRow(item)
              }
            } header: {
              ListSectionHeader(text: TaskMapper.dayLabel(for: group.day).uppercased())
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
    }
    .stackedTabletCentered()
    .background(c.background)
    .refreshable { await store.load() }
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
    EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.lg, bottom: AppSpacing.xs, trailing: AppSpacing.lg)
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
      store.complete(task)
    }, onTap: {
      detailRoute = TaskDetailRoute(taskId: task.id)
    }, onSubtaskTap: { sub in
      subtaskDetailRoute = SubtaskDetailRoute(subtask: sub, parentTaskId: task.id)
    }, onSubtaskChanged: {
      _Concurrency.Task { await store.load() }
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
