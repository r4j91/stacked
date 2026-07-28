"use client"

import { useTheme } from "@/components/theme/theme-provider"
import { themes } from "@/lib/theme/themes"
import { softenMetaColor } from "@/lib/theme/soften-color"

/** Tinta de meta no claro: dessatura hex ou mistura CSS var com cinza. Escuro = original. */
export function useMetaInk(color: string): string {
  const { themeId } = useTheme()
  const isLight = !themes[themeId]?.colors.isDark
  if (!isLight) return color
  const trimmed = color.trim()
  if (trimmed.startsWith("var(")) {
    return `color-mix(in srgb, ${trimmed} 58%, #5c6570 42%)`
  }
  return softenMetaColor(trimmed, true)
}
