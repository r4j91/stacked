import SwiftUI

// Paridade lib/theme/app_theme_data.dart
enum AppThemeId: String, CaseIterable, Identifiable {
    case graphite
    case moonstone
    case midnight
    case obsidian
    case slate

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .graphite: "Graphite"
        case .moonstone: "Moonstone"
        case .midnight: "Midnight"
        case .obsidian: "Obsidian"
        case .slate: "Slate"
        }
    }

    var subtitle: String {
        switch self {
        case .graphite: "Escuro"
        case .moonstone: "Claro"
        case .midnight: "Escuro premium"
        case .obsidian: "Preto puro"
        case .slate: "Monocromático"
        }
    }

    var colors: AppThemeColors {
        switch self {
        case .graphite: .graphite
        case .moonstone: .moonstone
        case .midnight: .midnight
        case .obsidian: .obsidian
        case .slate: .slate
        }
    }
}

struct AppThemeColors: Equatable {
    let background: Color
    let surface: Color
    let surfaceVariant: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let accent: Color
    let navBar: Color
    let isDark: Bool

    // Paridade AppThemeColors.graphite
    static let graphite = AppThemeColors(
        background: Color(hex: 0x1A1B1E),
        surface: Color(hex: 0x242529),
        surfaceVariant: Color(hex: 0x2C2D33),
        textPrimary: Color(hex: 0xF2F3F5),
        textSecondary: Color(hex: 0x9296A0),
        textTertiary: Color(hex: 0x6B6E76),
        accent: Color(hex: 0x5FD3DC),
        navBar: Color(hex: 0x242529),
        isDark: true
    )

    static let moonstone = AppThemeColors(
        background: Color(hex: 0xF2F4F7),
        surface: Color(hex: 0xFFFFFF),
        surfaceVariant: Color(hex: 0xE8ECF2),
        textPrimary: Color(hex: 0x1C2033),
        textSecondary: Color(hex: 0x52596E),
        textTertiary: Color(hex: 0x9097AB),
        accent: Color(hex: 0x3B485B),
        navBar: Color(hex: 0xFFFFFF),
        isDark: false
    )

    static let midnight = AppThemeColors(
        background: Color(hex: 0x0A0A0F),
        surface: Color(hex: 0x12121A),
        surfaceVariant: Color(hex: 0x1E1E2E),
        textPrimary: Color(hex: 0xE8E8F0),
        textSecondary: Color(hex: 0x7070A0),
        textTertiary: Color(hex: 0x4A4A6A),
        accent: Color(hex: 0x6C63FF),
        navBar: Color(hex: 0x0F0F18),
        isDark: true
    )

    static let obsidian = AppThemeColors(
        background: Color(hex: 0x0D0D0D),
        surface: Color(hex: 0x161616),
        surfaceVariant: Color(hex: 0x222222),
        textPrimary: Color(hex: 0xF0F0F0),
        textSecondary: Color(hex: 0x888888),
        textTertiary: Color(hex: 0x555555),
        accent: Color(hex: 0x00D4D4),
        navBar: Color(hex: 0x111111),
        isDark: true
    )

    static let slate = AppThemeColors(
        background: Color(hex: 0x16161A),
        surface: Color(hex: 0x1C1C20),
        surfaceVariant: Color(hex: 0x2C2C32),
        textPrimary: Color(hex: 0xF2F2F4),
        textSecondary: Color(hex: 0x9A9AA2),
        textTertiary: Color(hex: 0x65656D),
        accent: Color(hex: 0xE8E8EC),
        navBar: Color(hex: 0x16161A),
        isDark: true
    )
}

// MARK: - Theme manager (Fase 1 expandirá persistência)

@Observable
final class ThemeManager {
  static let shared = ThemeManager()

  private static let storageKey = "stacked_theme_id"

  var currentId: AppThemeId = .graphite {
    didSet { UserDefaults.standard.set(currentId.rawValue, forKey: Self.storageKey) }
  }

  var colors: AppThemeColors { currentId.colors }

  private init() {
    if let raw = UserDefaults.standard.string(forKey: Self.storageKey),
       let saved = AppThemeId(rawValue: raw) {
      currentId = saved
    }
  }

  func setTheme(_ id: AppThemeId) {
    currentId = id
  }
}

// MARK: - Color hex helper

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
