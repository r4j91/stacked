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

    List {
      Section {
        ScreenHeader(title: "Em breve", subtitle: NavTab.upcoming.subtitle)
          .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }

      Section {
        modeToggle
          .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
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
              .font(.system(size: 13, weight: .semibold))
              .foregroundStyle(c.accent)
          }
          .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 8, trailing: 20))
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
        }
      }

      if store.mode != .agenda {
        Section {
          calendarSection
            .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
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
      } else if store.filteredTasks.isEmpty {
        Section {
          EmptyStateView(icon: .navUpcoming, title: "Nenhuma tarefa", subtitle: "Selecione outro dia ou adicione uma tarefa com data de vencimento.")
          .listRowBackground(Color.clear)
        }
      } else {
        ForEach(store.groupedTasks, id: \.day) { group in
          Section {
            ForEach(group.tasks) { task in
              taskRow(task)
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
    .stackedTabletCentered()
    .background(c.background)
    .refreshable { await store.load() }
    .task { await store.load() }
    .fullScreenCover(item: $detailRoute) { route in
      TaskDetailZoom.cover(route: route, namespace: taskDetailZoom) {
        TaskDetailView(taskId: route.taskId) {
          _Concurrency.Task { await store.load() }
        }
        .environment(ThemeManager.shared)
      }
    }
    .sheet(item: $subtaskDetailRoute) { route in
      SubtaskDetailView(subtask: route.subtask) {
        _Concurrency.Task { await store.load() }
      }
      .environment(ThemeManager.shared)
    }
  }

  private var modeToggle: some View {
    let c = theme.colors
    return HStack(spacing: 4) {
      ForEach(UpcomingCalendarMode.allCases) { mode in
        let selected = store.mode == mode
        Button {
          HapticService.selection()
          // SUBSTITUIDO_FASE2: withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) { store.mode = mode }
          AppMotion.animate(AppMotion.snappy, reduceMotion: reduceMotion) {
            store.mode = mode
          }
        } label: {
          Text(mode.label)
            .font(.system(size: 13, weight: selected ? .semibold : .medium))
            .foregroundStyle(selected ? c.accent : c.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(selected ? c.surfaceVariant : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
      }
    }
    .padding(4)
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
    EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
  }

  @ViewBuilder
  private func taskRow(_ task: Task) -> some View {
    TaskRow(task: task, onToggle: {
      store.complete(task)
    }, onTap: {
      detailRoute = TaskDetailRoute(taskId: task.id)
    }, onSubtaskTap: { sub in
      subtaskDetailRoute = SubtaskDetailRoute(subtask: sub)
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
    .swipeActions(edge: .leading, allowsFullSwipe: true) {
      Button {
        HapticService.success()
        store.complete(task)
      } label: {
        Label("Concluir", systemImage: "checkmark")
      }
      .tint(AppColors.dateDueToday)
    }
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
      Button {
        HapticService.light()
        _Concurrency.Task { await store.postpone(task) }
      } label: {
        Label("Adiar", systemImage: "clock")
      }
      .tint(AppColors.priorityMedium)

      Button(role: .destructive) {
        HapticService.warning()
        store.delete(task)
      } label: {
        Label("Excluir", systemImage: "trash")
      }
    }
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
          VStack(spacing: 4) {
            Text(shortWeekday(day))
              .font(.system(size: 10, weight: .medium))
              .foregroundStyle(c.textTertiary)
            Text("\(Calendar.current.component(.day, from: day))")
              .font(.system(size: 16, weight: selected ? .bold : .semibold))
              .foregroundStyle(selected ? c.accent : (isToday ? c.textPrimary : c.textSecondary))
            Circle()
              .fill(hasTasks ? c.accent : Color.clear)
              .frame(width: 5, height: 5)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
          .background(selected ? c.surfaceVariant : Color.clear)
          .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.vertical, 4)
  }

  private func shortWeekday(_ date: Date) -> String {
    let weekday = Calendar.current.component(.weekday, from: date)
    let labels = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
    return labels[weekday - 1]
  }
}
