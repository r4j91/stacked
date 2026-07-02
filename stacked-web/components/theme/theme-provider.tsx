"use client"

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react"
import {
  applyThemeToDocument,
  DEFAULT_THEME_ID,
  isAppThemeId,
  themes,
  type AppThemeId,
} from "@/lib/theme/themes"

const STORAGE_KEY = "stacked-theme"

type ThemeContextValue = {
  themeId: AppThemeId
  setThemeId: (id: AppThemeId) => void
  themeName: string
}

const ThemeContext = createContext<ThemeContextValue | null>(null)

function readStoredTheme(): AppThemeId {
  if (typeof window === "undefined") return DEFAULT_THEME_ID
  const stored = window.localStorage.getItem(STORAGE_KEY)
  return stored && isAppThemeId(stored) ? stored : DEFAULT_THEME_ID
}

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [themeId, setThemeIdState] = useState<AppThemeId>(DEFAULT_THEME_ID)

  useEffect(() => {
    const stored = readStoredTheme()
    setThemeIdState(stored)
    applyThemeToDocument(stored)
  }, [])

  const setThemeId = useCallback((id: AppThemeId) => {
    setThemeIdState(id)
    window.localStorage.setItem(STORAGE_KEY, id)
    applyThemeToDocument(id)
  }, [])

  const value = useMemo(
    () => ({
      themeId,
      setThemeId,
      themeName: themes[themeId].name,
    }),
    [themeId, setThemeId],
  )

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>
}

export function useTheme() {
  const ctx = useContext(ThemeContext)
  if (!ctx) throw new Error("useTheme must be used within ThemeProvider")
  return ctx
}
