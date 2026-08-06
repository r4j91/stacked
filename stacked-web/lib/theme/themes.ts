/** Paridade lib/theme/app_theme_data.dart + iOS AppTheme.swift */
export type AppThemeId =
  | "graphite"
  | "moonstone"
  | "fog"
  | "fogAmazonite"
  | "cloud"
  | "cloudAmazonite"
  | "obsidian"
  | "anthracite"
  | "slate"
  | "slateCyan"
  | "slateAmazonite"
  | "slateEmber"
  | "slateMoonstone"
  | "titanium"
  | "amazonite"
  | "abyss"
  | "abyssAsh"
  | "abyssAshSolid"
  | "abyssAshSolidMint"
  | "abyssAshSolidTeal"
  | "abyssAshSolidLime"
  | "abyssAshSolidPetrol"
  | "abyssAshSoft"

export type AppThemeColors = {
  background: string
  surface: string
  surfaceVariant: string
  textPrimary: string
  textSecondary: string
  textTertiary: string
  textQuaternary: string
  hairline: string
  accent: string
  accentText: string
  navBar: string
  isDark: boolean
}

export type AppThemePreviewSwatch = {
  background: string
  surface: string
  accent: string
}

export type AppTheme = {
  id: AppThemeId
  name: string
  subtitle: string
  colors: AppThemeColors
  /** Seletor Aparência — hex de mockup nos temas novos (paridade iOS). */
  previewSwatch?: AppThemePreviewSwatch
}

/** Accent amazonite escurecido p/ contraste em fundo claro (ícones/tabs). Fill ainda lê como petróleo. */
const LIGHT_AMAZONITE_ACCENT = "#3F7076"

