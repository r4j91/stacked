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
    case .chevronRight: Hugeicons.arrowRight02
    case .chevronDown: Hugeicons.arrowDown01
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
    case .calendar: Hugeicons.calendar01
    case .money: Hugeicons.money01
    case .arrowUp: Hugeicons.arrowUp01
    case .comment: Hugeicons.comment01
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
  case checkCircle, repeatIcon, sun, calendar, money, arrowUp, comment
}

// Paridade lib/utils/project_icons.dart
enum ProjectIcons {
  static func asset(for key: String?) -> HugeiconsAsset {
    switch key {
    case "work": Hugeicons.briefcase01
    case "home": Hugeicons.home01
    case "school": Hugeicons.mortarboard01
    case "fitness": Hugeicons.dumbbell01
    case "shopping": Hugeicons.shoppingCart01
    case "favorite": Hugeicons.favourite
    case "star": Hugeicons.star
    case "rocket": Hugeicons.rocket01
    case "lightbulb": Hugeicons.idea01
    case "music": Hugeicons.musicNote01
    case "travel": Hugeicons.globe02
    case "money": Hugeicons.money01
    case "health": Hugeicons.shield01
    case "code": Hugeicons.code
    case "art": Hugeicons.paintBrush01
    default: Hugeicons.folder01
    }
  }

  static let pickerKeys: [String] = [
    "folder", "work", "home", "school", "fitness", "shopping",
    "favorite", "star", "rocket", "lightbulb", "music", "travel",
    "money", "health", "code", "art",
  ]
}
