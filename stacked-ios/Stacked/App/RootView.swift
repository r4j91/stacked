import SwiftUI

// Paridade lib/main.dart RootScreen + ResponsiveLayout (mobile)
struct RootView: View {
  @State private var selectedTab: NavTab = .home
  @State private var showSearch = false
  @State private var showQuickAdd = false
  @State private var showNewProject = false
  @State private var fabOpen = false
  @State private var router = AppNavigationRouter.shared

  var body: some View {
    MobileShell(
      selectedTab: $selectedTab,
      fabOpen: $fabOpen,
      onNewTask: { openQuickAdd() },
      onSearch: { showSearch = true },
      onNewProject: { showNewProject = true }
    ) {
      tabContent(for: selectedTab)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .onChange(of: selectedTab) { _, _ in
      dismissOverlays()
    }
    .onChange(of: router.pendingTab) { _, tab in
      if let tab { selectedTab = tab }
    }
    .onChange(of: router.pendingOpenSearch) { _, open in
      if open { showSearch = true }
    }
    .task { reloadData(for: selectedTab) }
    .sheet(isPresented: $showSearch) {
      SearchView().environment(ThemeManager.shared)
    }
    .sheet(isPresented: $showQuickAdd, onDismiss: {
      PopoverPresenter.shared.dismiss()
    }) {
      QuickAddTaskView(
        onSaved: { reloadAll() },
        onDismiss: { showQuickAdd = false }
      )
      .environment(ThemeManager.shared)
    }
    .sheet(isPresented: $showNewProject) {
      NewProjectSheetView(onCreated: {
        _Concurrency.Task {
          await HomeStore.shared.load()
          await FiltersStore.shared.loadDashboard()
        }
      })
      .environment(ThemeManager.shared)
      .presentationDetents([.large])
      .presentationDragIndicator(.visible)
    }
  }

  private func openQuickAdd() {
    fabOpen = false
    PopoverPresenter.shared.dismiss()
    showQuickAdd = true
  }

  private func dismissOverlays() {
    fabOpen = false
    PopoverPresenter.shared.dismiss()
  }

  @ViewBuilder
  private func tabContent(for tab: NavTab) -> some View {
    switch tab {
    case .home: HomeView(onNavigateToTab: { selectedTab = $0 })
    case .inbox: InboxView()
    case .today: TodayView()
    case .upcoming: UpcomingView()
    case .filters: FiltersView()
    }
  }

  private func reloadData(for tab: NavTab) {
    _Concurrency.Task {
      switch tab {
      case .home: await HomeStore.shared.load()
      case .today: await TaskStore.shared.loadToday()
      case .inbox: await TaskStore.shared.loadInbox()
      case .upcoming: await UpcomingStore.shared.load()
      case .filters: await FiltersStore.shared.loadDashboard()
      }
    }
  }

  private func reloadAll() {
    reloadData(for: selectedTab)
    _Concurrency.Task {
      await TaskStore.shared.loadToday()
      await TaskStore.shared.loadInbox()
      await UpcomingStore.shared.load()
      await HomeStore.shared.load()
    }
  }
}
