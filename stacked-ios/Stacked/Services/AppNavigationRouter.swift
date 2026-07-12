import Foundation

@MainActor
@Observable
final class AppNavigationRouter {
  static let shared = AppNavigationRouter()

  var pendingTab: NavTab?
  var pendingOpenSearch = false
  var pendingTaskId: String?

  private init() {}

  func open(tab: NavTab) {
    pendingTab = tab
  }

  func openSearch() {
    pendingOpenSearch = true
  }

  func openTask(id: String) {
    guard TaskIdentity.isValidUUID(id) else {
      open(tab: .today)
      return
    }
    pendingTaskId = id
    open(tab: .today)
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
    case "task":
      let id = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
      if TaskIdentity.isValidUUID(id) {
        openTask(id: id)
      } else {
        open(tab: .today)
      }
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

  func consumeTaskId() -> String? {
    defer { pendingTaskId = nil }
    return pendingTaskId
  }
}
