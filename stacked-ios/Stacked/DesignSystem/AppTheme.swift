import SwiftUI

// Paridade lib/theme/app_theme_data.dart
enum AppThemeId: String, CaseIterable, Identifiable {
    case graphite
    case moonstone
    case midnight
    case obsidian
    case anthracite
    case slate
    case titanium
    case sodalite
    case hematite
    case jade
    case aventurine
    case amazonite
    case larimar

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .graphite: "Graphite"
        case .moonstone: "Moonstone"
        case .midnight: "Midnight"
        case .obsidian: "Obsidian"
        case .anthracite: "Anthracite"
        case .slate: "Slate"
        case .titanium: "Titanium"
        case .sodalite: "Sodalite"
        case .hematite: "Hematite"
        case .jade: "Jade"
        case .aventurine: "Aventurine"
        case .amazonite: "Amazonite"
        case .larimar: "Larimar"
        }
    }

    var subtitle: String {
        switch self {
        case .graphite: "Escuro"
        case .moonstone: "Claro"
        case .midnight: "Escuro premium"
        case .obsidian: "Preto puro"
        case .anthracite: "Cinza premium"
        case .slate: "Monocromático"
        case .titanium: "Escuro metálico"
        case .sodalite: "Azul profundo"
        case .hematite: "Preto polido"
        case .jade: "Verde discreto"
        case .aventurine: "Verde profundo"
        case .amazonite: "Petróleo"
        case .larimar: "Petróleo cinza"
        }
    }

    /// Preview do seletor (3 retângulos). Temas novos usam hex de mockup; demais = tokens reais.
    var previewSwatch: (background: Color, surface: Color, accent: Color) {
        switch self {
        case .titanium:
            return (Color(hex: 0x0A0C10), Color(hex: 0x171B21), Color(hex: 0x8FA8C7))
        case .sodalite:
            return (Color(hex: 0x070A12), Color(hex: 0x101626), Color(hex: 0xA9BAD9))
        case .hematite:
            return (Color(hex: 0x060707), Color(hex: 0x131416), Color(hex: 0xC4CCD6))
        case .jade:
            return (Color(hex: 0x0A0B0B), Color(hex: 0x191B1B), Color(hex: 0x7FAA92))
        case .aventurine:
            return (Color(hex: 0x070808), Color(hex: 0x131515), Color(hex: 0x5E9474))
        case .amazonite:
            return (Color(hex: 0x070B0D), Color(hex: 0x12191C), Color(hex: 0x86ABB0))
        case .anthracite:
            return (Color(hex: 0x1A1A1A), Color(hex: 0x242424), Color(hex: 0x00D4D4))
        case .larimar:
            return (Color(hex: 0x141C1F), Color(hex: 0x1C262A), Color(hex: 0x86ABB0))
        default:
            let c = colors
            return (c.background, c.surface, c.accent)
        }
    }

    var colors: AppThemeColors {
        switch self {
        case .graphite: .graphite
        case .moonstone: .moonstone
        case .midnight: .midnight
        case .obsidian: .obsidian
        case .anthracite: .anthracite
        case .slate: .slate
        case .titanium: .titanium
        case .sodalite: .sodalite
        case .hematite: .hematite
        case .jade: .jade
        case .aventurine: .aventurine
        case .amazonite: .amazonite
        case .larimar: .larimar
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
    /// Acento de UI (tab ativa, pastas padrão, seleções, realces).
    let accent: Color
    /// Texto/ícone sobre fundo `accent` — derivado por tema, sem alterar hex da paleta.
    let onAccent: Color
    /// Acento de ação primária (FAB, Salvar, CTAs, toggles). Temas clássicos: = `accent`.
    let actionAccent: Color
    /// Texto/ícone sobre fill de ação (FAB/CTA). Temas clássicos: = `onAccent`.
    let onActionAccent: Color
    /// Gradiente FAB (135–150°). Temas clássicos: ambos = `actionAccent` (sólido).
    let fabGradientStart: Color
    let fabGradientEnd: Color
    /// Cor padrão de ícone de pasta/projeto sem hex próprio. Temas clássicos: = `accent`.
    let folderTint: Color
    let navBar: Color
    let isDark: Bool

    // SUBSTITUIDO_TEMAS_JADE: factories sem actionAccent/onActionAccent/fabGradient*/folderTint
    // — campos novos = accent/onAccent nos temas pré-Jade (zero delta visual).

    // Paridade AppThemeColors.graphite
    static let graphite = AppThemeColors(
        background: Color(hex: 0x1A1B1E),
        surface: Color(hex: 0x242529),
        surfaceVariant: Color(hex: 0x2C2D33),
        textPrimary: Color(hex: 0xF2F3F5),
        textSecondary: Color(hex: 0x9296A0),
        textTertiary: Color(hex: 0x6B6E76),
        accent: Color(hex: 0x5FD3DC),
        onAccent: Color(hex: 0x1A1B1E),
        actionAccent: Color(hex: 0x5FD3DC),
        onActionAccent: Color(hex: 0x1A1B1E),
        fabGradientStart: Color(hex: 0x5FD3DC),
        fabGradientEnd: Color(hex: 0x5FD3DC),
        folderTint: Color(hex: 0x5FD3DC),
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
        onAccent: Color(hex: 0xFFFFFF),
        actionAccent: Color(hex: 0x3B485B),
        onActionAccent: Color(hex: 0xFFFFFF),
        fabGradientStart: Color(hex: 0x3B485B),
        fabGradientEnd: Color(hex: 0x3B485B),
        folderTint: Color(hex: 0x3B485B),
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
        onAccent: Color(hex: 0x0A0A0F),
        actionAccent: Color(hex: 0x6C63FF),
        onActionAccent: Color(hex: 0x0A0A0F),
        fabGradientStart: Color(hex: 0x6C63FF),
        fabGradientEnd: Color(hex: 0x6C63FF),
        folderTint: Color(hex: 0x6C63FF),
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
        onAccent: Color(hex: 0x0D0D0D),
        actionAccent: Color(hex: 0x00D4D4),
        onActionAccent: Color(hex: 0x0D0D0D),
        fabGradientStart: Color(hex: 0x00D4D4),
        fabGradientEnd: Color(hex: 0x00D4D4),
        folderTint: Color(hex: 0x00D4D4),
        navBar: Color(hex: 0x111111),
        isDark: true
    )

    /// Anthracite — variante Obsidian com fundo cinza premium (não preto puro).
    static let anthracite = AppThemeColors(
        background: Color(hex: 0x1A1A1A),
        surface: Color(hex: 0x242424),
        surfaceVariant: Color(hex: 0x2E2E2E),
        textPrimary: Color(hex: 0xF0F0F0),
        textSecondary: Color(hex: 0x8A8A8A),
        textTertiary: Color(hex: 0x5A5A5A),
        accent: Color(hex: 0x00D4D4),
        onAccent: Color(hex: 0x1A1A1A),
        actionAccent: Color(hex: 0x00D4D4),
        onActionAccent: Color(hex: 0x1A1A1A),
        fabGradientStart: Color(hex: 0x00D4D4),
        fabGradientEnd: Color(hex: 0x00D4D4),
        folderTint: Color(hex: 0x00D4D4),
        navBar: Color(hex: 0x1F1F1F),
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
        onAccent: Color(hex: 0x16161A),
        actionAccent: Color(hex: 0xE8E8EC),
        onActionAccent: Color(hex: 0x16161A),
        fabGradientStart: Color(hex: 0xE8E8EC),
        fabGradientEnd: Color(hex: 0xE8E8EC),
        folderTint: Color(hex: 0xE8E8EC),
        navBar: Color(hex: 0x16161A),
        isDark: true
    )

    static let titanium = AppThemeColors(
        background: Color(hex: 0x101318),
        surface: Color(hex: 0x171B21),
        surfaceVariant: Color(hex: 0x1E242C),
        textPrimary: Color(hex: 0xE6EAF0),
        textSecondary: Color(hex: 0x98A2B0),
        textTertiary: Color(hex: 0x616B7A),
        accent: Color(hex: 0x8FA8C7),
        onAccent: Color(hex: 0x0E1319),
        actionAccent: Color(hex: 0x8FA8C7),
        onActionAccent: Color(hex: 0x0E1319),
        fabGradientStart: Color(hex: 0x8FA8C7),
        fabGradientEnd: Color(hex: 0x8FA8C7),
        folderTint: Color(hex: 0x8FA8C7),
        navBar: Color(hex: 0x171B21),
        isDark: true
    )

    static let sodalite = AppThemeColors(
        background: Color(hex: 0x0A0E19),
        surface: Color(hex: 0x101626),
        surfaceVariant: Color(hex: 0x161E33),
        textPrimary: Color(hex: 0xE7EAF3),
        textSecondary: Color(hex: 0x8E97B2),
        textTertiary: Color(hex: 0x5A6480),
        accent: Color(hex: 0xA9BAD9),
        onAccent: Color(hex: 0x0A0F1D),
        actionAccent: Color(hex: 0xA9BAD9),
        onActionAccent: Color(hex: 0x0A0F1D),
        fabGradientStart: Color(hex: 0xA9BAD9),
        fabGradientEnd: Color(hex: 0xA9BAD9),
        folderTint: Color(hex: 0xA9BAD9),
        navBar: Color(hex: 0x101626),
        isDark: true
    )

    static let hematite = AppThemeColors(
        background: Color(hex: 0x0A0B0C),
        surface: Color(hex: 0x131416),
        surfaceVariant: Color(hex: 0x1A1C1F),
        textPrimary: Color(hex: 0xECEEF1),
        textSecondary: Color(hex: 0x93999F),
        textTertiary: Color(hex: 0x5C6167),
        accent: Color(hex: 0xC4CCD6),
        onAccent: Color(hex: 0x0B0C0E),
        actionAccent: Color(hex: 0xC4CCD6),
        onActionAccent: Color(hex: 0x0B0C0E),
        fabGradientStart: Color(hex: 0xC4CCD6),
        fabGradientEnd: Color(hex: 0xC4CCD6),
        folderTint: Color(hex: 0xC4CCD6),
        navBar: Color(hex: 0x131416),
        isDark: true
    )

    /// Jade — "Verde discreto": UI neutra; verde-sálvia só em ação.
    static let jade = AppThemeColors(
        background: Color(hex: 0x121313),
        surface: Color(hex: 0x191B1B),
        surfaceVariant: Color(hex: 0x212423),
        textPrimary: Color(hex: 0xEAEDEB),
        textSecondary: Color(hex: 0x9AA19D),
        textTertiary: Color(hex: 0x626864),
        accent: Color(hex: 0xEAEDEB),
        onAccent: Color(hex: 0x121313),
        actionAccent: Color(hex: 0x7FAA92),
        onActionAccent: Color(hex: 0x0C110E),
        fabGradientStart: Color(hex: 0x9CC2AC),
        fabGradientEnd: Color(hex: 0x628E75),
        folderTint: Color(hex: 0x8B9691),
        navBar: Color(hex: 0x191B1B),
        isDark: true
    )

    /// Aventurine — "Verde profundo": UI neutra; esmeralda só em ação.
    static let aventurine = AppThemeColors(
        background: Color(hex: 0x0B0C0C),
        surface: Color(hex: 0x131515),
        surfaceVariant: Color(hex: 0x1A1D1C),
        textPrimary: Color(hex: 0xECEFED),
        textSecondary: Color(hex: 0x949B97),
        textTertiary: Color(hex: 0x5B615D),
        accent: Color(hex: 0xECEFED),
        onAccent: Color(hex: 0x0B0C0C),
        actionAccent: Color(hex: 0x5E9474),
        onActionAccent: Color(hex: 0xF2F7F4),
        fabGradientStart: Color(hex: 0x79AE8F),
        fabGradientEnd: Color(hex: 0x487859),
        folderTint: Color(hex: 0x909794),
        navBar: Color(hex: 0x131515),
        isDark: true
    )

    /// Amazonite — "Petróleo": acento único (UI = ação).
    static let amazonite = AppThemeColors(
        background: Color(hex: 0x0B1113),
        surface: Color(hex: 0x12191C),
        surfaceVariant: Color(hex: 0x182124),
        textPrimary: Color(hex: 0xE5EBEC),
        textSecondary: Color(hex: 0x8EA0A3),
        textTertiary: Color(hex: 0x59696C),
        accent: Color(hex: 0x86ABB0),
        onAccent: Color(hex: 0x0A1012),
        actionAccent: Color(hex: 0x86ABB0),
        onActionAccent: Color(hex: 0x0A1012),
        fabGradientStart: Color(hex: 0xA3C6CB),
        fabGradientEnd: Color(hex: 0x6B8F95),
        folderTint: Color(hex: 0x86ABB0),
        navBar: Color(hex: 0x12191C),
        isDark: true
    )

    /// Larimar — variante Amazonite com fundo cinza-petróleo elevado.
    static let larimar = AppThemeColors(
        background: Color(hex: 0x141C1F),
        surface: Color(hex: 0x1C262A),
        surfaceVariant: Color(hex: 0x263236),
        textPrimary: Color(hex: 0xE5EBEC),
        textSecondary: Color(hex: 0x8EA0A3),
        textTertiary: Color(hex: 0x5C6B6E),
        accent: Color(hex: 0x86ABB0),
        onAccent: Color(hex: 0x0E1518),
        actionAccent: Color(hex: 0x86ABB0),
        onActionAccent: Color(hex: 0x0E1518),
        fabGradientStart: Color(hex: 0xA3C6CB),
        fabGradientEnd: Color(hex: 0x6B8F95),
        folderTint: Color(hex: 0x86ABB0),
        navBar: Color(hex: 0x1C262A),
        isDark: true
    )
}

// MARK: - Theme manager

@Observable
final class ThemeManager {
  static let shared = ThemeManager()

  private static let storageKey = "stacked_theme_id"

  /// Primeiro launch → Slate; quem já escolheu tema mantém a preferência salva.
  var currentId: AppThemeId = .slate {
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
