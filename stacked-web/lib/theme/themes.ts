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
  | "slateJade"
  | "ashCyan"
  | "ashAmazonite"
  | "titanium"
  | "amazonite"
  | "basalt"
  | "basaltAmazonite"
  | "basaltSky"
  | "basaltMoonstone"
  | "basaltEmber"
  | "basaltGold"
  | "basaltJade"
  | "basaltViolet"
  | "abyss"
  | "abyssAsh"

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
  /** Fundo Slate + sage do Basalt Jade. */
  slateJade: {
    id: "slateJade",
    name: "Slate Jade",
    subtitle: "Jade",
    previewSwatch: {
      background: "#18181E",
      surface: "#212127",
      accent: "#7FA89A",
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
      accent: "#7FA89A",
      accentText: "#0C1412",
      navBar: "#18181E",
      isDark: true,
    },
  },
  ashCyan: {
    id: "ashCyan",
    name: "Ash Cyan",
    subtitle: "Cinza Things · ciano suave",
    previewSwatch: {
      background: "#191D22",
      surface: "#22272E",
      accent: "#6BB5BA",
    },
    colors: {
      background: "#191D22",
      surface: "#22272E",
      surfaceVariant: "#2C333B",
      textPrimary: "#E6EBEF",
      textSecondary: "#96A0AA",
      textTertiary: "#66707A",
      textQuaternary: "#66707A",
      hairline: "#66707A",
      accent: "#6BB5BA",
      accentText: "#0C1214",
      navBar: "#191D22",
      isDark: true,
    },
  },
  ashAmazonite: {
    id: "ashAmazonite",
    name: "Ash Amazonite",
    subtitle: "Cinza Things · petróleo",
    previewSwatch: {
      background: "#191D22",
      surface: "#22272E",
      accent: "#9DC2C7",
    },
    colors: {
      background: "#191D22",
      surface: "#22272E",
      surfaceVariant: "#2C333B",
      textPrimary: "#E6EBEF",
      textSecondary: "#96A0AA",
      textTertiary: "#66707A",
      textQuaternary: "#66707A",
      hairline: "#66707A",
      accent: "#9DC2C7",
      accentText: "#0C1416",
      navBar: "#191D22",
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
  /** Things 3–like charcoal (#1C222D) — cinza nos botões / accent. */
  basalt: {
    id: "basalt",
    name: "Basalt",
    subtitle: "Cinza Things",
    previewSwatch: {
      background: "#1C222D",
      surface: "#282E3A",
      accent: "#A8B0BC",
    },
    colors: {
      background: "#1C222D",
      surface: "#282E3A",
      surfaceVariant: "#323946",
      textPrimary: "#E8ECF2",
      textSecondary: "#9AA3B0",
      textTertiary: "#6B7382",
      textQuaternary: "#6B7382",
      hairline: "#6B7382",
      accent: "#A8B0BC",
      accentText: "#12161E",
      navBar: "#282E3A",
      isDark: true,
    },
  },
  /** Mesmo fundo Basalt + petróleo Amazonite. */
  basaltAmazonite: {
    id: "basaltAmazonite",
    name: "Basalt Amazonite",
    subtitle: "Things · petróleo",
    previewSwatch: {
      background: "#1C222D",
      surface: "#282E3A",
      accent: "#86ABB0",
    },
    colors: {
      background: "#1C222D",
      surface: "#282E3A",
      surfaceVariant: "#323946",
      textPrimary: "#E8ECF2",
      textSecondary: "#9AA3B0",
      textTertiary: "#6B7382",
      textQuaternary: "#6B7382",
      hairline: "#6B7382",
      accent: "#86ABB0",
      accentText: "#0A1012",
      navBar: "#282E3A",
      isDark: true,
    },
  },
  /** Mesmo fundo Basalt + petróleo Amazonite (antes azul FAB #5B9FE8). */
  basaltSky: {
    id: "basaltSky",
    name: "Basalt Sky",
    subtitle: "Things · petróleo",
    previewSwatch: {
      background: "#1C222D",
      surface: "#282E3A",
      accent: "#86ABB0",
    },
    colors: {
      background: "#1C222D",
      surface: "#282E3A",
      surfaceVariant: "#323946",
      textPrimary: "#E8ECF2",
      textSecondary: "#9AA3B0",
      textTertiary: "#6B7382",
      textQuaternary: "#6B7382",
      hairline: "#6B7382",
      accent: "#86ABB0",
      accentText: "#0A1012",
      navBar: "#282E3A",
      isDark: true,
    },
  },
  /** Fundo Basalt + aço luminoso no escuro. */
  basaltMoonstone: {
    id: "basaltMoonstone",
    name: "Basalt Moonstone",
    subtitle: "Things · aço",
    previewSwatch: {
      background: "#1C222D",
      surface: "#282E3A",
      accent: "#4F8BB8",
    },
    colors: {
      background: "#1C222D",
      surface: "#282E3A",
      surfaceVariant: "#323946",
      textPrimary: "#E8ECF2",
      textSecondary: "#9AA3B0",
      textTertiary: "#6B7382",
      textQuaternary: "#6B7382",
      hairline: "#6B7382",
      accent: "#4F8BB8",
      accentText: "#FFFFFF",
      navBar: "#282E3A",
      isDark: true,
    },
  },
  /** Fundo Basalt + mesmo laranja do Slate Ember. */
  basaltEmber: {
    id: "basaltEmber",
    name: "Basalt Ember",
    subtitle: "Things · laranja",
    previewSwatch: {
      background: "#1C222D",
      surface: "#282E3A",
      accent: "#F06B2C",
    },
    colors: {
      background: "#1C222D",
      surface: "#282E3A",
      surfaceVariant: "#323946",
      textPrimary: "#E8ECF2",
      textSecondary: "#9AA3B0",
      textTertiary: "#6B7382",
      textQuaternary: "#6B7382",
      hairline: "#6B7382",
      accent: "#F06B2C",
      accentText: "#1A100C",
      navBar: "#282E3A",
      isDark: true,
    },
  },
  /** Fundo Basalt + champagne (luxo discreto). */
  basaltGold: {
    id: "basaltGold",
    name: "Basalt Gold",
    subtitle: "Things · champagne",
    previewSwatch: {
      background: "#1C222D",
      surface: "#282E3A",
      accent: "#C2A67A",
    },
    colors: {
      background: "#1C222D",
      surface: "#282E3A",
      surfaceVariant: "#323946",
      textPrimary: "#E8ECF2",
      textSecondary: "#9AA3B0",
      textTertiary: "#6B7382",
      textQuaternary: "#6B7382",
      hairline: "#6B7382",
      accent: "#C2A67A",
      accentText: "#16120C",
      navBar: "#282E3A",
      isDark: true,
    },
  },
  /** Fundo Basalt + sage suave. */
  basaltJade: {
    id: "basaltJade",
    name: "Basalt Jade",
    subtitle: "Things · jade",
    previewSwatch: {
      background: "#1C222D",
      surface: "#282E3A",
      accent: "#7FA89A",
    },
    colors: {
      background: "#1C222D",
      surface: "#282E3A",
      surfaceVariant: "#323946",
      textPrimary: "#E8ECF2",
      textSecondary: "#9AA3B0",
      textTertiary: "#6B7382",
      textQuaternary: "#6B7382",
      hairline: "#6B7382",
      accent: "#7FA89A",
      accentText: "#0C1412",
      navBar: "#282E3A",
      isDark: true,
    },
  },
  /** Fundo Basalt + ametista suave. */
  basaltViolet: {
    id: "basaltViolet",
    name: "Basalt Violet",
    subtitle: "Things · ametista",
    previewSwatch: {
      background: "#1C222D",
      surface: "#282E3A",
      accent: "#9A8BB5",
    },
    colors: {
      background: "#1C222D",
      surface: "#282E3A",
      surfaceVariant: "#323946",
      textPrimary: "#E8ECF2",
      textSecondary: "#9AA3B0",
      textTertiary: "#6B7382",
      textQuaternary: "#6B7382",
      hairline: "#6B7382",
      accent: "#9A8BB5",
      accentText: "#120E18",
      navBar: "#282E3A",
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
  /** Mesma atmosfera em cinza neutro — paridade iOS Abismo Cinza. */
  abyssAsh: {
    id: "abyssAsh",
    name: "Abismo Cinza",
    subtitle: "Noite neutra · cinza",
    previewSwatch: {
      background: "#141518",
      surface: "#1C1E22",
      accent: "#A8B0BC",
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
      accent: "#A8B0BC",
      accentText: "#12161E",
      navBar: "#1C1E22",
      isDark: true,
    },
  },
}

/** Paridade iOS AppThemeId.recommended */
export const RECOMMENDED_THEME_IDS: AppThemeId[] = [
  "abyss",
  "abyssAsh",
  "slate",
  "slateEmber",
  "graphite",
  "moonstone",
  "fog",
  "basalt",
  "basaltEmber",
  "basaltGold",
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
