import SwiftUI

// Paridade lib/theme/app_theme_data.dart
enum AppThemeId: String, CaseIterable, Identifiable {
    case graphite
    case moonstone
    case fog
    case fogAmazonite
    case cloud
    case cloudAmazonite
    case obsidian
    case anthracite
    case slate
    case slateCyan
    case slateAmazonite
    case slateEmber
    case slateMoonstone
    case titanium
    case amazonite
    case onyxAzurite
    case onyxMalachite
    case onyxLarimar
    case sodaliteAzurite
    case sodaliteMalachite
    case sodaliteLarimar
    /// Petróleo-noite com accent mint e fundo em gradiente.
    case abyss
    /// Mesma atmosfera em cinza neutro — gradiente sem matiz azul; accent âmbar.
    case abyssAsh
    /// Abismo Cinza sem degradê — fundo sólido no tom do topo.
    case abyssAshSolid
    /// Abismo Cinza Sólido com accent mint do Abismo.
    case abyssAshSolidMint
    /// Abismo Cinza Sólido com accent teal do print (syntax “option”).
    case abyssAshSolidTeal
    /// Abismo Cinza Sólido com accent lima do print (syntax “value”).
    case abyssAshSolidLime
    /// Abismo Cinza Sólido com accent azul petróleo.
    case abyssAshSolidPetrol
    /// Abismo Cinza com fundo mais claro.
    case abyssAshSoft

    var id: String { rawValue }

    /// Curadoria principal do seletor. Os demais continuam em “Mais temas”.
    static let recommended: [AppThemeId] = [
        .abyss,
        .abyssAsh,
        .abyssAshSolid,
        .abyssAshSolidMint,
        .abyssAshSolidTeal,
        .abyssAshSolidLime,
        .abyssAshSolidPetrol,
        .abyssAshSoft,
        .slate,
        .slateEmber,
        .graphite,
        .moonstone,
        .fog,
    ]

    /// Stops do degradê de atmosfera (hex, topo → base) — fonte única pro
    /// `LinearGradient` do SwiftUI e pra amostragem pontual em UIKit (header
    /// fixo do Em breve: `UIKitHostedTaskList.atmosphericHeaderFill`).
    var atmosphericGradientStops: [UInt32]? {
        switch self {
        case .abyss:
            return [0x0E1418, 0x10181E, 0x121C22, 0x152028]
        case .abyssAsh:
            return [0x141518, 0x16171A, 0x181A1E, 0x1C1E22]
        case .abyssAshSoft:
            return [0x1D2025, 0x1E2126, 0x202328, 0x22252A]
        default:
            return nil
        }
    }

