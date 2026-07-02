import Foundation

@MainActor
@Observable
final class AppNavigationRouter {
  static let shared = AppNavigationRouter()

  var pendingTab: NavTab?
  var pendingOpenSearch = false

  private init() {}

  func open(tab: NavTab) {
    pendingTab = tab
  }

  func openSearch() {
    pendingOpenSearch = true
  }

  func handle(url: URL) {
    guard url.scheme == "stacked" else { return }
    switch url.host {
    case "today": open(tab: .today)
    case "inbox": open(tab: .inbox)
    case "upcoming": open(tab: .upcoming)
    case "filters": open(tab: .filters)
    case "home", "navigate": open(tab: .home)
    case "search": openSearch()
    default: open(tab: .home)
    }
  }

  func consumeTab() -> NavTab? {
    defer { pendingTab = nil }
    return pendingTab
  }

  func consumeSearch() -> Bool {
    defer { pendingOpenSearch = false }
    return pendingOpenSearch
  }
}
