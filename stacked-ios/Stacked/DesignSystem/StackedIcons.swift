import SwiftUI
import Hugeicons

// Paridade lib/ — HugeIcons stroke-rounded via hugeicons-swift SPM
enum StackedIcons {
  static func asset(_ key: StackedIconKey) -> HugeiconsAsset {
    switch key {
    case .navHome: Hugeicons.home01
    case .navInbox: Hugeicons.inbox
    case .navToday: Hugeicons.calendar02
    case .navUpcoming: Hugeicons.calendar03
    case .navFilters: Hugeicons.filterHorizontal
    case .settings: Hugeicons.settings01
    case .notifications: Hugeicons.notification01
    case .search: Hugeicons.search01
    case .newTask: Hugeicons.add01
    case .newProject: Hugeicons.folderAdd
    case .folder: Hugeicons.folder01
    case .check: Hugeicons.tick01
    case .clock: Hugeicons.clock01
    case .trash: Hugeicons.delete01
    case .copy: Hugeicons.copy01
    case .tag: Hugeicons.tag01
    case .logbook: Hugeicons.taskDone01
    case .productivity: Hugeicons.analytics01
    case .chevronRight: Hugeicons.chevronRight
    case .chevronDown: Hugeicons.chevronDown
    case .exclamation: Hugeicons.alert01
    case .list: Hugeicons.listView
    case .paintbrush: Hugeicons.paintBrush01
    case .logout: Hugeicons.logout01
    case .edit: Hugeicons.edit01
    case .more: Hugeicons.moreHorizontal
    case .flag: Hugeicons.flag01
    case .move: Hugeicons.folder01
    case .arrowLeft: Hugeicons.arrowLeft01
    case .close: Hugeicons.cancel01
    case .text: Hugeicons.text
    case .grid: Hugeicons.grid
    case .plus: Hugeicons.add01
    case .checkCircle: Hugeicons.checkmarkCircle01
    case .repeatIcon: Hugeicons.repeatIcon
    case .sun: Hugeicons.sun01
    case .calendar: Hugeicons.calendar03
    case .target: Hugeicons.target01
    case .attachment: Hugeicons.attachment01
    case .money: Hugeicons.money01
    case .arrowUp: Hugeicons.arrowUp01
    case .comment: Hugeicons.comment01
    case .note: Hugeicons.note01
    }
  }

  @MainActor
  static func image(_ key: StackedIconKey) -> Image {
    asset(key).image().renderingMode(.template)
  }

  @MainActor
  static func image(_ asset: HugeiconsAsset) -> Image {
    asset.image().renderingMode(.template)
  }

  @MainActor
  static func icon(_ key: StackedIconKey, size: CGFloat, color: Color) -> some View {
    let img: Image
    let navKeys: [StackedIconKey] = [.navHome, .navInbox, .navToday, .navUpcoming, .navFilters]
    if navKeys.contains(key) {
      img = IconCache.shared.image(for: key) // AJUSTADO_ICONCACHE
    } else {
      img = image(key)
    }
    return img
      .resizable()
      .scaledToFit()
      .frame(width: size, height: size)
      .foregroundStyle(color)
  }
}

enum StackedIconKey: String {
  case navHome, navInbox, navToday, navUpcoming, navFilters
  case settings, notifications, search, newTask, newProject, folder
  case check, clock, trash, copy, tag, logbook, productivity
  case chevronRight, chevronDown, exclamation, list, paintbrush, logout
  case edit, more, flag, move, arrowLeft, close, text, grid, plus
  case checkCircle, repeatIcon, sun, calendar, target, attachment, money, arrowUp, comment
  case note
}