    /// Gradiente de atmosfera. `nil` = fundo sólido (`colors.background`).
    var atmosphericGradient: LinearGradient? {
        guard let stops = atmosphericGradientStops else { return nil }
        return LinearGradient(
            colors: stops.map { Color(hex: $0) },
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var usesAtmosphericBackground: Bool { atmosphericGradient != nil }

    var displayName: String {
        switch self {
        case .graphite: "Graphite"
        case .moonstone: "Moonstone"
        case .fog: "Fog"
        case .fogAmazonite: "Fog Amazonite"
        case .cloud: "Cloud"
        case .cloudAmazonite: "Cloud Amazonite"
        case .obsidian: "Obsidian"
        case .anthracite: "Anthracite"
        case .slate: "Slate"
        case .slateCyan: "Slate Cyan"
        case .slateAmazonite: "Slate Amazonite"
        case .slateEmber: "Slate Ember"
        case .slateMoonstone: "Slate Moonstone"
        case .titanium: "Titanium"
        case .amazonite: "Amazonite"
        case .onyxAzurite: "Onyx Azurite"
        case .onyxMalachite: "Onyx Malachite"
        case .onyxLarimar: "Onyx Larimar"
        case .sodaliteAzurite: "Sodalite Azurite"
        case .sodaliteMalachite: "Sodalite Malachite"
        case .sodaliteLarimar: "Sodalite Larimar"
        case .abyss: "Abismo"
        case .abyssAsh: "Abismo Cinza"
        case .abyssAshSolid: "Abismo Cinza Sólido"
        case .abyssAshSolidMint: "Abismo Cinza Mint"
        case .abyssAshSolidTeal: "Abismo Cinza Teal"
        case .abyssAshSolidLime: "Abismo Cinza Lima"
        case .abyssAshSolidPetrol: "Abismo Cinza Petróleo"
        case .abyssAshSoft: "Abismo Cinza Suave"
        }
    }

    var subtitle: String {
        switch self {
        case .graphite: "Escuro"
        case .moonstone: "Claro"
        case .fog: "Cinza frio claro"
        case .fogAmazonite: "Cinza frio · petróleo"
        case .cloud: "Semi-claro"
        case .cloudAmazonite: "Semi-claro · petróleo"
        case .obsidian: "Preto puro"
        case .anthracite: "Cinza premium"
        case .slate: "Monocromático"
        case .slateCyan: "Ciano Obsidian"
        case .slateAmazonite: "Petróleo"
        case .slateEmber: "Laranja"
        case .slateMoonstone: "Aço"
        case .titanium: "Escuro metálico"
        case .amazonite: "Petróleo"
        case .onyxAzurite: "Preto · aço"
        case .onyxMalachite: "Preto · verde"
        case .onyxLarimar: "Preto · ciano"
        case .sodaliteAzurite: "Carvão · aço"
        case .sodaliteMalachite: "Carvão · verde"
        case .sodaliteLarimar: "Carvão · ciano"
        case .abyss: "Petróleo-noite · mint"
        case .abyssAsh: "Noite neutra · âmbar"
        case .abyssAshSolid: "Fundo sólido · âmbar"
        case .abyssAshSolidMint: "Fundo sólido · mint"
        case .abyssAshSolidTeal: "Fundo sólido · teal"
        case .abyssAshSolidLime: "Fundo sólido · lima"
        case .abyssAshSolidPetrol: "Fundo sólido · petróleo"
        case .abyssAshSoft: "Cinza mais claro · âmbar"
        }
    }

    /// Preview do seletor (3 retângulos). Temas novos usam hex de mockup; demais = tokens reais.
    var previewSwatch: (background: Color, surface: Color, accent: Color) {
        switch self {
        case .abyss:
            return (Color(hex: 0x0E1418), Color(hex: 0x172026), Color(hex: 0x6ED4C8))
        case .abyssAsh:
            return (Color(hex: 0x141518), Color(hex: 0x1C1E22), Color(hex: 0xC9A06E))
        case .abyssAshSolid:
            return (Color(hex: 0x141518), Color(hex: 0x1C1E22), Color(hex: 0xC9A06E))
        case .abyssAshSolidMint:
            return (Color(hex: 0x141518), Color(hex: 0x1C1E22), Color(hex: 0x6ED4C8))
        case .abyssAshSolidTeal:
            return (Color(hex: 0x141518), Color(hex: 0x1C1E22), Color(hex: 0x209088))
        case .abyssAshSolidLime:
            return (Color(hex: 0x141518), Color(hex: 0x1C1E22), Color(hex: 0x98E878))
        case .abyssAshSolidPetrol:
            return (Color(hex: 0x141518), Color(hex: 0x1C1E22), Color(hex: 0x2A7088))
        case .abyssAshSoft:
            return (Color(hex: 0x1D2025), Color(hex: 0x1C1E22), Color(hex: 0xC9A06E))
        case .titanium:
            return (Color(hex: 0x0A0C10), Color(hex: 0x171B21), Color(hex: 0x8FA8C7))
        case .amazonite:
            return (Color(hex: 0x070B0D), Color(hex: 0x12191C), Color(hex: 0x86ABB0))
        case .anthracite:
            return (Color(hex: 0x1A1A1A), Color(hex: 0x242424), Color(hex: 0x5FD3DC))
        case .slateCyan:
            return (Color(hex: 0x18181E), Color(hex: 0x212127), Color(hex: 0x5FD3DC))
        case .slateAmazonite:
            return (Color(hex: 0x18181E), Color(hex: 0x212127), Color(hex: 0x86ABB0))
        case .slateEmber:
            return (Color(hex: 0x18181E), Color(hex: 0x212127), Color(hex: 0xF06B2C))
        case .slateMoonstone:
            return (Color(hex: 0x18181E), Color(hex: 0x212127), Color(hex: 0x4F8BB8))
        case .fog:
            return (Color(hex: 0xE6E8ED), Color(hex: 0xEEEFF3), Color(hex: 0x2A9AA3))
        case .fogAmazonite:
            return (Color(hex: 0xE6E8ED), Color(hex: 0xEEEFF3), Color(hex: 0x86ABB0))
        case .cloud:
            return (Color(hex: 0xD5D8DE), Color(hex: 0xE0E3E9), Color(hex: 0x268F97))
        case .cloudAmazonite:
            return (Color(hex: 0xD5D8DE), Color(hex: 0xE0E3E9), Color(hex: 0x86ABB0))
        case .moonstone:
            return (Color(hex: 0xEEF1F6), Color(hex: 0xF5F7FA), Color(hex: 0x3F6F96))
        case .onyxAzurite:
            return (Color(hex: 0x131313), Color(hex: 0x1C1C1C), Color(hex: 0x3A5468))
        case .onyxMalachite:
            return (Color(hex: 0x131313), Color(hex: 0x1C1C1C), Color(hex: 0x2F5450))
        case .onyxLarimar:
            return (Color(hex: 0x131313), Color(hex: 0x1C1C1C), Color(hex: 0x2C6B78))
        case .sodaliteAzurite:
            return (Color(hex: 0x15171B), Color(hex: 0x1D2025), Color(hex: 0x3A5468))
        case .sodaliteMalachite:
            return (Color(hex: 0x15171B), Color(hex: 0x1D2025), Color(hex: 0x2F5450))
        case .sodaliteLarimar:
            return (Color(hex: 0x15171B), Color(hex: 0x1D2025), Color(hex: 0x2C6B78))
        default:
            let c = colors
            return (c.background, c.surface, c.accent)
        }
    }

    var colors: AppThemeColors {
        switch self {
        case .graphite: .graphite
        case .moonstone: .moonstone
        case .fog: .fog
        case .fogAmazonite: .fogAmazonite
        case .cloud: .cloud
        case .cloudAmazonite: .cloudAmazonite
        case .obsidian: .obsidian
        case .anthracite: .anthracite
        case .slate: .slate
        case .slateCyan: .slateCyan
        case .slateAmazonite: .slateAmazonite
        case .slateEmber: .slateEmber
        case .slateMoonstone: .slateMoonstone
        case .titanium: .titanium
        case .amazonite: .amazonite
        case .onyxAzurite: .onyxAzurite
        case .onyxMalachite: .onyxMalachite
        case .onyxLarimar: .onyxLarimar
        case .sodaliteAzurite: .sodaliteAzurite
        case .sodaliteMalachite: .sodaliteMalachite
        case .sodaliteLarimar: .sodaliteLarimar
        case .abyss: .abyss
        case .abyssAsh: .abyssAsh
        case .abyssAshSolid: .abyssAshSolid
        case .abyssAshSolidMint: .abyssAshSolidMint
        case .abyssAshSolidTeal: .abyssAshSolidTeal
        case .abyssAshSolidLime: .abyssAshSolidLime
        case .abyssAshSolidPetrol: .abyssAshSolidPetrol
        case .abyssAshSoft: .abyssAshSoft
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
    /// Moldura textual e ícones de navegação (cabeçalho de seção, chevron, ícone inativo). Alvo ≥3:1.
    let textQuaternary: Color
    /// Geometria decorativa (divisores, trilhos, fills de ilustração). Não é cor de texto — nunca usar em `Text`.
    let hairline: Color
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
        textQuaternary: Color(hex: 0x55585E),
        hairline: Color(hex: 0x3A3B40),
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

    /// Moonstone — claro legível: sem branco puro; terciário ≥4.5:1.
    /// Accent aço mais saturado (#3A5068 → #3F6F96) — ainda sóbrio no claro.
    static let moonstone = AppThemeColors(
        background: Color(hex: 0xEEF1F6),
        surface: Color(hex: 0xF5F7FA),
        surfaceVariant: Color(hex: 0xE2E6EE),
        textPrimary: Color(hex: 0x1A1D28),
        textSecondary: Color(hex: 0x4A5163),
        textTertiary: Color(hex: 0x656A78),
        textQuaternary: Color(hex: 0x7A8091),
        hairline: Color(hex: 0x8A909C),
        accent: Color(hex: 0x3F6F96),
        onAccent: Color(hex: 0xFFFFFF),
        actionAccent: Color(hex: 0x3F6F96),
        onActionAccent: Color(hex: 0xFFFFFF),
        fabGradientStart: Color(hex: 0x3F6F96),
        fabGradientEnd: Color(hex: 0x3F6F96),
        folderTint: Color(hex: 0x3F6F96),
        navBar: Color(hex: 0xF5F7FA),
        isDark: false
    )

    /// Fog — cinza frio claro (gêmeo Graphite). Accent ciano escurecido p/ contraste.
    static let fog = AppThemeColors(
        background: Color(hex: 0xE6E8ED),
        surface: Color(hex: 0xEEEFF3),
        surfaceVariant: Color(hex: 0xDCDFE6),
        textPrimary: Color(hex: 0x1A1C22),
        textSecondary: Color(hex: 0x4E535E),
        textTertiary: Color(hex: 0x5C616C),
        textQuaternary: Color(hex: 0x727882),
        hairline: Color(hex: 0x8A909C),
        accent: Color(hex: 0x2A9AA3),
        onAccent: Color(hex: 0xF4FBFC),
        actionAccent: Color(hex: 0x2A9AA3),
        onActionAccent: Color(hex: 0xF4FBFC),
        fabGradientStart: Color(hex: 0x2A9AA3),
        fabGradientEnd: Color(hex: 0x2A9AA3),
        folderTint: Color(hex: 0x2A9AA3),
        navBar: Color(hex: 0xEEEFF3),
        isDark: false
    )

    /// Fog Amazonite — Fog + accent petróleo legível em claro (#86ABB0 escurecido).
    static let fogAmazonite = AppThemeColors(
        background: Color(hex: 0xE6E8ED),
        surface: Color(hex: 0xEEEFF3),
        surfaceVariant: Color(hex: 0xDCDFE6),
        textPrimary: Color(hex: 0x1A1C22),
        textSecondary: Color(hex: 0x4E535E),
        textTertiary: Color(hex: 0x5C616C),
        textQuaternary: Color(hex: 0x727882),
        hairline: Color(hex: 0x8A909C),
        accent: Color(hex: 0x3F7076),
        onAccent: Color(hex: 0xF4FBFC),
        actionAccent: Color(hex: 0x3F7076),
        onActionAccent: Color(hex: 0xF4FBFC),
        fabGradientStart: Color(hex: 0x5A8E94),
        fabGradientEnd: Color(hex: 0x3F7076),
        folderTint: Color(hex: 0x3F7076),
        navBar: Color(hex: 0xEEEFF3),
        isDark: false
    )

    /// Cloud — semi-claro / dia nublado (menos brilho de tela).
    static let cloud = AppThemeColors(
        background: Color(hex: 0xD5D8DE),
        surface: Color(hex: 0xE0E3E9),
        surfaceVariant: Color(hex: 0xC8CCD4),
        textPrimary: Color(hex: 0x17191E),
        textSecondary: Color(hex: 0x454A54),
        textTertiary: Color(hex: 0x555C66),
        textQuaternary: Color(hex: 0x6B727C),
        hairline: Color(hex: 0x7A818C),
        accent: Color(hex: 0x268F97),
        onAccent: Color(hex: 0xF2FAFB),
        actionAccent: Color(hex: 0x268F97),
        onActionAccent: Color(hex: 0xF2FAFB),
        fabGradientStart: Color(hex: 0x268F97),
        fabGradientEnd: Color(hex: 0x268F97),
        folderTint: Color(hex: 0x268F97),
        navBar: Color(hex: 0xE0E3E9),
        isDark: false
    )

    /// Cloud Amazonite — Cloud + accent petróleo legível em claro.
    static let cloudAmazonite = AppThemeColors(
        background: Color(hex: 0xD5D8DE),
        surface: Color(hex: 0xE0E3E9),
        surfaceVariant: Color(hex: 0xC8CCD4),
        textPrimary: Color(hex: 0x17191E),
        textSecondary: Color(hex: 0x454A54),
        textTertiary: Color(hex: 0x555C66),
        textQuaternary: Color(hex: 0x6B727C),
        hairline: Color(hex: 0x7A818C),
        accent: Color(hex: 0x3F7076),
        onAccent: Color(hex: 0xF2FAFB),
        actionAccent: Color(hex: 0x3F7076),
        onActionAccent: Color(hex: 0xF2FAFB),
        fabGradientStart: Color(hex: 0x5A8E94),
        fabGradientEnd: Color(hex: 0x3F7076),
        folderTint: Color(hex: 0x3F7076),
        navBar: Color(hex: 0xE0E3E9),
        isDark: false
    )

    static let obsidian = AppThemeColors(
        background: Color(hex: 0x0D0D0D),
        surface: Color(hex: 0x161616),
        surfaceVariant: Color(hex: 0x222222),
        textPrimary: Color(hex: 0xF0F0F0),
        textSecondary: Color(hex: 0x888888),
        textTertiary: Color(hex: 0x555555),
        textQuaternary: Color(hex: 0x444444),
        hairline: Color(hex: 0x2E2E2E),
        accent: Color(hex: 0x5FD3DC),
        onAccent: Color(hex: 0x0D0D0D),
        actionAccent: Color(hex: 0x5FD3DC),
        onActionAccent: Color(hex: 0x0D0D0D),
        fabGradientStart: Color(hex: 0x5FD3DC),
        fabGradientEnd: Color(hex: 0x5FD3DC),
        folderTint: Color(hex: 0x5FD3DC),
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
        textQuaternary: Color(hex: 0x484848),
        hairline: Color(hex: 0x333333),
        accent: Color(hex: 0x5FD3DC),
        onAccent: Color(hex: 0x1A1A1A),
        actionAccent: Color(hex: 0x5FD3DC),
        onActionAccent: Color(hex: 0x1A1A1A),
        fabGradientStart: Color(hex: 0x5FD3DC),
        fabGradientEnd: Color(hex: 0x5FD3DC),
        folderTint: Color(hex: 0x5FD3DC),
        navBar: Color(hex: 0x1F1F1F),
        isDark: true
    )

    static let slate = AppThemeColors(
        background: Color(hex: 0x18181E),
        surface: Color(hex: 0x212127),
        surfaceVariant: Color(hex: 0x2F2F36),
        textPrimary: Color(hex: 0xF2F2F4),
        textSecondary: Color(hex: 0x9A9AA2),
        textTertiary: Color(hex: 0x65656D),
        textQuaternary: Color(hex: 0x52525A),
        hairline: Color(hex: 0x3A3A40),
        accent: Color(hex: 0xE8E8EC),
        onAccent: Color(hex: 0x18181E),
        actionAccent: Color(hex: 0xE8E8EC),
        onActionAccent: Color(hex: 0x18181E),
        fabGradientStart: Color(hex: 0xE8E8EC),
        fabGradientEnd: Color(hex: 0xE8E8EC),
        folderTint: Color(hex: 0xE8E8EC),
        navBar: Color(hex: 0x18181E),
        isDark: true
    )

    /// Slate Cyan — fundo Slate; acento ciano do Obsidian em botões e detalhes.
    static let slateCyan = AppThemeColors(
        background: Color(hex: 0x18181E),
        surface: Color(hex: 0x212127),
        surfaceVariant: Color(hex: 0x2F2F36),
        textPrimary: Color(hex: 0xF2F2F4),
        textSecondary: Color(hex: 0x9A9AA2),
        textTertiary: Color(hex: 0x65656D),
        textQuaternary: Color(hex: 0x52525A),
        hairline: Color(hex: 0x3A3A40),
        accent: Color(hex: 0x5FD3DC),
        onAccent: Color(hex: 0x0A0A0A),
        actionAccent: Color(hex: 0x5FD3DC),
        onActionAccent: Color(hex: 0x0A0A0A),
        fabGradientStart: Color(hex: 0x5FD3DC),
        fabGradientEnd: Color(hex: 0x5FD3DC),
        folderTint: Color(hex: 0x5FD3DC),
        navBar: Color(hex: 0x18181E),
        isDark: true
    )

    /// Slate Amazonite — fundo Slate; acento petróleo do Amazonite em botões e detalhes.
    static let slateAmazonite = AppThemeColors(
        background: Color(hex: 0x18181E),
        surface: Color(hex: 0x212127),
        surfaceVariant: Color(hex: 0x2F2F36),
        textPrimary: Color(hex: 0xF2F2F4),
        textSecondary: Color(hex: 0x9A9AA2),
        textTertiary: Color(hex: 0x65656D),
        textQuaternary: Color(hex: 0x52525A),
        hairline: Color(hex: 0x3A3A40),
        accent: Color(hex: 0x86ABB0),
        onAccent: Color(hex: 0x0A1012),
        actionAccent: Color(hex: 0x86ABB0),
        onActionAccent: Color(hex: 0x0A1012),
        fabGradientStart: Color(hex: 0xA3C6CB),
        fabGradientEnd: Color(hex: 0x6B8F95),
        folderTint: Color(hex: 0x86ABB0),
        navBar: Color(hex: 0x18181E),
        isDark: true
    )

    /// Slate Ember — fundo Slate; laranja vivo (#F06B2C), sem neon.
    static let slateEmber = AppThemeColors(
        background: Color(hex: 0x18181E),
        surface: Color(hex: 0x212127),
        surfaceVariant: Color(hex: 0x2F2F36),
        textPrimary: Color(hex: 0xF2F2F4),
        textSecondary: Color(hex: 0x9A9AA2),
        textTertiary: Color(hex: 0x65656D),
        textQuaternary: Color(hex: 0x65656D),
        hairline: Color(hex: 0x65656D),
        accent: Color(hex: 0xF06B2C),
        onAccent: Color(hex: 0x1A100C),
        actionAccent: Color(hex: 0xF06B2C),
        onActionAccent: Color(hex: 0x1A100C),
        fabGradientStart: Color(hex: 0xF88A48),
        fabGradientEnd: Color(hex: 0xD85518),
        folderTint: Color(hex: 0xF06B2C),
        navBar: Color(hex: 0x18181E),
        isDark: true
    )

    /// Slate Moonstone — fundo Slate; aço mais luminoso no escuro (#4F8BB8).
    static let slateMoonstone = AppThemeColors(
        background: Color(hex: 0x18181E),
        surface: Color(hex: 0x212127),
        surfaceVariant: Color(hex: 0x2F2F36),
        textPrimary: Color(hex: 0xF2F2F4),
        textSecondary: Color(hex: 0x9A9AA2),
        textTertiary: Color(hex: 0x65656D),
        textQuaternary: Color(hex: 0x65656D),
        hairline: Color(hex: 0x65656D),
        accent: Color(hex: 0x4F8BB8),
        onAccent: Color(hex: 0xFFFFFF),
        actionAccent: Color(hex: 0x4F8BB8),
        onActionAccent: Color(hex: 0xFFFFFF),
        fabGradientStart: Color(hex: 0x61A0C8),
        fabGradientEnd: Color(hex: 0x3A739E),
        folderTint: Color(hex: 0x4F8BB8),
        navBar: Color(hex: 0x18181E),
        isDark: true
    )

    static let titanium = AppThemeColors(
        background: Color(hex: 0x101318),
        surface: Color(hex: 0x171B21),
        surfaceVariant: Color(hex: 0x1E242C),
        textPrimary: Color(hex: 0xE6EAF0),
        textSecondary: Color(hex: 0x98A2B0),
        textTertiary: Color(hex: 0x616B7A),
        textQuaternary: Color(hex: 0x4E5664),
        hairline: Color(hex: 0x383E48),
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

    /// Amazonite — "Petróleo": acento único (UI = ação).
    static let amazonite = AppThemeColors(
        background: Color(hex: 0x0B1113),
        surface: Color(hex: 0x12191C),
        surfaceVariant: Color(hex: 0x182124),
        textPrimary: Color(hex: 0xE5EBEC),
        textSecondary: Color(hex: 0x8EA0A3),
        textTertiary: Color(hex: 0x59696C),
        textQuaternary: Color(hex: 0x485558),
        hairline: Color(hex: 0x343E40),
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

    /// Abismo — petrol-noite com accent mint. Fundo usa gradiente em `atmosphericGradient`.
    static let abyss = AppThemeColors(
        background: Color(hex: 0x0E1418),
        surface: Color(hex: 0x172026),
        surfaceVariant: Color(hex: 0x1E2A31),
        textPrimary: Color(hex: 0xE8EEF1),
        textSecondary: Color(hex: 0x8FA3AD),
        textTertiary: Color(hex: 0x667A84),
        textQuaternary: Color(hex: 0x556870),
        hairline: Color(hex: 0x2A3840),
        accent: Color(hex: 0x6ED4C8),
        onAccent: Color(hex: 0x0A1214),
        actionAccent: Color(hex: 0x6ED4C8),
        onActionAccent: Color(hex: 0x0A1214),
        fabGradientStart: Color(hex: 0x8FE0D6),
        fabGradientEnd: Color(hex: 0x4FB8AC),
        folderTint: Color(hex: 0x6ED4C8),
        navBar: Color(hex: 0x172026),
        isDark: true
    )

    /// Abismo Cinza — atmosfera neutra; accent âmbar quente (contraste no cinza frio).
    static let abyssAsh = AppThemeColors(
        background: Color(hex: 0x141518),
        surface: Color(hex: 0x1C1E22),
        surfaceVariant: Color(hex: 0x25282E),
        textPrimary: Color(hex: 0xE8ECF0),
        textSecondary: Color(hex: 0x9AA3B0),
        textTertiary: Color(hex: 0x6B7382),
        textQuaternary: Color(hex: 0x5A6270),
        hairline: Color(hex: 0x2E323A),
        accent: Color(hex: 0xC9A06E),
        onAccent: Color(hex: 0x16120C),
        actionAccent: Color(hex: 0xC9A06E),
        onActionAccent: Color(hex: 0x16120C),
        fabGradientStart: Color(hex: 0xDBB888),
        fabGradientEnd: Color(hex: 0xA88448),
        folderTint: Color(hex: 0xC9A06E),
        navBar: Color(hex: 0x1C1E22),
        isDark: true
    )

    /// Abismo Cinza Sólido — mesmas cores do Abismo Cinza, sem degradê de atmosfera.
    /// Fundo = tom do topo (#141518); containers = surface dos atalhos (#1C1E22).
    static let abyssAshSolid = AppThemeColors(
        background: Color(hex: 0x141518),
        surface: Color(hex: 0x1C1E22),
        surfaceVariant: Color(hex: 0x25282E),
        textPrimary: Color(hex: 0xE8ECF0),
        textSecondary: Color(hex: 0x9AA3B0),
        textTertiary: Color(hex: 0x6B7382),
        textQuaternary: Color(hex: 0x5A6270),
        hairline: Color(hex: 0x2E323A),
        accent: Color(hex: 0xC9A06E),
        onAccent: Color(hex: 0x16120C),
        actionAccent: Color(hex: 0xC9A06E),
        onActionAccent: Color(hex: 0x16120C),
        fabGradientStart: Color(hex: 0xDBB888),
        fabGradientEnd: Color(hex: 0xA88448),
        folderTint: Color(hex: 0xC9A06E),
        navBar: Color(hex: 0x1C1E22),
        isDark: true
    )

    /// Abismo Cinza Mint — canvas sólido do Cinza Sólido + accent mint do Abismo.
    static let abyssAshSolidMint = AppThemeColors(
        background: Color(hex: 0x141518),
        surface: Color(hex: 0x1C1E22),
        surfaceVariant: Color(hex: 0x25282E),
        textPrimary: Color(hex: 0xE8ECF0),
        textSecondary: Color(hex: 0x9AA3B0),
        textTertiary: Color(hex: 0x6B7382),
        textQuaternary: Color(hex: 0x5A6270),
        hairline: Color(hex: 0x2E323A),
        accent: Color(hex: 0x6ED4C8),
        onAccent: Color(hex: 0x0A1214),
        actionAccent: Color(hex: 0x6ED4C8),
        onActionAccent: Color(hex: 0x0A1214),
        fabGradientStart: Color(hex: 0x8FE0D6),
        fabGradientEnd: Color(hex: 0x4FB8AC),
        folderTint: Color(hex: 0x6ED4C8),
        navBar: Color(hex: 0x1C1E22),
        isDark: true
    )

    /// Abismo Cinza Teal — canvas sólido + accent teal do print (`option`).
    static let abyssAshSolidTeal = AppThemeColors(
        background: Color(hex: 0x141518),
        surface: Color(hex: 0x1C1E22),
        surfaceVariant: Color(hex: 0x25282E),
        textPrimary: Color(hex: 0xE8ECF0),
        textSecondary: Color(hex: 0x9AA3B0),
        textTertiary: Color(hex: 0x6B7382),
        textQuaternary: Color(hex: 0x5A6270),
        hairline: Color(hex: 0x2E323A),
        accent: Color(hex: 0x209088),
        onAccent: Color(hex: 0x0A1412),
        actionAccent: Color(hex: 0x209088),
        onActionAccent: Color(hex: 0x0A1412),
        fabGradientStart: Color(hex: 0x3CB5AB),
        fabGradientEnd: Color(hex: 0x187870),
        folderTint: Color(hex: 0x209088),
        navBar: Color(hex: 0x1C1E22),
        isDark: true
    )

    /// Abismo Cinza Lima — canvas sólido + accent lima do print (`value`).
    static let abyssAshSolidLime = AppThemeColors(
        background: Color(hex: 0x141518),
        surface: Color(hex: 0x1C1E22),
        surfaceVariant: Color(hex: 0x25282E),
        textPrimary: Color(hex: 0xE8ECF0),
        textSecondary: Color(hex: 0x9AA3B0),
        textTertiary: Color(hex: 0x6B7382),
        textQuaternary: Color(hex: 0x5A6270),
        hairline: Color(hex: 0x2E323A),
        accent: Color(hex: 0x98E878),
        onAccent: Color(hex: 0x10180C),
        actionAccent: Color(hex: 0x98E878),
        onActionAccent: Color(hex: 0x10180C),
        fabGradientStart: Color(hex: 0xB4F090),
        fabGradientEnd: Color(hex: 0x6FC050),
        folderTint: Color(hex: 0x98E878),
        navBar: Color(hex: 0x1C1E22),
        isDark: true
    )

    /// Abismo Cinza Petróleo — canvas sólido + accent azul petróleo escuro.
    static let abyssAshSolidPetrol = AppThemeColors(
        background: Color(hex: 0x141518),
        surface: Color(hex: 0x1C1E22),
        surfaceVariant: Color(hex: 0x25282E),
        textPrimary: Color(hex: 0xE8ECF0),
        textSecondary: Color(hex: 0x9AA3B0),
        textTertiary: Color(hex: 0x6B7382),
        textQuaternary: Color(hex: 0x5A6270),
        hairline: Color(hex: 0x2E323A),
        accent: Color(hex: 0x2A7088),
        onAccent: Color(hex: 0x061218),
        actionAccent: Color(hex: 0x2A7088),
        onActionAccent: Color(hex: 0x061218),
        fabGradientStart: Color(hex: 0x3F8FA8),
        fabGradientEnd: Color(hex: 0x1A5568),
        folderTint: Color(hex: 0x2A7088),
        navBar: Color(hex: 0x1C1E22),
        isDark: true
    )

    /// Abismo Cinza Suave — cards iguais ao Abismo Cinza; canvas bem mais claro.
    static let abyssAshSoft = AppThemeColors(
        background: Color(hex: 0x1D2025),
        surface: Color(hex: 0x1C1E22),
        surfaceVariant: Color(hex: 0x25282E),
        textPrimary: Color(hex: 0xE8ECF0),
        textSecondary: Color(hex: 0x9AA3B0),
        textTertiary: Color(hex: 0x6B7382),
        textQuaternary: Color(hex: 0x5A6270),
        hairline: Color(hex: 0x2E323A),
        accent: Color(hex: 0xC9A06E),
        onAccent: Color(hex: 0x16120C),
        actionAccent: Color(hex: 0xC9A06E),
        onActionAccent: Color(hex: 0x16120C),
        fabGradientStart: Color(hex: 0xDBB888),
        fabGradientEnd: Color(hex: 0xA88448),
        folderTint: Color(hex: 0xC9A06E),
        navBar: Color(hex: 0x1C1E22),
        isDark: true
    )

    // MARK: Onyx / Sodalite × Azurite / Malachite / Larimar
    // Accent UI = actionAccent.

    /// Onyx Azurite — preto profundo + aço.
    static let onyxAzurite = mineralActionVariant(
        background: 0x131313, surface: 0x1C1C1C, surfaceVariant: 0x242424, hairline: 0x212121,
        textPrimary: 0xEDEDED, textSecondary: 0x8F8F8F, textTertiary: 0x616161, textQuaternary: 0x4E4E4E,
        accent: 0x3A5468, onAccent: 0xE9EEF2,
        fabGradientStart: 0x617686, fabGradientEnd: 0x314758
    )

    /// Onyx Malachite — preto profundo + verde.
    static let onyxMalachite = mineralActionVariant(
        background: 0x131313, surface: 0x1C1C1C, surfaceVariant: 0x242424, hairline: 0x212121,
        textPrimary: 0xEDEDED, textSecondary: 0x8F8F8F, textTertiary: 0x616161, textQuaternary: 0x4E4E4E,
        accent: 0x2F5450, onAccent: 0xE8F0EE,
        fabGradientStart: 0x587673, fabGradientEnd: 0x274744
    )

    /// Onyx Larimar — preto profundo + ciano aço.
    static let onyxLarimar = mineralActionVariant(
        background: 0x131313, surface: 0x1C1C1C, surfaceVariant: 0x242424, hairline: 0x212121,
        textPrimary: 0xEDEDED, textSecondary: 0x8F8F8F, textTertiary: 0x616161, textQuaternary: 0x4E4E4E,
        accent: 0x2C6B78, onAccent: 0xE7F2F4,
        fabGradientStart: 0x568893, fabGradientEnd: 0x255A66
    )

    /// Sodalite Azurite — azul carvão + aço.
    static let sodaliteAzurite = mineralActionVariant(
        background: 0x15171B, surface: 0x1D2025, surfaceVariant: 0x262A30, hairline: 0x25272B,
        textPrimary: 0xE8EAED, textSecondary: 0x8B92A0, textTertiary: 0x5E6470, textQuaternary: 0x4A505A,
        accent: 0x3A5468, onAccent: 0xE9EEF2,
        fabGradientStart: 0x617686, fabGradientEnd: 0x314758
    )

    /// Sodalite Malachite — azul carvão + verde.
    static let sodaliteMalachite = mineralActionVariant(
        background: 0x15171B, surface: 0x1D2025, surfaceVariant: 0x262A30, hairline: 0x25272B,
        textPrimary: 0xE8EAED, textSecondary: 0x8B92A0, textTertiary: 0x5E6470, textQuaternary: 0x4A505A,
        accent: 0x2F5450, onAccent: 0xE8F0EE,
        fabGradientStart: 0x587673, fabGradientEnd: 0x274744
    )

    /// Sodalite Larimar — azul carvão + ciano aço.
    static let sodaliteLarimar = mineralActionVariant(
        background: 0x15171B, surface: 0x1D2025, surfaceVariant: 0x262A30, hairline: 0x25272B,
        textPrimary: 0xE8EAED, textSecondary: 0x8B92A0, textTertiary: 0x5E6470, textQuaternary: 0x4A505A,
        accent: 0x2C6B78, onAccent: 0xE7F2F4,
        fabGradientStart: 0x568893, fabGradientEnd: 0x255A66
    )

    /// Fundo mineral + accent unificado (UI = ação).
    private static func mineralActionVariant(
        background: UInt32,
        surface: UInt32,
        surfaceVariant: UInt32,
        hairline: UInt32,
        textPrimary: UInt32,
        textSecondary: UInt32,
        textTertiary: UInt32,
        textQuaternary: UInt32,
        accent: UInt32,
        onAccent: UInt32,
        fabGradientStart: UInt32,
        fabGradientEnd: UInt32
    ) -> AppThemeColors {
        AppThemeColors(
            background: Color(hex: background),
            surface: Color(hex: surface),
            surfaceVariant: Color(hex: surfaceVariant),
            textPrimary: Color(hex: textPrimary),
            textSecondary: Color(hex: textSecondary),
            textTertiary: Color(hex: textTertiary),
            textQuaternary: Color(hex: textQuaternary),
            hairline: Color(hex: hairline),
            accent: Color(hex: accent),
            onAccent: Color(hex: onAccent),
            actionAccent: Color(hex: accent),
            onActionAccent: Color(hex: onAccent),
            fabGradientStart: Color(hex: fabGradientStart),
            fabGradientEnd: Color(hex: fabGradientEnd),
            folderTint: Color(hex: accent),
            navBar: Color(hex: surface),
            isDark: true
        )
    }
}

// MARK: - Theme manager

@Observable
final class ThemeManager {
  static let shared = ThemeManager()

  private static let storageKey = "stacked_theme_id"

  /// Primeiro launch → Graphite; quem já escolheu tema mantém a preferência salva.
  var currentId: AppThemeId = .graphite {
    didSet { UserDefaults.standard.set(currentId.rawValue, forKey: Self.storageKey) }
  }

  var colors: AppThemeColors { currentId.colors }

  var usesAtmosphericBackground: Bool { currentId.usesAtmosphericBackground }

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

extension View {
  /// Fundo da tela: gradiente nos temas Abismo, sólido nos demais.
  /// Em listas com `.scrollContentBackground(.hidden)`, use isto no shell e
  /// `Color.clear` na lista para o gradiente aparecer atrás do conteúdo.
  @ViewBuilder
  func stackedThemeBackground(_ theme: ThemeManager) -> some View {
    if let gradient = theme.currentId.atmosphericGradient {
      background(gradient.ignoresSafeArea())
    } else {
      background(theme.colors.background.ignoresSafeArea())
    }
  }

  /// Cor de fundo de lista/scroll: transparente com atmosfera, senão o sólido do tema.
  func stackedListCanvasBackground(_ theme: ThemeManager) -> some View {
    background(theme.usesAtmosphericBackground ? Color.clear : theme.colors.background)
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
