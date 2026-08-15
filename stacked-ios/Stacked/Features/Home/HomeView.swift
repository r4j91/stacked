import SwiftUI

// Paridade lib/screens/home_screen.dart
struct HomeView: View {
  @Environment(ThemeManager.self) private var theme
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.isTabActive) private var isTabActive
  var onNavigateToTab: (NavTab) -> Void
  var onOpenFilter: (TaskFilterKind) -> Void

  @State private var store = HomeStore.shared
  @State private var selectedProject: ProjectRoute?
  @State private var showNewProject = false
  @State private var showSettings = false
  @State private var showProductivity = false
  @State private var showProfile = false
  @State private var showNotifications = false
  @State private var showSearch = false
  @State private var showLabels = false
  @State private var showNotes = false
  @State private var showMoney = false
  @State private var projectOptions: ProjectRoute?
  @State private var projectsEditMode: EditMode = .inactive
  @State private var router = AppNavigationRouter.shared
  @AppStorage(HomeHeroStyleStorage.key) private var homeHeroStyleRaw = HomeHeroStyleStorage.defaultRawValue
  @AppStorage(HomeTopCardStorage.key) private var topCardEnabled = HomeTopCardStorage.defaultEnabled

  private var homeHeroStyle: HomeHeroStyle {
    HomeHeroStyleStorage.style(from: homeHeroStyleRaw)
  }

  var body: some View {
    let c = theme.colors

    NavigationStack {
      List {
        if topCardEnabled {
          HomeHeroSection(
            style: homeHeroStyle,
            store: store,
            onOpenFilter: onOpenFilter,
            onRetry: { _Concurrency.Task { await store.load() } }
          )
        } else {
          HomeUtilitySection(
            onOpenSearch: { showSearch = true },
            onOpenReports: { showProductivity = true },
            onOpenFilters: { onNavigateToTab(.filters) },
            onOpenLabels: { showLabels = true },
            onOpenNotes: { showNotes = true }
          )
        }
        HomeOverviewSection(onNavigateToTab: onNavigateToTab, onOpenFilter: onOpenFilter)
        HomeMoneySection(onOpen: { showMoney = true })
        HomeProjectsSection(
          selectedProject: $selectedProject,
          showNewProject: $showNewProject,
          projectOptions: $projectOptions,
          projectsEditMode: $projectsEditMode
        )

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
      .stackedThemeBackground(theme)
      .environment(\.editMode, $projectsEditMode)
      .navigationTitle("")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(.hidden, for: .navigationBar)
      .toolbar {
        HomeHeaderToolbar(
          showProductivity: $showProductivity,
          showProfile: $showProfile,
          showNotifications: $showNotifications,
          showSettings: $showSettings,
          showSearch: $showSearch
        )
      }
      .refreshable {
        await store.load()
        await MoneyStore.shared.load()
      }
      .task {
        store.hydrateFromDisk()
        store.refreshTemporal()
        await NotificationService.shared.prefetchPreview()
        await store.refreshWeatherIfNeeded()
      }
      .onChange(of: isTabActive) { _, active in
        guard active else { return }
        refreshHomeOnFocus(reloadCounts: true)
      }
      .onChange(of: scenePhase) { _, phase in
        guard phase == .active, isTabActive else { return }
        // Contagens já vão pelo RootView; aqui só o “agora” do hero.
        store.refreshTemporal()
      }
      .onChange(of: router.pendingOpenNotes) { _, open in
        guard open else { return }
        showNotes = true
        _ = router.consumeNotes()
      }
      .onAppear {
        if router.consumeNotes() {
          showNotes = true
        }
      }
      .navigationDestination(item: $selectedProject) { route in
        ProjectDetailView(
          projectId: route.id,
          projectName: route.name,
          projectColorHex: store.projects.first(where: { $0.id == route.id })?.colorHex,
          initialSnapshot: route.snapshot
        )
        .environment(ThemeManager.shared)
      }
      .navigationDestination(isPresented: $showLabels) {
        LabelsManagementView().environment(ThemeManager.shared)
      }
      .navigationDestination(isPresented: $showNotes) {
        NotesBoardView().environment(ThemeManager.shared)
      }
      .navigationDestination(isPresented: $showMoney) {
        MoneyView().environment(ThemeManager.shared)
      }
    }
    .toolbarBackground(.hidden, for: .navigationBar)
    .stackedThemeBackground(theme)
    .newProjectFloating(isPresented: $showNewProject) {
      _Concurrency.Task { await store.load() }
    }
    .sheet(isPresented: $showSettings) {
      SettingsView().environment(ThemeManager.shared)
        .presentationDetents([.large]).presentationDragIndicator(.visible)
    }
    .sheet(isPresented: $showProductivity) {
      ProductivityView().environment(ThemeManager.shared)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
    .sheet(isPresented: $showProfile) {
      NavigationStack {
        ProfileEditView().environment(ThemeManager.shared)
      }
      .presentationDetents([.large])
      .presentationDragIndicator(.visible)
    }
    .sheet(isPresented: $showSearch) {
      SearchView().environment(ThemeManager.shared)
    }
    .sheet(isPresented: $showNotifications) {
      NotificationsPreviewSheet().environment(ThemeManager.shared)
        .presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
    }
    .sheet(item: $projectOptions) { route in
      ProjectOptionsSheet(
        project: projectModel(for: route),
        onEdited: { _Concurrency.Task { await store.load() } },
        onDeleted: {
          projectOptions = nil
          selectedProject = nil
          _Concurrency.Task { await store.load() }
        }
      )
      .environment(ThemeManager.shared)
      .presentationDetents([.medium, .large])
      .stackedEditableSheetPresentation(background: theme.colors.background)
    }
  }

  /// Volta à aba Home: atualiza relógio/trilho e reforça contagens do status.
  private func refreshHomeOnFocus(reloadCounts: Bool) {
    store.refreshTemporal()
    guard reloadCounts else { return }
    _Concurrency.Task {
      await store.refreshCounts()
      await MoneyStore.shared.load()
    }
  }

  private func projectModel(for route: ProjectRoute) -> Project {
    if let hp = store.projects.first(where: { $0.id == route.id }) {
      return Project(
        id: hp.id,
        name: hp.name,
        color: AppColors.parseHex(hp.colorHex, fallback: theme.colors.folderTint)
      )
    }
    // SUBSTITUIDO_TEMAS_JADE: color: theme.colors.accent
    return Project(id: route.id, name: route.name, color: theme.colors.folderTint)
  }
}

// MARK: - Overview (counts only — isolated from hero loading)

private struct HomeOverviewSection: View {
  @Environment(ThemeManager.self) private var theme
  @State private var store = HomeStore.shared
  var onNavigateToTab: (NavTab) -> Void
  var onOpenFilter: (TaskFilterKind) -> Void
  @AppStorage(HomeSectionStyleStorage.key) private var sectionStyleRaw = HomeSectionStyleStorage.defaultRawValue
  @AppStorage(AppTypeScaleStorage.key) private var typeScaleRaw = AppTypeScaleStorage.defaultRawValue
  @AppStorage(HomeTopCardStorage.key) private var topCardEnabled = HomeTopCardStorage.defaultEnabled

  private var sectionStyle: HomeSectionStyle {
    HomeSectionStyleStorage.style(from: sectionStyleRaw)
  }

  private var typeScale: AppTypeScale {
    AppTypeScaleStorage.scale(from: typeScaleRaw)
  }

  private struct OverviewEntry {
    let icon: StackedIconKey
    let label: String
    let count: Int
    /// Atrasadas puxam a cor de alerta; as demais ficam no cinza de sempre.
    var isAlert: Bool = false
    let action: () -> Void
  }

  /// Com o card de saudação ligado é ele quem avisa das atrasadas — aqui a linha
  /// só entra quando o card está desligado, senão o aviso apareceria duas vezes.
  private var showsOverdue: Bool {
    !topCardEnabled && store.overdueCount > 0
  }

  private var entries: [OverviewEntry] {
    var rows: [OverviewEntry] = []
    if showsOverdue {
      rows.append(
        OverviewEntry(
          icon: .clock,
          label: "Atrasadas",
          count: store.overdueCount,
          isAlert: true,
          action: { onOpenFilter(.overdue) }
        )
      )
    }
    rows.append(
      OverviewEntry(icon: .navInbox, label: "Inbox", count: store.inboxCount) {
        onNavigateToTab(.inbox)
      }
    )
    rows.append(
      OverviewEntry(icon: .navToday, label: "Hoje", count: store.todayPending) {
        onNavigateToTab(.today)
      }
    )
    rows.append(
      OverviewEntry(icon: .navUpcoming, label: "Em breve", count: store.upcomingCount) {
        onNavigateToTab(.upcoming)
      }
    )
    return rows
  }

  var body: some View {
    let rows = entries
    let showsError = store.error != nil
    let offset = showsError ? 1 : 0
    let total = rows.count + offset

    Section {
      if showsError {
        errorRow(position: .at(index: 0, count: total))
      }
      ForEach(Array(rows.enumerated()), id: \.element.label) { index, entry in
        navRow(entry, position: .at(index: index + offset, count: total))
      }
    } header: {
      HomeSectionHeader(text: "VISÃO GERAL", style: sectionStyle, scale: typeScale)
        .homeSectionHeaderInsets(sectionStyle)
    }
  }

  /// Sync falhou: sem isto a Home mostraria os números velhos como se fossem atuais.
  private func errorRow(position: HomeSectionRowPosition) -> some View {
    let c = theme.colors
    let t = typeScale.metrics
    let m = sectionStyle.metrics
    return HStack(spacing: HomeSectionRowLayout.iconSpacing) {
      StackedIcons.image(.exclamation)
        .font(.system(size: 20))
        .foregroundStyle(AppColors.overdue)
        .frame(width: HomeSectionRowLayout.iconWidth)
      Text("Não foi possível atualizar")
        .font(t.rowTitleFont)
        .foregroundStyle(c.textPrimary)
        .lineLimit(1)
        .layoutPriority(1)
      Spacer(minLength: 8)
      Button("Tentar de novo") {
        HapticService.selection()
        _Concurrency.Task { await store.load() }
      }
      .font(t.actionFont)
      .foregroundStyle(c.accent)
      .buttonStyle(.plain)
    }
    .padding(.vertical, m.rowPaddingV)
    .listRowInsets(m.rowInsets)
    .listRowSeparator(.hidden)
    .listRowBackground(
      HomeSectionRowBackground(style: sectionStyle, position: position, colors: c)
    )
  }

  private func navRow(_ entry: OverviewEntry, position: HomeSectionRowPosition) -> some View {
    let c = theme.colors
    let t = typeScale.metrics
    let m = sectionStyle.metrics
    return Button(action: entry.action) {
      HStack(spacing: HomeSectionRowLayout.iconSpacing) {
        StackedIcons.image(entry.icon)
          .font(.system(size: 20))
          .foregroundStyle(entry.isAlert ? AppColors.overdue : c.textSecondary)
          .frame(width: HomeSectionRowLayout.iconWidth)
        Text(entry.label)
          .font(t.rowTitleFont)
          .fontWeight(entry.isAlert ? .semibold : nil)
          .foregroundStyle(entry.isAlert ? AppColors.overdue : c.textPrimary)
        Spacer()
        countLabel(entry, t: t, c: c)
        DisclosureChevron(
          color: entry.isAlert ? AppColors.overdue : c.textSecondary
        )
      }
      .padding(.vertical, m.rowPaddingV)
    }
    .buttonStyle(PressableStyle(cornerRadius: AppSpacing.md))
    .listRowInsets(m.rowInsets)
    .listRowSeparator(.hidden)
    .listRowBackground(
      HomeSectionRowBackground(style: sectionStyle, position: position, colors: c)
    )
  }

  /// Zero não é informação: a ausência do número já diz que não há nada ali.
  /// Na carga fria o lugar fica reservado para o número não pular na chegada.
  @ViewBuilder
  private func countLabel(_ entry: OverviewEntry, t: AppTypeScaleMetrics, c: AppThemeColors) -> some View {
    if store.isLoading {
      Text("00")
        .font(t.rowCountFont)
        .monospacedDigit()
        .foregroundStyle(c.textSecondary)
        .redacted(reason: .placeholder)
    } else if entry.count > 0 {
      Text("\(entry.count)")
        .font(t.rowCountFont)
        .monospacedDigit()
        .fontWeight(entry.isAlert ? .semibold : nil)
        .foregroundStyle(entry.isAlert ? AppColors.overdue : c.textSecondary)
    }
  }
}

// MARK: - Projects (projects array only — isolated from hero loading)

private struct HomeProjectsSection: View {
  @Environment(ThemeManager.self) private var theme
  @State private var store = HomeStore.shared
  @Binding var selectedProject: ProjectRoute?
  @Binding var showNewProject: Bool
  @Binding var projectOptions: ProjectRoute?
  @Binding var projectsEditMode: EditMode
  @AppStorage(HomeSectionStyleStorage.key) private var sectionStyleRaw = HomeSectionStyleStorage.defaultRawValue
  @AppStorage(AppTypeScaleStorage.key) private var typeScaleRaw = AppTypeScaleStorage.defaultRawValue

  private var sectionStyle: HomeSectionStyle {
    HomeSectionStyleStorage.style(from: sectionStyleRaw)
  }

  private var typeScale: AppTypeScale {
    AppTypeScaleStorage.scale(from: typeScaleRaw)
  }

  var body: some View {
    let c = theme.colors
    let editing = projectsEditMode == .active
    let m = sectionStyle.metrics

    Section {
      if store.projects.isEmpty, store.isLoading {
        // Carga fria: sem isto o empty state "Nenhum projeto ainda" pisca antes dos dados.
        ForEach(Array(Self.skeletonWidths.enumerated()), id: \.offset) { index, placeholder in
          projectSkeletonRow(placeholder: placeholder)
            .listRowInsets(m.rowInsets)
            .listRowSeparator(.hidden)
            .listRowBackground(
              HomeSectionRowBackground(
                style: sectionStyle,
                position: .at(index: index, count: Self.skeletonWidths.count),
                colors: c
              )
            )
        }
      } else if store.projects.isEmpty {
        VStack(spacing: AppSpacing.md) {
          EmptyStateView(illustration: .projectsEmpty, title: "Nenhum projeto ainda", subtitle: "Organize suas tarefas por contexto")
          Button("Criar projeto") { showNewProject = true }
            .font(AppTypography.bodySemibold)
            .foregroundStyle(c.accent)
        }
        .stackedListEmptyStateRow()
      } else {
        ForEach(Array(store.projects.enumerated()), id: \.element.id) { index, project in
          Group {
            if editing {
              projectRow(project, showChevron: false)
            } else {
              Button {
                let projectId = project.id
                ProjectDetailCache.shared.prefetch(projectId: projectId)
                selectedProject = ProjectRoute(
                  id: projectId,
                  name: project.name,
                  snapshot: ProjectDetailCache.shared.snapshot(for: projectId)
                )
              } label: {
                projectRow(project, showChevron: true)
              }
              .buttonStyle(PressableStyle(cornerRadius: AppSpacing.md))
              .contextMenu {
                Button("Opções do projeto") {
                  projectOptions = ProjectRoute(id: project.id, name: project.name)
                }
              }
            }
          }
          .listRowInsets(m.rowInsets)
          .listRowSeparator(.hidden)
          .listRowBackground(
            HomeSectionRowBackground(
              style: sectionStyle,
              position: .at(index: index, count: store.projects.count),
              colors: c,
              editing: editing
            )
          )
        }
        .onMove(perform: store.reorderProjects)
      }
    } header: {
      HomeSectionHeader(text: "PROJETOS", style: sectionStyle, scale: typeScale) {
        if store.projects.count >= 2 {
          Button(editing ? "Concluir" : "Editar") {
            HapticService.selection()
            projectsEditMode = editing ? .inactive : .active
          }
          .font(typeScale.metrics.actionFont)
          .foregroundStyle(c.accent)
          .textCase(nil)
          .buttonStyle(.plain)
        }
      }
      .homeSectionHeaderInsets(sectionStyle)
    }
  }

  private func projectRow(_ project: HomeProject, showChevron: Bool = true) -> some View {
    let c = theme.colors
    let color = AppColors.parseHex(project.colorHex, fallback: theme.colors.folderTint)
    let t = typeScale.metrics
    return HStack(spacing: HomeSectionRowLayout.iconSpacing) {
      StackedIcons.image(ProjectIcons.asset(for: project.iconKey))
        .font(.system(size: 20))
        .foregroundStyle(color)
        .frame(width: HomeSectionRowLayout.iconWidth)
      Text(project.name)
        .font(t.rowTitleFont)
        .foregroundStyle(c.textPrimary)
        .lineLimit(1)
        .truncationMode(.tail)
        .layoutPriority(1)
      Spacer(minLength: 8)
      if project.taskCount > 0 {
        Text("\(project.taskCount)")
          .font(t.rowCountFont)
          .monospacedDigit()
          .foregroundStyle(c.textSecondary)
      }
      if showChevron {
        DisclosureChevron(color: c.textSecondary)
      }
    }
    .padding(.vertical, sectionStyle.metrics.rowPaddingV)
  }

  /// Larguras diferentes para o esqueleto não virar três barras iguais.
  private static let skeletonWidths = ["Trabalho", "Casa e rotina", "Estudos"]

  private func projectSkeletonRow(placeholder: String) -> some View {
    let c = theme.colors
    let t = typeScale.metrics
    return HStack(spacing: HomeSectionRowLayout.iconSpacing) {
      StackedIcons.image(ProjectIcons.asset(for: nil))
        .font(.system(size: 20))
        .foregroundStyle(c.textSecondary)
        .frame(width: HomeSectionRowLayout.iconWidth)
      Text(placeholder).font(t.rowTitleFont).foregroundStyle(c.textPrimary)
      Spacer()
    }
    .padding(.vertical, sectionStyle.metrics.rowPaddingV)
    .redacted(reason: .placeholder)
    .accessibilityHidden(true)
  }
}
