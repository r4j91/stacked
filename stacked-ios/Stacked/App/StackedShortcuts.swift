import AppIntents

struct OpenTodayIntent: AppIntent {
  static var title: LocalizedStringResource = "Abrir Hoje"
  static var description = IntentDescription("Abre a lista de tarefas de hoje no Stacked.")
  static var openAppWhenRun = true

  func perform() async throws -> some IntentResult {
    await MainActor.run { AppNavigationRouter.shared.open(tab: .today) }
    return .result()
  }
}

struct OpenInboxIntent: AppIntent {
  static var title: LocalizedStringResource = "Abrir Inbox"
  static var description = IntentDescription("Abre a caixa de entrada no Stacked.")
  static var openAppWhenRun = true

  func perform() async throws -> some IntentResult {
    await MainActor.run { AppNavigationRouter.shared.open(tab: .inbox) }
    return .result()
  }
}

struct OpenSearchIntent: AppIntent {
  static var title: LocalizedStringResource = "Buscar tarefas"
  static var description = IntentDescription("Abre a busca no Stacked.")
  static var openAppWhenRun = true

  func perform() async throws -> some IntentResult {
    await MainActor.run { AppNavigationRouter.shared.openSearch() }
    return .result()
  }
}

struct StackedShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: OpenTodayIntent(),
      phrases: [
        "Ver tarefas de hoje no \(.applicationName)",
        "Abrir Hoje no \(.applicationName)",
      ],
      shortTitle: "Hoje",
      systemImageName: "calendar"
    )
    AppShortcut(
      intent: OpenInboxIntent(),
      phrases: [
        "Abrir Inbox no \(.applicationName)",
        "Ver caixa de entrada no \(.applicationName)",
      ],
      shortTitle: "Inbox",
      systemImageName: "tray"
    )
    AppShortcut(
      intent: OpenSearchIntent(),
      phrases: [
        "Buscar tarefas no \(.applicationName)",
      ],
      shortTitle: "Buscar",
      systemImageName: "magnifyingglass"
    )
  }
}