export const themes: Record<AppThemeId, AppTheme> = {
  graphite: {
    id: "graphite",
    name: "Graphite",
    subtitle: "Escuro",
    colors: {
      background: "#1A1B1E",
      surface: "#242529",
      surfaceVariant: "#2C2D33",
      textPrimary: "#F2F3F5",
      textSecondary: "#9296A0",
      textTertiary: "#6B6E76",
      textQuaternary: "#6B6E76",
      hairline: "#6B6E76",
      accent: "#5FD3DC",
      accentText: "#0A0A0A",
      navBar: "#242529",
      isDark: true,
    },
  },
  moonstone: {
    id: "moonstone",
    name: "Moonstone",
    subtitle: "Claro",
    previewSwatch: {
      background: "#EEF1F6",
      surface: "#F5F7FA",
      accent: "#3F6F96",
    },
    colors: {
      // Sem #FFFFFF — superfície off-white; texto terciário escurecido (≥4.5:1)
      background: "#EEF1F6",
      surface: "#F5F7FA",
      surfaceVariant: "#E2E6EE",
      textPrimary: "#1A1D28",
      textSecondary: "#4A5163",
      textTertiary: "#656A78",
      textQuaternary: "#7A8091",
      hairline: "#8A909C",
      accent: "#3F6F96",
      accentText: "#FFFFFF",
      navBar: "#F5F7FA",
      isDark: false,
    },
  },
  fog: {
    id: "fog",
    name: "Fog",
    subtitle: "Cinza frio claro",
    previewSwatch: {
      background: "#E6E8ED",
      surface: "#EEEFF3",
      accent: "#2A9AA3",
    },
    colors: {
      background: "#E6E8ED",
      surface: "#EEEFF3",
      surfaceVariant: "#DCDFE6",
      textPrimary: "#1A1C22",
      textSecondary: "#4E535E",
      textTertiary: "#5C616C",
      textQuaternary: "#727882",
      hairline: "#8A909C",
      accent: "#2A9AA3",
      accentText: "#F4FBFC",
      navBar: "#EEEFF3",
      isDark: false,
    },
  },
  fogAmazonite: {
    id: "fogAmazonite",
    name: "Fog Amazonite",
    subtitle: "Cinza frio · petróleo",
    previewSwatch: {
      background: "#E6E8ED",
      surface: "#EEEFF3",
      accent: "#86ABB0",
    },
    colors: {
      background: "#E6E8ED",
      surface: "#EEEFF3",
      surfaceVariant: "#DCDFE6",
      textPrimary: "#1A1C22",
      textSecondary: "#4E535E",
      textTertiary: "#5C616C",
      textQuaternary: "#727882",
      hairline: "#8A909C",
      accent: LIGHT_AMAZONITE_ACCENT,
      accentText: "#F4FBFC",
      navBar: "#EEEFF3",
      isDark: false,
    },
  },
  cloud: {
    id: "cloud",
    name: "Cloud",
    subtitle: "Semi-claro",
    previewSwatch: {
      background: "#D5D8DE",
      surface: "#E0E3E9",
      accent: "#268F97",
    },
    colors: {
      background: "#D5D8DE",
      surface: "#E0E3E9",
      surfaceVariant: "#C8CCD4",
      textPrimary: "#17191E",
      textSecondary: "#454A54",
      textTertiary: "#555C66",
      textQuaternary: "#6B727C",
      hairline: "#7A818C",
      accent: "#268F97",
      accentText: "#F2FAFB",
      navBar: "#E0E3E9",
      isDark: false,
    },
  },
  cloudAmazonite: {
    id: "cloudAmazonite",
    name: "Cloud Amazonite",
    subtitle: "Semi-claro · petróleo",
    previewSwatch: {
      background: "#D5D8DE",
      surface: "#E0E3E9",
      accent: "#86ABB0",
    },
    colors: {
      background: "#D5D8DE",
      surface: "#E0E3E9",
      surfaceVariant: "#C8CCD4",
      textPrimary: "#17191E",
      textSecondary: "#454A54",
      textTertiary: "#555C66",
      textQuaternary: "#6B727C",
      hairline: "#7A818C",
      accent: LIGHT_AMAZONITE_ACCENT,
      accentText: "#F2FAFB",
      navBar: "#E0E3E9",
      isDark: false,
    },
  },
  obsidian: {
    id: "obsidian",
    name: "Obsidian",
    subtitle: "Preto puro",
    colors: {
      background: "#0D0D0D",
      surface: "#161616",
      surfaceVariant: "#222222",
      textPrimary: "#F0F0F0",
      textSecondary: "#888888",
      textTertiary: "#6E6E6E",
      textQuaternary: "#6E6E6E",
      hairline: "#6E6E6E",
      accent: "#00D4D4",
      accentText: "#0A0A0A",
      navBar: "#111111",
      isDark: true,
    },
  },
  anthracite: {
    id: "anthracite",
    name: "Anthracite",
    subtitle: "Cinza premium",
    previewSwatch: {
      background: "#1A1A1A",
      surface: "#242424",
      accent: "#00D4D4",
    },
    colors: {
      background: "#1A1A1A",
      surface: "#242424",
      surfaceVariant: "#2E2E2E",
      textPrimary: "#F0F0F0",
      textSecondary: "#8A8A8A",
      textTertiary: "#5A5A5A",
      textQuaternary: "#5A5A5A",
      hairline: "#5A5A5A",
      accent: "#00D4D4",
      accentText: "#1A1A1A",
      navBar: "#1F1F1F",
      isDark: true,
    },
  },
  slate: {
    id: "slate",
    name: "Slate",
    subtitle: "Monocromático",
    colors: {
      background: "#18181E",
      surface: "#212127",
      surfaceVariant: "#2F2F36",
      textPrimary: "#F2F2F4",
      textSecondary: "#9A9AA2",
      textTertiary: "#65656D",
      textQuaternary: "#65656D",
      hairline: "#65656D",
      accent: "#E8E8EC",
      accentText: "#0A0A0A",
      navBar: "#18181E",
      isDark: true,
    },
  },
  slateCyan: {
    id: "slateCyan",
    name: "Slate Cyan",
    subtitle: "Ciano Obsidian",
    previewSwatch: {
      background: "#18181E",
      surface: "#212127",
      accent: "#00D4D4",
    },
    colors: {
      background: "#18181E",
      surface: "#212127",
      surfaceVariant: "#2F2F36",
      textPrimary: "#F2F2F4",
      textSecondary: "#9A9AA2",
      textTertiary: "#65656D",
      textQuaternary: "#65656D",
      hairline: "#65656D",
      accent: "#00D4D4",
      accentText: "#0A0A0A",
      navBar: "#18181E",
      isDark: true,
    },
  },
  slateAmazonite: {
    id: "slateAmazonite",
    name: "Slate Amazonite",
    subtitle: "Petróleo",
    previewSwatch: {
      background: "#18181E",
      surface: "#212127",
      accent: "#86ABB0",
    },
    colors: {
      background: "#18181E",
      surface: "#212127",
      surfaceVariant: "#2F2F36",
      textPrimary: "#F2F2F4",
      textSecondary: "#9A9AA2",
      textTertiary: "#65656D",
      textQuaternary: "#65656D",
      hairline: "#65656D",
      accent: "#86ABB0",
      accentText: "#0A1012",
      navBar: "#18181E",
      isDark: true,
    },
  },
  /** Fundo Slate + laranja vivo (#F06B2C). */
  slateEmber: {
    id: "slateEmber",
    name: "Slate Ember",
    subtitle: "Laranja",
    previewSwatch: {
      background: "#18181E",
      surface: "#212127",
      accent: "#F06B2C",
    },
    colors: {
      background: "#18181E",
      surface: "#212127",
      surfaceVariant: "#2F2F36",
      textPrimary: "#F2F2F4",
      textSecondary: "#9A9AA2",
      textTertiary: "#65656D",
      textQuaternary: "#65656D",
      hairline: "#65656D",
      accent: "#F06B2C",
      accentText: "#1A100C",
      navBar: "#18181E",
      isDark: true,
    },
  },
  /** Fundo Slate + aço luminoso no escuro. */
  slateMoonstone: {
    id: "slateMoonstone",
    name: "Slate Moonstone",
    subtitle: "Aço",
    previewSwatch: {
      background: "#18181E",
      surface: "#212127",
      accent: "#4F8BB8",
    },
    colors: {
      background: "#18181E",
      surface: "#212127",
      surfaceVariant: "#2F2F36",
      textPrimary: "#F2F2F4",
      textSecondary: "#9A9AA2",
      textTertiary: "#65656D",
      textQuaternary: "#65656D",
      hairline: "#65656D",
      accent: "#4F8BB8",
      accentText: "#FFFFFF",
      navBar: "#18181E",
      isDark: true,
    },
  },
  titanium: {
    id: "titanium",
    name: "Titanium",
    subtitle: "Escuro metálico",
    previewSwatch: {
      background: "#0A0C10",
      surface: "#171B21",
      accent: "#8FA8C7",
    },
    colors: {
      background: "#101318",
      surface: "#171B21",
      surfaceVariant: "#1E242C",
      textPrimary: "#E6EAF0",
      textSecondary: "#98A2B0",
      textTertiary: "#616B7A",
      textQuaternary: "#616B7A",
      hairline: "#616B7A",
      accent: "#8FA8C7",
      accentText: "#0E1319",
      navBar: "#171B21",
      isDark: true,
    },
  },
  amazonite: {
    id: "amazonite",
    name: "Amazonite",
    subtitle: "Petróleo",
    previewSwatch: {
      background: "#0B1113",
      surface: "#12191C",
      accent: "#86ABB0",
    },
    colors: {
      background: "#0B1113",
      surface: "#12191C",
      surfaceVariant: "#182124",
      textPrimary: "#E5EBEC",
      textSecondary: "#8EA0A3",
      textTertiary: "#59696C",
      textQuaternary: "#59696C",
      hairline: "#59696C",
      accent: "#86ABB0",
      accentText: "#0A1012",
      navBar: "#12191C",
      isDark: true,
    },
  },
  /** Petróleo-noite com accent mint — paridade iOS Abismo. */
  abyss: {
    id: "abyss",
    name: "Abismo",
    subtitle: "Petróleo-noite · mint",
    previewSwatch: {
      background: "#0E1418",
      surface: "#172026",
      accent: "#6ED4C8",
    },
    colors: {
      background: "#0E1418",
      surface: "#172026",
      surfaceVariant: "#1E2A31",
      textPrimary: "#E8EEF1",
      textSecondary: "#8FA3AD",
      textTertiary: "#667A84",
      textQuaternary: "#556870",
      hairline: "#2A3840",
      accent: "#6ED4C8",
      accentText: "#0A1214",
      navBar: "#172026",
      isDark: true,
    },
  },
  /** Atmosfera neutra + accent âmbar — paridade iOS Abismo Cinza. */
  abyssAsh: {
    id: "abyssAsh",
    name: "Abismo Cinza",
    subtitle: "Noite neutra · âmbar",
    previewSwatch: {
      background: "#141518",
      surface: "#1C1E22",
      accent: "#C9A06E",
    },
    colors: {
      background: "#141518",
      surface: "#1C1E22",
      surfaceVariant: "#25282E",
      textPrimary: "#E8ECF0",
      textSecondary: "#9AA3B0",
      textTertiary: "#6B7382",
      textQuaternary: "#5A6270",
      hairline: "#2E323A",
      accent: "#C9A06E",
      accentText: "#16120C",
      navBar: "#1C1E22",
      isDark: true,
    },
  },
  /** Mesmas cores do Abismo Cinza, sem degradê — fundo sólido #141518. */
  abyssAshSolid: {
    id: "abyssAshSolid",
    name: "Abismo Cinza Sólido",
    subtitle: "Fundo sólido · âmbar",
    previewSwatch: {
      background: "#141518",
      surface: "#1C1E22",
      accent: "#C9A06E",
    },
    colors: {
      background: "#141518",
      surface: "#1C1E22",
      surfaceVariant: "#25282E",
      textPrimary: "#E8ECF0",
      textSecondary: "#9AA3B0",
      textTertiary: "#6B7382",
      textQuaternary: "#5A6270",
      hairline: "#2E323A",
      accent: "#C9A06E",
      accentText: "#16120C",
      navBar: "#1C1E22",
      isDark: true,
    },
  },
  /** Canvas sólido do Cinza Sólido + accent mint do Abismo. */
  abyssAshSolidMint: {
    id: "abyssAshSolidMint",
    name: "Abismo Cinza Mint",
    subtitle: "Fundo sólido · mint",
    previewSwatch: {
      background: "#141518",
      surface: "#1C1E22",
      accent: "#6ED4C8",
    },
    colors: {
      background: "#141518",
      surface: "#1C1E22",
      surfaceVariant: "#25282E",
      textPrimary: "#E8ECF0",
      textSecondary: "#9AA3B0",
      textTertiary: "#6B7382",
      textQuaternary: "#5A6270",
      hairline: "#2E323A",
      accent: "#6ED4C8",
      accentText: "#0A1214",
      navBar: "#1C1E22",
      isDark: true,
    },
  },
  /** Canvas sólido + accent teal amostrado do print (`option`). */
  abyssAshSolidTeal: {
    id: "abyssAshSolidTeal",
    name: "Abismo Cinza Teal",
    subtitle: "Fundo sólido · teal",
    previewSwatch: {
      background: "#141518",
      surface: "#1C1E22",
      accent: "#209088",
    },
    colors: {
      background: "#141518",
      surface: "#1C1E22",
      surfaceVariant: "#25282E",
      textPrimary: "#E8ECF0",
      textSecondary: "#9AA3B0",
      textTertiary: "#6B7382",
      textQuaternary: "#5A6270",
      hairline: "#2E323A",
      accent: "#209088",
      accentText: "#0A1412",
      navBar: "#1C1E22",
      isDark: true,
    },
  },
  /** Canvas sólido + accent lima amostrado do print (`value`). */
  abyssAshSolidLime: {
    id: "abyssAshSolidLime",
    name: "Abismo Cinza Lima",
    subtitle: "Fundo sólido · lima",
    previewSwatch: {
      background: "#141518",
      surface: "#1C1E22",
      accent: "#98E878",
    },
    colors: {
      background: "#141518",
      surface: "#1C1E22",
      surfaceVariant: "#25282E",
      textPrimary: "#E8ECF0",
      textSecondary: "#9AA3B0",
      textTertiary: "#6B7382",
      textQuaternary: "#5A6270",
      hairline: "#2E323A",
      accent: "#98E878",
      accentText: "#10180C",
      navBar: "#1C1E22",
      isDark: true,
    },
  },
  /** Canvas sólido + accent azul petróleo escuro. */
  abyssAshSolidPetrol: {
    id: "abyssAshSolidPetrol",
    name: "Abismo Cinza Petróleo",
    subtitle: "Fundo sólido · petróleo",
    previewSwatch: {
      background: "#141518",
      surface: "#1C1E22",
      accent: "#2A7088",
    },
    colors: {
      background: "#141518",
      surface: "#1C1E22",
      surfaceVariant: "#25282E",
      textPrimary: "#E8ECF0",
      textSecondary: "#9AA3B0",
      textTertiary: "#6B7382",
      textQuaternary: "#5A6270",
      hairline: "#2E323A",
      accent: "#2A7088",
      accentText: "#061218",
      navBar: "#1C1E22",
      isDark: true,
    },
  },
  /** Abismo Cinza Suave — cards iguais ao Abismo Cinza; canvas bem mais claro. */
  abyssAshSoft: {
    id: "abyssAshSoft",
    name: "Abismo Cinza Suave",
    subtitle: "Cinza mais claro · âmbar",
    previewSwatch: {
      background: "#1D2025",
      surface: "#1C1E22",
      accent: "#C9A06E",
    },
    colors: {
      background: "#1D2025",
      surface: "#1C1E22",
      surfaceVariant: "#25282E",
      textPrimary: "#E8ECF0",
      textSecondary: "#9AA3B0",
      textTertiary: "#6B7382",
      textQuaternary: "#5A6270",
      hairline: "#2E323A",
      accent: "#C9A06E",
      accentText: "#16120C",
      navBar: "#1C1E22",
      isDark: true,
    },
  },
}

