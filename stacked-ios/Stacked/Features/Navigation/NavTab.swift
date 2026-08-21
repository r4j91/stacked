import SwiftUI

// Paridade lib/main.dart RootScreen + responsive_layout.dart _navItems
enum NavTab: Int, CaseIterable, Identifiable {
  case home = 0
  case inbox = 1
  case today = 2
  case upcoming = 3
  case money = 4

  var id: Int { rawValue }

  var label: String {
    switch self {
    case .home: "Navegar"
    case .inbox: "Inbox"
    case .today: "Hoje"
    case .upcoming: "Em breve"
    case .money: "Dinheiro"
    }
  }

  var stackedIcon: StackedIconKey {
    switch self {
    case .home: .navHome
    case .inbox: .navInbox
    case .today: .navToday
    case .upcoming: .navUpcoming
    case .money: .navMoney
    }
  }

  /// Paridade lib/theme/app_icon_size.dart — calendário com arte mais “baixa” no SVG.
  /// Carteira (`wallet01`) preenche o viewBox; 24pt fazia ela parecer maior que o resto.
  var navIconSize: CGFloat {
    switch self {
    case .today: 24
    default: 22
    }
  }

  var subtitle: String? {
    switch self {
    case .home: nil
    case .inbox: "Tarefas sem data ou projeto"
    case .today: formattedTodaySubtitle
    case .upcoming: "Calendário e agenda"
    case .money: "Contas, fluxo e lançamentos"
    }
  }

  private var formattedTodaySubtitle: String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "pt_BR")
    f.dateFormat = "EEEE, d 'de' MMMM"
    return f.string(from: Date()).capitalized
  }
}
