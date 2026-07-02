import SwiftUI

// Paridade lib/main.dart RootScreen + ResponsiveLayout (mobile)
struct RootView: View {
  @Environment(MobileChromeController.self) private var chrome
  @State private var showSearch = false
  @State private var showQuickAdd = false
  @State private var showNewProject = false
  @State private var router = AppNavigationRouter.shared

  var body: some View {
    @Bindable var chrome = chrome
    let currentTab = chrome.selectedTab

    MobileShell(
      onNewTask: { openQuickAdd() },
      onSearch: { showSearch = true },
      onNewProject: { showNewProject = true }
    ) {
      RootTabContent()
    }
    .onChange(of: currentTab) { _, tab in
      reloadData(for: tab)
    }
    .onChange(of: router.pendingTab) { _, tab in
      if let tab { chrome.selectTab(tab) }
    }
    .onChange(of: router.pendingOpenSearch) { _, open in
      if open { showSearch = true }
    }
    .task { reloadData(for: currentTab) }
    .sheet(isPresented: $showSearch) {
      SearchView().environment(ThemeManager.shared)
    }
    .sheet(isPresented: $showQuickAdd, onDismiss: {
      PopoverPresenter.shared.dismiss()
      WindowPopoverCoordinator.shared.presenter?.dismiss()
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
    chrome.closeFabMenu()
    PopoverPresenter.shared.dismiss()
    showQuickAdd = true
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
    reloadData(for: chrome.selectedTab)
    _Concurrency.Task {
      await TaskStore.shared.loadToday()
      await TaskStore.shared.loadInbox()
      await UpcomingStore.shared.load()
      await HomeStore.shared.load()
    }
  }
}

/// Conteúdo por aba — lê `selectedTab` do environment para reagir a toques UIKit no dock.
struct RootTabContent: View {
  @Environment(MobileChromeController.self) private var chrome

  var body: some View {
    switch chrome.selectedTab {
    case .home:
      HomeView(onNavigateToTab: { chrome.selectTab($0) })
    case .inbox:
      InboxView()
    case .today:
      TodayView()
    case .upcoming:
      UpcomingView()
    case .filters:
      FiltersView()
    }
  }
}
