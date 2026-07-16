/** Paridade lib/theme/app_theme_data.dart + iOS AppTheme.swift */
export type AppThemeId =
  | "graphite"
  | "moonstone"
  | "midnight"
  | "obsidian"
  | "slate"
  | "slateCyan"
  | "slateAmazonite"
  | "titanium"
  | "sodalite"
  | "hematite"

export type AppThemeColors = {
  background: string
  surface: string
  surfaceVariant: string
  textPrimary: string
  textSecondary: string
  textTertiary: string
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
    colors: {
      background: "#F2F4F7",
      surface: "#FFFFFF",
      surfaceVariant: "#E8ECF2",
      textPrimary: "#1C2033",
      textSecondary: "#52596E",
      textTertiary: "#757D92",
      accent: "#3B485B",
      accentText: "#FFFFFF",
      navBar: "#FFFFFF",
      isDark: false,
    },
  },
  midnight: {
    id: "midnight",
    name: "Midnight",
    subtitle: "Escuro premium",
    colors: {
      background: "#0A0A0F",
      surface: "#12121A",
      surfaceVariant: "#1E1E2E",
      textPrimary: "#E8E8F0",
      textSecondary: "#7070A0",
      textTertiary: "#4A4A6A",
      accent: "#6C63FF",
      accentText: "#FFFFFF",
      navBar: "#0F0F18",
      isDark: true,
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
      accent: "#00D4D4",
      accentText: "#0A0A0A",
      navBar: "#111111",
      isDark: true,
    },
  },
  slate: {
    id: "slate",
    name: "Slate",
    subtitle: "Monocromático",
    colors: {
      background: "#16161A",
      surface: "#1C1C20",
      surfaceVariant: "#2C2C32",
      textPrimary: "#F2F2F4",
      textSecondary: "#9A9AA2",
      textTertiary: "#65656D",
      accent: "#E8E8EC",
      accentText: "#0A0A0A",
      navBar: "#16161A",
      isDark: true,
    },
  },
  slateCyan: {
    id: "slateCyan",
    name: "Slate Cyan",
    subtitle: "Ciano Obsidian",
    previewSwatch: {
      background: "#16161A",
      surface: "#1C1C20",
      accent: "#00D4D4",
    },
    colors: {
      background: "#16161A",
      surface: "#1C1C20",
      surfaceVariant: "#2C2C32",
      textPrimary: "#F2F2F4",
      textSecondary: "#9A9AA2",
      textTertiary: "#65656D",
      accent: "#00D4D4",
      accentText: "#0A0A0A",
      navBar: "#16161A",
      isDark: true,
    },
  },
  slateAmazonite: {
    id: "slateAmazonite",
    name: "Slate Amazonite",
    subtitle: "Petróleo",
    previewSwatch: {
      background: "#16161A",
      surface: "#1C1C20",
      accent: "#86ABB0",
    },
    colors: {
      background: "#16161A",
      surface: "#1C1C20",
      surfaceVariant: "#2C2C32",
      textPrimary: "#F2F2F4",
      textSecondary: "#9A9AA2",
      textTertiary: "#65656D",
      accent: "#86ABB0",
      accentText: "#0A1012",
      navBar: "#16161A",
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
      accent: "#8FA8C7",
      accentText: "#0E1319",
      navBar: "#171B21",
      isDark: true,
    },
  },
  sodalite: {
    id: "sodalite",
    name: "Sodalite",
    subtitle: "Azul profundo",
    previewSwatch: {
      background: "#070A12",
      surface: "#101626",
      accent: "#A9BAD9",
    },
    colors: {
      background: "#0A0E19",
      surface: "#101626",
      surfaceVariant: "#161E33",
      textPrimary: "#E7EAF3",
      textSecondary: "#8E97B2",
      textTertiary: "#5A6480",
      accent: "#A9BAD9",
      accentText: "#0A0F1D",
      navBar: "#101626",
      isDark: true,
    },
  },
  hematite: {
    id: "hematite",
    name: "Hematite",
    subtitle: "Preto polido",
    previewSwatch: {
      background: "#060707",
      surface: "#131416",
      accent: "#C4CCD6",
    },
    colors: {
      background: "#0A0B0C",
      surface: "#131416",
      surfaceVariant: "#1A1C1F",
      textPrimary: "#ECEEF1",
      textSecondary: "#93999F",
      textTertiary: "#5C6167",
      accent: "#C4CCD6",
      accentText: "#0B0C0E",
      navBar: "#131416",
      isDark: true,
    },
  },
}

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
  root.style.setProperty("--color-bg", colors.background)
  root.style.setProperty("--color-surface", colors.surface)
  root.style.setProperty("--color-surface-variant", colors.surfaceVariant)
  root.style.setProperty("--color-surface-hover", colors.isDark ? "#35353d" : "#DDE2EA")
  root.style.setProperty("--color-text", colors.textPrimary)
  root.style.setProperty("--color-text-secondary", colors.textSecondary)
  root.style.setProperty("--color-text-tertiary", colors.textTertiary)
  root.style.setProperty("--color-accent", colors.accent)
  root.style.setProperty("--color-accent-text", colors.accentText)
  root.style.setProperty(
    "--color-border",
    isLight ? "rgba(0, 0, 0, 0.08)" : "rgba(255, 255, 255, 0.08)",
  )
  root.style.setProperty(
    "--color-border-strong",
    isLight ? "rgba(0, 0, 0, 0.14)" : "rgba(255, 255, 255, 0.12)",
  )

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
    root.style.setProperty("--color-btn-secondary-bg", colors.surfaceVariant)
    root.style.setProperty("--color-btn-secondary-fg", colors.textPrimary)
    root.style.setProperty(
      "--color-btn-secondary-border",
      isLight ? "rgba(0, 0, 0, 0.08)" : "rgba(255, 255, 255, 0.08)",
    )
    root.style.setProperty(
      "--color-btn-secondary-hover-bg",
      isLight ? "#DDE2EA" : "#35353d",
    )
    root.style.setProperty("--color-nav-badge", colors.textSecondary)
  }

  root.style.setProperty(
    "--color-hover-overlay",
    isLight ? "rgba(0, 0, 0, 0.04)" : "rgba(255, 255, 255, 0.04)",
  )
  root.style.setProperty(
    "--color-hover-overlay-strong",
    isLight ? "rgba(0, 0, 0, 0.07)" : "rgba(255, 255, 255, 0.07)",
  )
  root.style.setProperty("--color-placeholder", colors.textSecondary)
  root.style.setProperty(
    "--color-selection-bg",
    isLight ? `${colors.accent}28` : "rgba(232, 232, 236, 0.2)",
  )
  root.style.setProperty(
    "--color-scrollbar-thumb",
    isLight ? "rgba(0, 0, 0, 0.14)" : "rgba(255, 255, 255, 0.14)",
  )

  if (isSlate) {
    root.style.setProperty("--color-selected-bg", colors.surfaceVariant)
    root.style.setProperty("--color-selected-fg", colors.textPrimary)
  } else {
    root.style.setProperty("--color-selected-bg", colors.accent)
    root.style.setProperty("--color-selected-fg", colors.accentText)
  }

  if (themeId === "moonstone") {
    root.style.setProperty("--color-inspector-bg", "#FFFFFF")
    root.style.setProperty("--color-bg", "#EEF1F6")
  } else {
    root.style.setProperty("--color-inspector-bg", colors.surface)
  }

  let themeColorMeta = document.querySelector('meta[name="theme-color"]')
  if (!themeColorMeta) {
    themeColorMeta = document.createElement("meta")
    themeColorMeta.setAttribute("name", "theme-color")
    document.head.appendChild(themeColorMeta)
  }
  themeColorMeta.setAttribute(
    "content",
    themeId === "moonstone" ? "#EEF1F6" : colors.background,
  )
}
