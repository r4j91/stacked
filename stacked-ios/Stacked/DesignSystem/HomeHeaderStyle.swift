import SwiftUI

/// Formato da barra do topo da Home quando o card de saudação está desligado.
/// Com o card ligado o header não muda: o card já carrega saudação, data, clima
/// e progresso, e repetir isso na barra seria redundante.
enum HomeHeaderStyle: String, CaseIterable, Identifiable {
  case classic
  case progressRing
  case greeting
  case search

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .classic: "Padrão"
    case .progressRing: "Anel no avatar"
    case .greeting: "Saudação"
    case .search: "Busca no topo"
    }
  }

  var subtitle: String {
    switch self {
    case .classic: "Avatar e nome, como está hoje"
    case .progressRing: "Progresso do dia em volta do avatar"
    case .greeting: "Saudação com data, clima e anel do dia"
    case .search: "Campo de busca entre os botões"
    }
  }

  var showsProgressRing: Bool {
    self == .progressRing || self == .greeting
  }

  /// A busca no header substitui o atalho — os dois juntos duplicariam a ação.
  var hidesSearchShortcut: Bool { self == .search }
}

enum HomeHeaderStyleStorage {
  static let key = "homeHeaderStyle"

  static var defaultStyle: HomeHeaderStyle { .greeting }
  static var defaultRawValue: String { defaultStyle.rawValue }

  static func style(from rawValue: String) -> HomeHeaderStyle {
    HomeHeaderStyle(rawValue: rawValue) ?? defaultStyle
  }

  static func resolved(rawValue: String, topCardEnabled: Bool) -> HomeHeaderStyle {
    topCardEnabled ? .classic : style(from: rawValue)
  }
}

/// Meta diária de conclusões que o anel do avatar preenche. Mede tarefas e
/// subtarefas concluídas hoje, não a agenda do dia: o denominador precisa ser
/// estável para o anel não andar para trás quando você agenda algo novo.
enum HomeDailyGoalStorage {
  static let key = "homeDailyGoal"
  static let defaultGoal = 5
  static let options = [3, 5, 8, 10]

  static func goal(from stored: Int) -> Int {
    options.contains(stored) ? stored : defaultGoal
  }
}

/// Larguras do header derivadas da janela: dentro da toolbar não há proposta de
/// largura utilizável, então os textos são cortados por contagem de caracteres e
/// os campos recebem largura fixa.
@MainActor
enum HomeHeaderMetrics {
  /// Sino + divisória + engrenagem.
  static var trailingPillWidth: CGFloat { AppLayout.headerControlSize * 2 + 4 }

  /// Margens da nav + gap — reserva espaço pro trailing (sino/config).
  private static let barChromeReserve: CGFloat = 48

  /// Largura máxima da pill do avatar — sempre deixa espaço pro trailing.
  static var leadingPillMaxWidth: CGFloat {
    let free = ScreenMetrics.bounds.width - trailingPillWidth - barChromeReserve
    return max(200, free)
  }

  /// Sobra entre a pill do avatar e a de sino/config, já descontadas as margens
  /// da barra de navegação.
  static var searchFieldWidth: CGFloat {
    let free = ScreenMetrics.bounds.width
      - AppLayout.headerControlSize
      - trailingPillWidth
      - 60
    return max(110, free)
  }
}
