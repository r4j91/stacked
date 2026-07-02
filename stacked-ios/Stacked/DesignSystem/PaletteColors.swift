import SwiftUI

// Paridade lib/theme/palette_colors.dart
enum PaletteColors {
  static let projectHex: [String] = [
    "#63C7D8", "#6F8FB8", "#84B98E", "#789C6B", "#C58D97", "#C58A72",
    "#A496C8", "#6F79B6", "#C7B38A", "#D3B36A", "#7F99A8", "#9CA3AF",
    "#5FD3DC", "#4D9FEC", "#B18CF5", "#8FD46B", "#F5A623", "#EF5A5F",
    "#FF85A1", "#64D8A0", "#FFD166", "#E07B54",
    "#F43F5E", "#EC4899", "#D946EF", "#06B6D4", "#10B981", "#84CC16",
    "#F59E0B", "#F97316",
  ]

  static var projectColors: [Color] {
    projectHex.map { AppColors.parseHex($0) }
  }

  static let defaultHex = "#5FD3DC"
}
