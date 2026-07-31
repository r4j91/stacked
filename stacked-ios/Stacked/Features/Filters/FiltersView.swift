import SwiftUI
import Hugeicons

private struct SavedFilterRoute: Identifiable, Hashable {
  let filter: SavedFilter
  var id: String { filter.id }

  static func == (lhs: SavedFilterRoute, rhs: SavedFilterRoute) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

// Paridade lib/screens/filters_screen.dart
struct FiltersView: View {
  @Environment(ThemeManager.self) private var theme
  @Bindable private var store = FiltersStore.shared
  @State private var detailRoute: TaskDetailRoute?
  @State private var subtaskDetailRoute: SubtaskDetailRoute?
  @State private var selectedProject: ProjectRoute?
  @State private var presetFilterRoute: TaskFilterKind?
  @State private var savedFilterRoute: SavedFilterRoute?
  @Namespace private var taskDetailZoom
  @State private var showBuilder = false
  @State private var editingFilter: SavedFilter?
  @State private var showNewProject = false
  @AppStorage(HomeSectionStyleStorage.key) private var sectionStyleRaw = HomeSectionStyleStorage.defaultRawValue
  @AppStorage(AppTypeScaleStorage.key) private var typeScaleRaw = AppTypeScaleStorage.defaultRawValue

  private var sectionStyle: HomeSectionStyle {
    HomeSectionStyleStorage.style(from: sectionStyleRaw)
  }

  private var typeScale: AppTypeScale {
    AppTypeScaleStorage.scale(from: typeScaleRaw)
  }

  var body: some View {
    NavigationStack {
      dashboardView
        .navigationDestination(item: $selectedProject) { route in
          ProjectDetailView(
            projectId: route.id,
            projectName: route.name,
            projectColorHex: store.projects.first(where: { $0.id == route.id })?.colorHex,
            initialSnapshot: route.snapshot
          )
          .environment(ThemeManager.shared)
        }
        .navigationDestination(item: $presetFilterRoute) { kind in
          PresetFilterResultsScreen(
            kind: kind,
            taskDetailNamespace: taskDetailZoom,
            activeZoomTaskId: detailRoute?.taskId,
            onTaskTap: { detailRoute = TaskDetailRoute(task: $0) },
            onSubtaskTap: { subtaskDetailRoute = $0 }
          )
        }
        .navigationDestination(item: $savedFilterRoute) { route in
          SavedFilterResultsScreen(
            filter: route.filter,
            initialPending: store.cachedPendingResults(for: route.filter.id),
            initialCompleted: store.cachedCompletedResults(for: route.filter.id),
            taskDetailNamespace: taskDetailZoom,
            activeZoomTaskId: detailRoute?.taskId,
            onTaskTap: { detailRoute = TaskDetailRoute(task: $0) },
            onSubtaskTap: { subtaskDetailRoute = $0 },
            onEditFilter: { filter in
              editingFilter = filter
              showBuilder = true
            }
          )
        }
    }
    .tint(theme.colors.textSecondary)
    .background(theme.colors.background.ignoresSafeArea(.all))
    .newProjectFloating(isPresented: $showNewProject) {
      _Concurrency.Task { await store.loadDashboard() }
    }
    .taskDetailCover(item: $detailRoute, namespace: taskDetailZoom, onDismiss: {
      _Concurrency.Task {
        await store.loadDashboard()
        if case .presetFilter(let kind) = store.mode {
          await store.openFilter(kind)
        } else if case .savedFilter(let filter) = store.mode {
          await store.openSavedFilter(filter)
        }
      }
    }) { route in
      TaskDetailView(taskId: route.taskId, seed: route.seed)
        .environment(ThemeManager.shared)
    }
    .sheet(item: $subtaskDetailRoute) { route in
      SubtaskDetailView(subtask: route.subtask, parentTaskId: route.parentTaskId) { snapshot in
        await SubtaskSaveHandler.handle(snapshot, patch: store.applySubtaskPatch) {
          await store.loadDashboard()
          if case .presetFilter(let kind) = store.mode {
            await store.openFilter(kind)
          } else if case .savedFilter(let filter) = store.mode {
            await store.openSavedFilter(filter)
          }
        }
      }
      .environment(ThemeManager.shared)
    }
    .sheet(isPresented: $showBuilder) {
      SavedFilterBuilderView(existing: editingFilter) {
        editingFilter = nil
        await store.loadDashboard()
      }
      .environment(ThemeManager.shared)
    }
    .onChange(of: showBuilder) { _, open in
      if !open { editingFilter = nil }
    }
    .onChange(of: presetFilterRoute) { _, route in
      if route == nil, case .presetFilter = store.mode {
        deferDashboardReset()
      }
    }
    .onChange(of: savedFilterRoute) { _, route in
      if route == nil, case .savedFilter = store.mode {
        deferDashboardReset()
      }
    }
    .onAppear { consumePendingPresetNavigation() }
    .onChange(of: store.pendingPresetFilterToken) { _, _ in
      consumePendingPresetNavigation()
    }
  }

