import AppIntents

/// Modo de exibição do widget — configurável ao adicionar/editar na Home Screen.
///
/// Só deve ser compilado no target StackedWidgetExtension (não no app host).
/// AppEnum duplicado em dois módulos faz a Home Screen gravar um tipo e o
/// widget ler outro — o parâmetro volta pro default e o modo Em breve “não pega”.
enum WidgetDisplayMode: String, AppEnum, CaseIterable {
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

  init() {
    self.displayMode = .smart
  }

  init(displayMode: WidgetDisplayMode) {
    self.displayMode = displayMode
  }

  static var parameterSummary: some ParameterSummary {
    Summary("Mostrar \(\.$displayMode)")
  }
}
