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
  @State private var showNotifications = false
  @State private var projectOptions: ProjectRoute?
  @AppStorage(HomeHeroStyleStorage.key) private var homeHeroStyleRaw = HomeHeroStyleStorage.defaultRawValue

  private var homeHeroStyle: HomeHeroStyle {
    HomeHeroStyleStorage.style(from: homeHeroStyleRaw)
  }

  private var homeListRowInsets: EdgeInsets {
    EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.xl, bottom: AppSpacing.xs, trailing: AppSpacing.xl)
  }

  var body: some View {
    let c = theme.colors

    NavigationStack {
      List {
        HomeHeroSection(
          style: homeHeroStyle,
          store: store,
          onOpenFilter: onOpenFilter,
          onRetry: { _Concurrency.Task { await store.load() } }
        )
        overviewSection
        projectsSection

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
      .navigationTitle("")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(.hidden, for: .navigationBar)
      .toolbar {
        HomeHeaderToolbar(
          showProductivity: $showProductivity,
          showNotifications: $showNotifications,
          showSettings: $showSettings
        )
      }
      .refreshable { await store.load() }
      .task {
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
      .navigationDestination(item: $selectedProject) { route in
        ProjectDetailView(
          projectId: route.id,
          projectName: route.name,
          projectColorHex: store.projects.first(where: { $0.id == route.id })?.colorHex,
          initialSnapshot: route.snapshot
        )
        .environment(ThemeManager.shared)
      }
    }
    .toolbarBackground(.hidden, for: .navigationBar)
    .background(c.background.ignoresSafeArea(.all))
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
    _Concurrency.Task { await store.refreshCounts() }
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

  private var overviewSection: some View {
    Section {
      navRow(icon: .navInbox, label: "Inbox", count: store.inboxCount, tab: .inbox)
      navRow(icon: .navToday, label: "Hoje", count: store.todayPending, tab: .today)
      navRow(icon: .navUpcoming, label: "Em breve", count: store.upcomingCount, tab: .upcoming)
    } header: {
      ListSectionHeader(text: "VISÃO GERAL")
    }
  }

  private var projectsSection: some View {
    Section {
      if store.projects.isEmpty {
        VStack(spacing: AppSpacing.md) {
          EmptyStateView(icon: .folder, title: "Nenhum projeto ainda", subtitle: "Organize suas tarefas por contexto")
          Button("Criar projeto") { showNewProject = true }
            .font(AppTypography.bodySemibold)
            .foregroundStyle(theme.colors.accent)
        }
        .stackedListEmptyStateRow()
      } else {
        ForEach(store.projects) { project in
          Button {
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
          .contextMenu {
            Button("Opções do projeto") {
              projectOptions = ProjectRoute(id: project.id, name: project.name)
            }
          }
          .listRowInsets(homeListRowInsets)
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
        }
      }
    } header: {
      ListSectionHeader(text: "PROJETOS")
    }
  }

  private func navRow(icon: StackedIconKey, label: String, count: Int, tab: NavTab) -> some View {
    let c = theme.colors
    return Button { onNavigateToTab(tab) } label: {
      HStack(spacing: AppSpacing.md + 2) {
        StackedIcons.image(icon).font(.system(size: 20)).foregroundStyle(c.textSecondary).frame(width: 28)
        Text(label).font(AppTypography.navRowTitle).foregroundStyle(c.textPrimary)
        Spacer()
        Text("\(count)").font(AppTypography.navRowCount).foregroundStyle(c.textTertiary)
        DisclosureChevron(color: c.textTertiary.opacity(0.7))
      }
      .padding(.vertical, AppSpacing.sm + 2)
    }
    .buttonStyle(PressableStyle(cornerRadius: AppSpacing.md))
    .listRowInsets(homeListRowInsets)
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
  }

  private func projectRow(_ project: HomeProject) -> some View {
    let c = theme.colors
    let color = AppColors.parseHex(project.colorHex, fallback: theme.colors.folderTint)
    return HStack(spacing: AppSpacing.md + 2) {
      StackedIcons.image(ProjectIcons.asset(for: project.iconKey))
        .font(.system(size: 20)).foregroundStyle(color).frame(width: 28)
      Text(project.name).font(AppTypography.navRowTitle).foregroundStyle(c.textPrimary)
      Spacer()
      Text("\(project.taskCount)").font(AppTypography.navRowCount).foregroundStyle(c.textTertiary)
      DisclosureChevron(color: c.textTertiary.opacity(0.7))
    }
    .padding(.vertical, AppSpacing.sm + 2)
  }
}