  /// Paridade lib/main.dart `_deliverPendingFilter` — Home pode pedir drill-down
  /// com a aba Filtros já visitada; onAppear sozinho não dispara de novo.
  private func consumePendingPresetNavigation() {
    guard let kind = store.takePendingPresetFilter() else { return }
    store.preparePresetFilterSession(kind)
    presetFilterRoute = kind
    _Concurrency.Task {
      await store.openFilter(kind)
    }
  }

  private func openPresetFilter(_ kind: TaskFilterKind) {
    HapticService.selection()
    store.preparePresetFilterSession(kind)
    presetFilterRoute = kind
    _Concurrency.Task {
      await store.openFilter(kind)
    }
  }

  private func openSavedFilter(_ filter: SavedFilter) {
    HapticService.selection()
    savedFilterRoute = SavedFilterRoute(filter: filter)
  }

  /// Limpa estado do drill-down após o pop do NavigationStack — evita re-layout da lista durante a animação.
  private func deferDashboardReset() {
    _Concurrency.Task {
      await NavigationPushMotion.awaitSettle()
      guard presetFilterRoute == nil, savedFilterRoute == nil else { return }
      if case .dashboard = store.mode { return }
      await NavigationPushMotion.afterSettle {
        store.backToDashboard()
      }
    }
  }

  private var filtersListRowInsets: EdgeInsets {
    sectionStyle.metrics.rowInsets
  }

