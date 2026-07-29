import SwiftUI
import UIKit

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

  static let dateDueToday = Color(hex: 0x2EC4B6)
  static let dateOverdue = Color(hex: 0xDC4C3E)
  /// Data futura — cinza cool (não compete com o accent). Em claro, tom mais escuro p/ contraste.
  static var dateUpcoming: Color {
    ThemeManager.shared.colors.isDark ? Color(hex: 0x8A9099) : Color(hex: 0x5A6470)
  }
  /// Prazo (Deadline) — aço azulado; distinto da data e do accent teal.
  static var deadline: Color {
    ThemeManager.shared.colors.isDark ? Color(hex: 0x7B9BB8) : Color(hex: 0x4A6B88)
  }
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

// MARK: - Meta ink (claro)

/// Dessatura cores de meta (chips) só no tema claro — escuro intacto.
enum SoftMetaColor {
  /// Antes 0.52 (muito cinza); sobe um pouco a saturação sem voltar ao vivo.
  private static let saturationScale: CGFloat = 0.68

  static func soften(_ color: Color, isDark: Bool) -> Color {
    guard !isDark else { return color }
    let ui = UIColor(color)
    var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    if ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
      let softS = s * saturationScale
      let softB = min(b, 0.74) * 0.90 + 0.05
      return Color(UIColor(hue: h, saturation: softS, brightness: softB, alpha: a))
    }
    var r: CGFloat = 0, g: CGFloat = 0, bl: CGFloat = 0
    guard ui.getRed(&r, green: &g, blue: &bl, alpha: &a) else { return color }
    let mix: CGFloat = 0.28
    let nr = r * (1 - mix) + 0.36 * mix
    let ng = g * (1 - mix) + 0.39 * mix
    let nb = bl * (1 - mix) + 0.44 * mix
    return Color(UIColor(red: nr, green: ng, blue: nb, alpha: a))
  }
}

extension Color {
  /// Cor de tinta para metadados — dessaturada no claro.
  func metaInk(isDark: Bool) -> Color {
    SoftMetaColor.soften(self, isDark: isDark)
  }
}