/** Paridade iOS AppThemeId.recommended */
export const RECOMMENDED_THEME_IDS: AppThemeId[] = [
  "abyss",
  "abyssAsh",
  "abyssAshSolid",
  "abyssAshSolidMint",
  "abyssAshSolidTeal",
  "abyssAshSolidLime",
  "abyssAshSolidPetrol",
  "abyssAshSoft",
  "slate",
  "slateEmber",
  "graphite",
  "moonstone",
  "fog",
]

export const DEFAULT_THEME_ID: AppThemeId = "graphite"

export function isAppThemeId(value: string): value is AppThemeId {
  return value in themes
}

export function applyThemeToDocument(themeId: AppThemeId) {
  const { colors } = themes[themeId]
  const root = document.documentElement
  const isSlate = themeId === "slate"
  const isLight = !colors.isDark

  root.dataset.theme = themeId
  root.style.setProperty("color-scheme", isLight ? "light" : "dark")
  root.style.setProperty("--color-bg", colors.background)
  root.style.setProperty("--color-surface", colors.surface)
  root.style.setProperty("--color-surface-variant", colors.surfaceVariant)
  root.style.setProperty(
    "--color-surface-hover",
    isLight ? colors.surfaceVariant : "#35353d",
  )
  root.style.setProperty("--color-text", colors.textPrimary)
  root.style.setProperty("--color-text-secondary", colors.textSecondary)
  root.style.setProperty("--color-text-tertiary", colors.textTertiary)
  root.style.setProperty("--color-text-quaternary", colors.textQuaternary)
  root.style.setProperty("--color-hairline", colors.hairline)
  root.style.setProperty("--color-accent", colors.accent)
  root.style.setProperty("--color-accent-text", colors.accentText)
  root.style.setProperty(
    "--color-border",
    isLight ? "rgba(0, 0, 0, 0.10)" : "rgba(255, 255, 255, 0.08)",
  )
  root.style.setProperty(
    "--color-border-strong",
    isLight ? "rgba(0, 0, 0, 0.16)" : "rgba(255, 255, 255, 0.12)",
  )

  // Datas / prioridades: em claro, tom um pouco mais fechado (menos “estourado”)
  root.style.setProperty(
    "--color-date-upcoming",
    isLight ? "#5A6470" : "#8a9099",
  )
  root.style.setProperty(
    "--color-deadline",
    isLight ? "#4A6B88" : "#7b9bb8",
  )
  root.style.setProperty("--color-p1", isLight ? "#D14B52" : "#ef5a5f")
  root.style.setProperty("--color-p2", isLight ? "#D4891A" : "#f5a623")
  root.style.setProperty("--color-p3", isLight ? "#3A88D4" : "#4d9fec")
  root.style.setProperty("--color-due-today", isLight ? "#1A9E94" : "#2ec4b6")
  root.style.setProperty("--color-overdue", isLight ? "#D14B52" : "#ef5a5f")
  root.style.setProperty("--color-tag-green", isLight ? "#6BB34F" : "#8fd46b")
  root.style.setProperty("--chip-fill-pct", isLight ? "10%" : "14%")
  root.style.setProperty("--chip-border-pct", isLight ? "28%" : "40%")
  root.dataset.colorScheme = isLight ? "light" : "dark"

  if (isSlate) {
    root.style.setProperty("--color-nav-indicator", colors.surfaceVariant)
    root.style.setProperty("--color-focus-ring", "rgba(232, 232, 236, 0.55)")
    root.style.setProperty("--color-btn-primary-bg", colors.textPrimary)
    root.style.setProperty("--color-btn-primary-fg", colors.background)
    root.style.setProperty("--color-btn-secondary-bg", colors.surfaceVariant)
    root.style.setProperty("--color-btn-secondary-fg", colors.textPrimary)
    root.style.setProperty("--color-btn-secondary-border", "rgba(255, 255, 255, 0.08)")
    root.style.setProperty("--color-btn-secondary-hover-bg", "#35353d")
    root.style.setProperty("--color-nav-badge", colors.textSecondary)
  } else {
    root.style.setProperty("--color-nav-indicator", `${colors.accent}24`)
    root.style.setProperty("--color-focus-ring", colors.accent)
    root.style.setProperty("--color-btn-primary-bg", colors.accent)
    root.style.setProperty("--color-btn-primary-fg", colors.accentText)
    // Claro: surface elevada + borda mais presente (variant some no bg)
    root.style.setProperty(
      "--color-btn-secondary-bg",
      isLight ? colors.surface : colors.surfaceVariant,
    )
    root.style.setProperty("--color-btn-secondary-fg", colors.textPrimary)
    root.style.setProperty(
      "--color-btn-secondary-border",
      isLight ? "rgba(0, 0, 0, 0.14)" : "rgba(255, 255, 255, 0.08)",
    )
    root.style.setProperty(
      "--color-btn-secondary-hover-bg",
      isLight ? colors.surfaceVariant : "#35353d",
    )
    root.style.setProperty("--color-nav-badge", colors.textSecondary)
  }

  root.style.setProperty(
    "--color-hover-overlay",
    isLight ? "rgba(0, 0, 0, 0.05)" : "rgba(255, 255, 255, 0.04)",
  )
  root.style.setProperty(
    "--color-hover-overlay-strong",
    isLight ? "rgba(0, 0, 0, 0.08)" : "rgba(255, 255, 255, 0.07)",
  )
  root.style.setProperty("--color-placeholder", colors.textSecondary)
  root.style.setProperty(
    "--color-selection-bg",
    isLight ? `${colors.accent}28` : "rgba(232, 232, 236, 0.2)",
  )
  root.style.setProperty(
    "--color-scrollbar-thumb",
    isLight ? "rgba(0, 0, 0, 0.18)" : "rgba(255, 255, 255, 0.14)",
  )

  if (isSlate) {
    root.style.setProperty("--color-selected-bg", colors.surfaceVariant)
    root.style.setProperty("--color-selected-fg", colors.textPrimary)
  } else {
    root.style.setProperty("--color-selected-bg", colors.accent)
    root.style.setProperty("--color-selected-fg", colors.accentText)
  }

  root.style.setProperty("--color-inspector-bg", colors.surface)

  let themeColorMeta = document.querySelector('meta[name="theme-color"]')
  if (!themeColorMeta) {
    themeColorMeta = document.createElement("meta")
    themeColorMeta.setAttribute("name", "theme-color")
    document.head.appendChild(themeColorMeta)
  }
  themeColorMeta.setAttribute("content", colors.background)
}
