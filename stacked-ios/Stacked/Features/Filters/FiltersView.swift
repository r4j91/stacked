import SwiftUI

// Paridade lib/screens/filters_screen.dart
struct FiltersView: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var store = FiltersStore.shared
  @State private var detailRoute: TaskDetailRoute?
  @State private var subtaskDetailRoute: SubtaskDetailRoute?
  @State private var selectedProject: ProjectRoute?
  @Namespace private var taskDetailZoom

  var body: some View {
    NavigationStack {
      Group {
        switch store.mode {
        case .dashboard:
          dashboardView
            .transition(.opacity.combined(with: .move(edge: .leading)))
        case .filter(let kind):
          filterListView(kind: kind)
            .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
      }
      // SUBSTITUIDO_FASE2: .animation(.spring(response: 0.32, dampingFraction: 0.86), value: store.mode)
      .animation(AppMotion.smooth(reduceMotion: reduceMotion), value: store.mode)
      .task { await store.loadDashboard() }
      .navigationDestination(item: $selectedProject) { route in
        ProjectDetailView(
          projectId: route.id,
          projectName: route.name,
          projectColorHex: store.projects.first(where: { $0.id == route.id })?.colorHex
        )
        .environment(ThemeManager.shared)
      }
    }
    .stackedTabletCentered()
    .background(theme.colors.background.ignoresSafeArea(.all))
    .fullScreenCover(item: $detailRoute) { route in
      TaskDetailZoom.cover(route: route, namespace: taskDetailZoom) {
        TaskDetailView(taskId: route.taskId) {
          _Concurrency.Task {
            await store.loadDashboard()
            if case .filter(let kind) = store.mode {
              await store.openFilter(kind)
            }
          }
        }
        .environment(ThemeManager.shared)
      }
    }
    .sheet(item: $subtaskDetailRoute) { route in
      SubtaskDetailView(subtask: route.subtask) {
        _Concurrency.Task {
          await store.loadDashboard()
          if case .filter(let kind) = store.mode {
            await store.openFilter(kind)
          }
        }
      }
      .environment(ThemeManager.shared)
    }
  }

  private var dashboardView: some View {
    let c = theme.colors

    return List {
      Section {
        ScreenHeader(title: "Filtros")
          .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }

      if store.dashboardLoading {
        Section {
          ProgressView()
            .tint(c.accent)
            .frame(maxWidth: .infinity, minHeight: 120)
            .listRowBackground(Color.clear)
        }
      } else if let err = store.dashboardError, store.projects.isEmpty {
        Section {
          LoadErrorView(message: err) {
            _Concurrency.Task { await store.loadDashboard() }
          }
          .listRowBackground(Color.clear)
        }
      } else {
        Section {
          statGrid
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 12, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }

        Section {
          if store.projects.isEmpty {
            EmptyStateView(icon: .folder, title: "Nenhum projeto", subtitle: "Organize suas tarefas por contexto")
            .listRowBackground(Color.clear)
          } else {
            ForEach(store.projects) { project in
              Button {
                HapticService.selection()
                selectedProject = ProjectRoute(id: project.id, name: project.name)
              } label: {
                projectRow(project)
              }
              .buttonStyle(.plain)
              .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
              .listRowSeparator(.hidden)
              .listRowBackground(Color.clear)
            }
          }
        } header: {
          SectionLabel(text: "PROJETOS")
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
    .refreshable { await store.loadDashboard() }
  }

  private var statGrid: some View {
    VStack(spacing: 12) {
      HStack(spacing: 12) {
        statCard(
          icon: .exclamation,
          label: "Atrasadas",
          count: store.counts.overdue,
          colored: true,
          tint: AppColors.priorityHigh,
          kind: .overdue
        )
        statCard(
          icon: .navToday,
          label: "Hoje",
          count: store.counts.today,
          colored: false,
          tint: theme.colors.accent,
          kind: .today
        )
      }
      HStack(spacing: 12) {
        statCard(
          icon: .navUpcoming,
          label: "Próximos 7 dias",
          count: store.counts.week,
          colored: false,
          tint: theme.colors.accent,
          kind: .week
        )
        statCard(
          icon: .check,
          label: "Concluídas hoje",
          count: store.counts.completedToday,
          colored: false,
          tint: theme.colors.accent,
          kind: .completedToday
        )
      }
    }
  }

  private func statCard(
    icon: StackedIconKey,
    label: String,
    count: Int,
    colored: Bool,
    tint: Color,
    kind: TaskFilterKind
  ) -> some View {
    let c = theme.colors
    let hasCount = count > 0
    let countLabel = count == 1 ? "1 tarefa" : "\(count) tarefas"
    let iconColor = colored ? tint : c.textPrimary
    let iconBg = colored ? tint.opacity(0.14) : c.surfaceVariant.opacity(0.45)

    return Button {
      HapticService.selection()
      _Concurrency.Task { await store.openFilter(kind) }
    } label: {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          ZStack {
            RoundedRectangle(cornerRadius: 12)
              .fill(iconBg)
              .frame(width: 40, height: 40)
            StackedIcons.image(icon)
              .font(.system(size: 20))
              .foregroundStyle(iconColor)
          }
          Spacer()
          if hasCount {
            Text("\(count)")
              .font(.system(size: 12, weight: .bold))
              .foregroundStyle(colored ? tint : c.textTertiary)
              .padding(.horizontal, 9)
              .padding(.vertical, 4)
              .background(colored ? tint.opacity(0.16) : c.textTertiary.opacity(0.12))
              .clipShape(Capsule())
          }
        }
        Text(label)
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(c.textPrimary)
          .lineLimit(2)
          .multilineTextAlignment(.leading)
        Text(hasCount ? countLabel : "Nenhuma")
          .font(.system(size: 12))
          .foregroundStyle(c.textSecondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(14)
      .background(colored && hasCount ? tint.opacity(0.07) : c.surface)
      .clipShape(RoundedRectangle(cornerRadius: 14))
      .overlay(
        RoundedRectangle(cornerRadius: 14)
          .stroke(colored && hasCount ? tint.opacity(0.22) : c.textTertiary.opacity(0.1), lineWidth: 1)
      )
    }
    .buttonStyle(.plain)
  }

  private func filterListView(kind: TaskFilterKind) -> some View {
    let c = theme.colors
    let tint = kind == .overdue ? AppColors.priorityHigh : c.accent

    return List {
      Section {
        FilterDrillDownHeader(
          title: kind.title,
          taskCount: store.filterTasks.count,
          tint: tint,
          onBack: { store.backToDashboard() }
        )
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
      }

      if store.filterLoading {
        Section {
          ProgressView()
            .tint(c.accent)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        }
      } else if let err = store.filterError, store.filterTasks.isEmpty {
        Section {
          LoadErrorView(message: err) {
            _Concurrency.Task { await store.openFilter(kind) }
          }
          .listRowBackground(Color.clear)
        }
      } else if store.filterTasks.isEmpty {
        Section {
          EmptyStateView(icon: kind.stackedIcon, title: "Nenhuma tarefa", subtitle: "Nada neste filtro por enquanto.")
          .listRowBackground(Color.clear)
        }
      } else {
        Section {
          ForEach(store.filterTasks) { task in
            filterTaskRow(task, canPostpone: kind != .completedToday)
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
    .refreshable {
      await store.openFilter(kind)
      await store.loadDashboard()
    }
  }

  private func projectRow(_ project: ProjectTaskStats) -> some View {
    let c = theme.colors
    let color = AppColors.parseHex(project.colorHex, fallback: c.accent)
    let done = project.total - project.pending
    let progress = project.total > 0 ? Double(done) / Double(project.total) : 0

    return HStack(spacing: 16) {
      StackedIcons.image(.folder)
        .font(.system(size: 22))
        .foregroundStyle(color)
        .frame(width: 28, height: 28)

      VStack(alignment: .leading, spacing: 7) {
        Text(project.name)
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(c.textPrimary)
          .lineLimit(1)
        if project.total > 0 {
          GeometryReader { geo in
            ZStack(alignment: .leading) {
              Capsule().fill(c.textTertiary.opacity(0.12))
              Capsule().fill(color).frame(width: geo.size.width * progress)
            }
          }
          .frame(height: 3)
        }
      }

      Text("\(project.pending)")
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(c.textTertiary)

      StackedIcons.image(.chevronRight)
        .font(.system(size: 14))
        .foregroundStyle(c.textTertiary.opacity(0.7))
    }
    .padding(.vertical, 13)
  }

  private var rowInsets: EdgeInsets {
    EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
  }

  @ViewBuilder
  private func filterTaskRow(_ task: Task, canPostpone: Bool) -> some View {
    TaskRow(task: task, onToggle: {
      store.complete(task)
    }, onTap: {
      detailRoute = TaskDetailRoute(taskId: task.id)
    }, onSubtaskTap: { sub in
      subtaskDetailRoute = SubtaskDetailRoute(subtask: sub)
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
          if case .filter(let kind) = store.mode {
            await store.openFilter(kind)
          }
          await store.loadDashboard()
        }
      },
      onDelete: { store.delete(task) },
      onRefresh: {
        _Concurrency.Task {
          if case .filter(let kind) = store.mode {
            await store.openFilter(kind)
          }
          await store.loadDashboard()
        }
      }
    )
    .swipeActions(edge: .leading, allowsFullSwipe: true) {
      if !task.done {
        Button {
          HapticService.success()
          store.complete(task)
        } label: {
          Label("Concluir", systemImage: "checkmark")
        }
        .tint(AppColors.dateDueToday)
      }
    }
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
      if canPostpone {
        Button {
          HapticService.light()
          _Concurrency.Task { await store.postpone(task) }
        } label: {
          Label("Adiar", systemImage: "clock")
        }
        .tint(AppColors.priorityMedium)
      }

      Button(role: .destructive) {
        HapticService.warning()
        store.delete(task)
      } label: {
        Label("Excluir", systemImage: "trash")
      }
    }
  }
}
