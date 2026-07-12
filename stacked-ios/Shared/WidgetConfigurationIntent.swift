import AppIntents

/// Modo de exibição do widget — configurável ao adicionar/editar na Home Screen.
enum WidgetDisplayMode: String, AppEnum {
  case today
  case upcoming
  case smart

  static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Modo")

  static var caseDisplayRepresentations: [WidgetDisplayMode: DisplayRepresentation] {
    [
      .today: DisplayRepresentation(title: "Hoje", subtitle: "Tarefas de hoje e atrasadas"),
      .upcoming: DisplayRepresentation(title: "Em breve", subtitle: "Próximas tarefas agendadas"),
      .smart: DisplayRepresentation(title: "Inteligente", subtitle: "Hoje; se vazio, mostra Em breve"),
    ]
  }
}

struct StackedWidgetIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Stacked"
  static var description = IntentDescription("Escolha o que o widget deve mostrar.")

  @Parameter(title: "Mostrar", default: .smart)
  var displayMode: WidgetDisplayMode
}
