import SwiftUI

// Paridade lib/screens/home_screen.dart
struct HomeView: View {
  @Environment(ThemeManager.self) private var theme
  var onNavigateToTab: (NavTab) -> Void

  @State private var store = HomeStore.shared
  @State private var selectedProject: ProjectRoute?
  @State private var showNewProject = false
  @State private var showSettings = false
  @State private var showProductivity = false
  @State private var showNotifications = false
  @State private var projectOptions: ProjectRoute?

  var body: some View {
    let c = theme.colors

    NavigationStack {
      List {
        greetingTextSection
        statusSection
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
      .stackedListTailInset()
      .safeAreaPadding(.top, AppLayout.headerControlSize + 14)
      .overlay(alignment: .top) {
        HomeHeaderBar(
          showProductivity: $showProductivity,
          showNotifications: $showNotifications,
          showSettings: $showSettings
        )
      }
      .background(c.background)
      .refreshable { await store.load() }
      .task { await store.load() }
      .navigationDestination(item: $selectedProject) { route in
        ProjectDetailView(
          projectId: route.id,
          projectName: route.name,
          projectColorHex: store.projects.first(where: { $0.id == route.id })?.colorHex
        )
        .environment(ThemeManager.shared)
      }
    }
    .sheet(isPresented: $showNewProject) {
      NewProjectSheetView(onCreated: { _Concurrency.Task { await store.load() } })
        .environment(ThemeManager.shared)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    .sheet(isPresented: $showSettings) {
      SettingsView().environment(ThemeManager.shared)
        .presentationDetents([.large]).presentationDragIndicator(.visible)
    }
    .sheet(isPresented: $showProductivity) {
      ProductivityView().environment(ThemeManager.shared)
        .presentationDetents([.large]).presentationDragIndicator(.visible)
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
    }
  }

  private func projectModel(for route: ProjectRoute) -> Project {
    if let hp = store.projects.first(where: { $0.id == route.id }) {
      return Project(
        id: hp.id,
        name: hp.name,
        color: AppColors.parseHex(hp.colorHex, fallback: Color(hex: 0x5FD3DC))
      )
    }
    return Project(id: route.id, name: route.name, color: Color(hex: 0x5FD3DC))
  }

  private var greetingTextSection: some View {
    let c = theme.colors
    return Section {
      VStack(alignment: .leading, spacing: 6) {
        Text(store.greeting)
          .font(.system(size: 28, weight: .heavy))
          .foregroundStyle(c.textPrimary)
        Text("Vamos focar no que realmente importa hoje.")
          .font(AppTypography.taskPreview)
          .foregroundStyle(c.textSecondary)
      }
      .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 8, trailing: 20))
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
    }
  }

  @ViewBuilder
  private var statusSection: some View {
    if store.isLoading {
      Section {
        ProgressView().frame(maxWidth: .infinity).listRowBackground(Color.clear)
      }
    } else if store.overdueCount > 0 {
      Section {
        Button { onNavigateToTab(.today) } label: {
          HStack(spacing: 10) {
            StackedIcons.image(.exclamation).foregroundStyle(AppColors.overdue)
            Text(store.overdueCount == 1 ? "1 tarefa atrasada" : "\(store.overdueCount) tarefas atrasadas")
              .font(.system(size: 15, weight: .semibold))
              .foregroundStyle(AppColors.overdue)
            Spacer()
            StackedIcons.image(.chevronRight).font(.system(size: 12, weight: .semibold))
              .foregroundStyle(AppColors.overdue.opacity(0.85))
          }
          .padding(14)
          .background(AppColors.overdue.opacity(0.15))
          .clipShape(RoundedRectangle(cornerRadius: 14))
          .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.overdue.opacity(0.28)))
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 8, trailing: 20))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
      }
    } else {
      Section {
        HStack(spacing: 8) {
          StackedIcons.image(.checkCircle)
            .foregroundStyle(AppColors.tagGreen.opacity(0.72))
          Text("Tudo em dia")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(AppColors.tagGreen.opacity(0.72))
        }
        .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 8, trailing: 20))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
      }
    }
  }

  private var overviewSection: some View {
    Section {
      navRow(icon: .navInbox, label: "Inbox", count: store.inboxCount, tab: .inbox)
      navRow(icon: .navToday, label: "Hoje", count: store.todayPending, tab: .today)
      navRow(icon: .navUpcoming, label: "Em breve", count: store.upcomingCount, tab: .upcoming)
    } header: {
      sectionHeader("VISÃO GERAL")
    }
  }

  private var projectsSection: some View {
    Section {
      if store.projects.isEmpty {
        VStack(spacing: 12) {
          EmptyStateView(icon: .folder, title: "Nenhum projeto ainda", subtitle: "Organize suas tarefas por contexto")
          Button("Criar projeto") { showNewProject = true }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(theme.colors.accent)
        }
        .listRowBackground(Color.clear)
      } else {
        ForEach(store.projects) { project in
          Button { selectedProject = ProjectRoute(id: project.id, name: project.name) } label: {
            projectRow(project)
          }
          .buttonStyle(.plain)
          .contextMenu {
            Button("Opções do projeto") {
              projectOptions = ProjectRoute(id: project.id, name: project.name)
            }
          }
          .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
        }
      }
    } header: {
      sectionHeader("PROJETOS")
    }
  }

  private func navRow(icon: StackedIconKey, label: String, count: Int, tab: NavTab) -> some View {
    let c = theme.colors
    return Button { onNavigateToTab(tab) } label: {
      HStack(spacing: 14) {
        StackedIcons.image(icon).font(.system(size: 20)).foregroundStyle(c.textSecondary).frame(width: 28)
        Text(label).font(.system(size: 16, weight: .medium)).foregroundStyle(c.textPrimary)
        Spacer()
        Text("\(count)").font(.system(size: 16, weight: .medium)).foregroundStyle(c.textTertiary)
        StackedIcons.image(.chevronRight).font(.system(size: 12, weight: .semibold))
          .foregroundStyle(c.textTertiary.opacity(0.7))
      }
      .padding(.vertical, 10)
    }
    .buttonStyle(.plain)
    .listRowInsets(EdgeInsets(top: 2, leading: 20, bottom: 2, trailing: 20))
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
  }

  private func projectRow(_ project: HomeProject) -> some View {
    let c = theme.colors
    let color = AppColors.parseHex(project.colorHex, fallback: Color(hex: 0x5FD3DC))
    return HStack(spacing: 14) {
      StackedIcons.image(ProjectIcons.asset(for: project.iconKey))
        .font(.system(size: 20)).foregroundStyle(color).frame(width: 28)
      Text(project.name).font(.system(size: 16, weight: .medium)).foregroundStyle(c.textPrimary)
      Spacer()
      Text("\(project.taskCount)").font(.system(size: 16, weight: .medium)).foregroundStyle(c.textTertiary)
      StackedIcons.image(.chevronRight).font(.system(size: 12, weight: .semibold))
        .foregroundStyle(c.textTertiary.opacity(0.7))
    }
    .padding(.vertical, 10)
  }

  private func sectionHeader(_ text: String) -> some View {
    Text(text).font(.system(size: 11, weight: .bold))
      .foregroundStyle(theme.colors.textSecondary).tracking(0.8).textCase(nil)
  }
}
