import SwiftUI

// Paridade lib/theme/app_colors.dart — cores semânticas (não mudam com tema)
enum AppColors {
  static let priorityHigh = Color(hex: 0xEF5A5F)
  static let priorityMedium = Color(hex: 0xF5A623)
  static let priorityLow = Color(hex: 0x4D9FEC)
  static let tagPurple = Color(hex: 0xB18CF5)
  static let tagGreen = Color(hex: 0x8FD46B)

  static let success = Color(hex: 0x22C55E)
  static let overdue = priorityHigh
  static let onColoredFill = Color.white

  static let dateDueToday = Color(hex: 0x7ECC49)
  static let dateOverdue = Color(hex: 0xDC4C3E)
  /// Data futura — cinza cool (não compete com o accent).
  static let dateUpcoming = Color(hex: 0x8A9099)
  /// Chip de data concluída / neutro.
  static let textTertiary = Color(hex: 0x6B6E76)

  static let shortcutInbox = Color(hex: 0x246FE0)
  static let shortcutToday = Color(hex: 0x22C55E)
  static let shortcutUpcoming = Color(hex: 0xEB8909)
  static let shortcutFilters = Color(hex: 0x884DFF)

  static func parseHex(_ hex: String?, fallback: Color = Color(hex: 0x6B6E76)) -> Color {
    guard let hex, !hex.isEmpty else { return fallback }
    let clean = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    guard let value = UInt32(clean, radix: 16) else { return fallback }
    return Color(hex: value)
  }
}