  private var dashboardView: some View {
    let c = theme.colors

    return List {
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
          presetNavRow(
            icon: .exclamation,
            label: "Atrasadas",
            count: store.counts.overdue,
            tint: AppColors.priorityHigh,
            kind: .overdue,
            position: .first
          )
          presetNavRow(
            icon: .navToday,
            label: "Hoje",
            count: store.counts.today,
            tint: nil,
            kind: .today,
            position: .middle
          )
          presetNavRow(
            icon: .navUpcoming,
            label: "Próximos 7 dias",
            count: store.counts.week,
            tint: nil,
            kind: .week,
            position: .middle
          )
          presetNavRow(
            icon: .check,
            label: "Concluídas hoje",
            count: store.counts.completedToday,
            tint: nil,
            kind: .completedToday,
            position: .last
          )
        }

        Section {
          ForEach(Array(store.savedFilters.enumerated()), id: \.element.id) { index, item in
            Button {
              openSavedFilter(item.filter)
            } label: {
              savedFilterRow(item)
            }
            .buttonStyle(PressableStyle(cornerRadius: AppSpacing.md))
            .listRowInsets(filtersListRowInsets)
            .listRowSeparator(.hidden)
            .listRowBackground(
              HomeSectionRowBackground(
                style: sectionStyle,
                position: .at(index: index, count: store.savedFilters.count),
                colors: c
              )
            )
          }
        } header: {
          savedFiltersHeader
            .textCase(nil)
            .homeSectionHeaderInsets(sectionStyle)
        }

        Section {
          if store.projects.isEmpty {
            VStack(spacing: AppSpacing.md) {
              EmptyStateView(icon: .folder, title: "Nenhum projeto", subtitle: "Organize suas tarefas por contexto")
              Button("Criar projeto") { showNewProject = true }
                .font(AppTypography.bodySemibold)
                .foregroundStyle(theme.colors.accent)
            }
            .stackedListEmptyStateRow()
          } else {
            ForEach(Array(store.projects.enumerated()), id: \.element.id) { index, project in
              Button {
                HapticService.selection()
                let projectId = project.id
                ProjectDetailCache.shared.prefetch(projectId: projectId)
                selectedProject = ProjectRoute(
                  id: projectId,
                  name: project.name,
                  snapshot: ProjectDetailCache.shared.snapshot(for: projectId)
                )
              } label: {
                projectRow(project)
              }
              .buttonStyle(PressableStyle(cornerRadius: AppSpacing.md))
              .listRowInsets(filtersListRowInsets)
              .listRowSeparator(.hidden)
              .listRowBackground(
                HomeSectionRowBackground(
                  style: sectionStyle,
                  position: .at(index: index, count: store.projects.count),
                  colors: c
                )
              )
            }
          }
        } header: {
          projectsHeader
            .textCase(nil)
            .homeSectionHeaderInsets(sectionStyle)
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
    .stackedDashboardListChrome()
    .stackedTabletCentered()
    .background(c.background)
    .navigationTitle("Filtros")
    .navigationBarTitleDisplayMode(.inline)
    .toolbarBackground(.hidden, for: .navigationBar)
    .refreshable { await store.loadDashboard() }
  }

  /// Dense preset row — same vocabulary as Home `navRow`.
  private func presetNavRow(
    icon: StackedIconKey,
    label: String,
    count: Int,
    tint: Color?,
    kind: TaskFilterKind,
    position: HomeSectionRowPosition
  ) -> some View {
    let c = theme.colors
    let t = typeScale.metrics
    let iconColor = tint ?? c.textSecondary
    return Button {
      openPresetFilter(kind)
    } label: {
      HStack(spacing: HomeSectionRowLayout.iconSpacing) {
        StackedIcons.image(icon)
          .font(.system(size: 20))
          .foregroundStyle(iconColor)
          .frame(width: HomeSectionRowLayout.iconWidth)
        Text(label)
          .font(t.rowTitleFont)
          .foregroundStyle(c.textPrimary)
        Spacer()
        Text("\(count)")
          .font(t.rowCountFont)
          .foregroundStyle(tint ?? c.textTertiary)
        DisclosureChevron(color: c.textTertiary.opacity(0.7))
      }
      .padding(.vertical, sectionStyle.metrics.rowPaddingV)
    }
    .buttonStyle(PressableStyle(cornerRadius: AppSpacing.md))
    .listRowInsets(filtersListRowInsets)
    .listRowSeparator(.hidden)
    .listRowBackground(
      HomeSectionRowBackground(style: sectionStyle, position: position, colors: c)
    )
  }

  private var savedFiltersHeader: some View {
    let c = theme.colors
    return VStack(alignment: .leading, spacing: 6) {
      HomeSectionHeader(text: "Meus filtros", style: sectionStyle, scale: typeScale) {
        Button {
          HapticService.selection()
          editingFilter = nil
          showBuilder = true
        } label: {
          StackedIcons.image(.plus)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(c.accent)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Criar filtro")
      }

      if store.savedFilters.isEmpty {
        Text("Crie filtros para ver tarefas por etiqueta ou prioridade.")
          .font(AppTypography.meta)
          .foregroundStyle(c.textTertiary)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }

  private func savedFilterRow(_ item: SavedFilterWithCount) -> some View {
    let c = theme.colors
    let t = typeScale.metrics
    let tint = AppColors.parseHex(item.filter.colorHex, fallback: c.accent)
    return HStack(spacing: HomeSectionRowLayout.iconSpacing) {
      StackedIcons.image(.navFilters)
        .font(.system(size: 20))
        .foregroundStyle(tint)
        .frame(width: HomeSectionRowLayout.iconWidth)

      VStack(alignment: .leading, spacing: 2) {
        Text(item.filter.name)
          .font(t.rowTitleFont)
          .foregroundStyle(c.textPrimary)
          .lineLimit(1)
        Text(FilterCriteriaSummary.text(item.filter.criteria, labels: store.pickerLabels, projects: store.pickerProjects))
          .font(AppTypography.meta)
          .foregroundStyle(c.textTertiary)
          .lineLimit(1)
      }
      Spacer(minLength: 8)
      Text("\(item.pendingCount)")
        .font(t.rowCountFont)
        .foregroundStyle(c.textTertiary)
      DisclosureChevron(color: c.textTertiary.opacity(0.7))
    }
    .padding(.vertical, sectionStyle.metrics.rowPaddingV)
    .contentShape(Rectangle())
  }

  private var projectsHeader: some View {
    let c = theme.colors
    return VStack(alignment: .leading, spacing: 6) {
      HomeSectionHeader(text: "Projetos", style: sectionStyle, scale: typeScale)

      if store.projects.isEmpty {
        Text("Crie projetos na aba Navegar para acompanhar o progresso aqui.")
          .font(AppTypography.meta)
          .foregroundStyle(c.textTertiary)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }

  private func projectStatusLine(_ project: ProjectTaskStats) -> String {
    if project.total == 0 {
      return "Sem tarefas"
    }
    let done = project.total - project.pending
    if project.pending == 0 {
      return "Tudo concluído · \(project.total) no total"
    }
    let pendingLabel = project.pending == 1 ? "1 pendente" : "\(project.pending) pendentes"
    let doneLabel = done == 1 ? "1 concluída" : "\(done) concluídas"
    return "\(pendingLabel) · \(doneLabel)"
  }

  private func projectRow(_ project: ProjectTaskStats) -> some View {
    let c = theme.colors
    let t = typeScale.metrics
    let color = AppColors.parseHex(project.colorHex, fallback: c.folderTint)
    let done = project.total - project.pending
    let progress = project.total > 0 ? Double(done) / Double(project.total) : 0

    return HStack(spacing: HomeSectionRowLayout.iconSpacing) {
      StackedIcons.image(ProjectIcons.asset(for: project.iconKey))
        .font(.system(size: 20))
        .foregroundStyle(color)
        .frame(width: HomeSectionRowLayout.iconWidth)

      VStack(alignment: .leading, spacing: 5) {
        Text(project.name)
          .font(t.rowTitleFont)
          .foregroundStyle(c.textPrimary)
          .lineLimit(1)

        Text(projectStatusLine(project))
          .font(AppTypography.meta)
          .foregroundStyle(c.textTertiary)
          .lineLimit(1)

        if project.total > 0 {
          projectProgressBar(progress: progress, color: color)
        }
      }

      Spacer(minLength: 8)

      Text("\(project.pending)")
        .font(t.rowCountFont)
        .foregroundStyle(project.pending > 0 ? c.textSecondary : c.textTertiary)

      DisclosureChevron(color: c.textTertiary.opacity(0.7))
    }
    .padding(.vertical, sectionStyle.metrics.rowPaddingV)
    .contentShape(Rectangle())
  }

  private func projectProgressBar(progress: Double, color: Color) -> some View {
    let c = theme.colors
    return ZStack(alignment: .leading) {
      Capsule()
        .fill(c.textTertiary.opacity(0.12))
      Capsule()
        .fill(color)
        .scaleEffect(x: max(progress, progress > 0 ? 0.04 : 0), y: 1, anchor: .leading)
    }
    .frame(height: 3)
    .clipShape(Capsule())
  }
}