// Paridade lib/utils/project_icons.dart
enum ProjectIcons {
  static func asset(for key: String?) -> HugeiconsAsset {
    switch key {
    // Marcadores
    case "hash": Hugeicons.hash
    // `asterisk` vem dentro de um balão de fala; o solto é o 02.
    case "asterisk": Hugeicons.asterisk02
    case "star": Hugeicons.star
    case "favorite": Hugeicons.favourite
    case "flag": Hugeicons.flag01
    case "bookmark": Hugeicons.bookmark01
    case "tag": Hugeicons.tag01
    case "target": Hugeicons.target01
    case "inbox": Hugeicons.inbox
    case "archive": Hugeicons.archive
    // Trabalho e estudo
    case "work": Hugeicons.briefcase01
    case "building": Hugeicons.building03
    case "chart": Hugeicons.chart01
    case "code": Hugeicons.code
    case "lightbulb": Hugeicons.idea01
    case "brain": Hugeicons.brain
    case "school": Hugeicons.mortarboard01
    case "book": Hugeicons.book02
    case "note": Hugeicons.note01
    case "pen": Hugeicons.pen01
    // Comunicação e tempo
    case "mail": Hugeicons.mail01
    case "chat": Hugeicons.chat
    case "calendar": Hugeicons.calendar01
    case "clock": Hugeicons.clock01
    // Casa e rotina
    case "home": Hugeicons.home01
    case "coffee": Hugeicons.coffee01
    case "food": Hugeicons.restaurant01
    case "cake": Hugeicons.cake
    case "plant": Hugeicons.plant01
    case "leaf": Hugeicons.leaf01
    case "tree": Hugeicons.tree01
    // Saúde
    case "fitness": Hugeicons.dumbbell01
    case "health": Hugeicons.shield01
    case "pill": Hugeicons.pill
    // Compras e finanças
    case "shopping": Hugeicons.shoppingCart01
    case "money": Hugeicons.money01
    case "wallet": Hugeicons.wallet01
    case "card": Hugeicons.creditCard
    // Lugares e transporte
    case "car": Hugeicons.car01
    case "plane": Hugeicons.airplane01
    case "bike": Hugeicons.bicycle
    case "travel": Hugeicons.globe02
    case "location": Hugeicons.location01
    case "ticket": Hugeicons.ticket01
    case "gift": Hugeicons.gift
    case "key": Hugeicons.key01
    case "lock": Hugeicons.lock
    // Mídia e lazer
    case "music": Hugeicons.musicNote01
    case "headphones": Hugeicons.headphones
    case "camera": Hugeicons.camera01
    case "video": Hugeicons.video01
    case "image": Hugeicons.image01
    case "film": Hugeicons.film01
    case "game": Hugeicons.gamepad
    case "art": Hugeicons.paintBrush01
    // Tech e utilidades
    case "rocket": Hugeicons.rocket01
    case "settings": Hugeicons.settings01
    case "tools": Hugeicons.wrench01
    case "bug": Hugeicons.bug01
    case "cloud": Hugeicons.cloud
    case "database": Hugeicons.database
    case "puzzle": Hugeicons.puzzle
    case "award": Hugeicons.award01
    case "fire": Hugeicons.fire
    case "moon": Hugeicons.moon02
    default: Hugeicons.folder01
    }
  }

  /// Ordem do seletor — agrupada por tema, não alfabética, para varrer a grade
  /// batendo o olho. Chaves antigas continuam válidas; o `default` cobre o resto.
  static let pickerKeys: [String] = [
    "folder", "hash", "asterisk", "star", "favorite", "flag",
    "bookmark", "tag", "target", "inbox", "archive",
    "work", "building", "chart", "code", "lightbulb", "brain",
    "school", "book", "note", "pen",
    "mail", "chat", "calendar", "clock",
    "home", "coffee", "food", "cake", "plant", "leaf", "tree",
    "fitness", "health", "pill",
    "shopping", "money", "wallet", "card",
    "car", "plane", "bike", "travel", "location", "ticket",
    "gift", "key", "lock",
    "music", "headphones", "camera", "video", "image", "film", "game", "art",
    "rocket", "settings", "tools", "bug", "cloud", "database",
    "puzzle", "award", "fire", "moon",
  ]
}
