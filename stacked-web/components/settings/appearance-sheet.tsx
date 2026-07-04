"use client";

import { useTheme } from "@/components/theme/theme-provider";
import { useWorkbench } from "@/components/shell/workbench-context";
import { AnchoredPopover } from "@/components/ui/anchored-popover";
import { AppIcon } from "@/components/ui/app-icon";
import { Cancel01Icon, Tick01Icon } from "@/lib/icons/nav-icons";
import { themes, type AppThemeId } from "@/lib/theme/themes";

export function AppearanceSheet() {
  const { appearanceOpen, appearanceAnchor, closeAppearance } = useWorkbench();
  const { themeId, setThemeId } = useTheme();

  return (
    <AnchoredPopover
      open={appearanceOpen}
      onClose={closeAppearance}
      anchorRect={appearanceAnchor}
      width={300}
      preferSide="right"
      className="max-h-[min(85vh,480px)] p-0"
      labelledBy="appearance-sheet-title"
    >
      <div className="flex items-center justify-between border-b border-[var(--color-border)] px-4 py-3">
        <h2 id="appearance-sheet-title" className="text-base font-bold">Aparência</h2>
        <button
          type="button"
          onClick={closeAppearance}
          className="flex h-8 w-8 items-center justify-center rounded-full text-[var(--color-text-tertiary)] hover:bg-[var(--color-surface-variant)]"
          aria-label="Fechar"
        >
          <AppIcon icon={Cancel01Icon} size={16} />
        </button>
      </div>

      <div className="scroll-thin space-y-1 overflow-y-auto p-2">
        {(Object.keys(themes) as AppThemeId[]).map((id) => {
          const theme = themes[id];
          const selected = themeId === id;
          return (
            <button
              key={id}
              type="button"
              onClick={() => setThemeId(id)}
              className={`flex w-full items-center gap-3 rounded-[var(--radius-md)] px-2.5 py-2.5 text-left transition-colors ${
                selected
                  ? "bg-[var(--color-hover-overlay-strong)] ring-1 ring-[var(--color-border-strong)]"
                  : "hover:bg-[var(--color-hover-overlay)]"
              }`}
            >
              <ThemePreview colors={theme.colors} />
              <div className="min-w-0 flex-1">
                <p className="text-sm font-semibold">{theme.name}</p>
                <p className="text-[11px] text-[var(--color-text-tertiary)]">{theme.subtitle}</p>
              </div>
              {selected && (
                <span className="text-[var(--color-text)]">
                  <AppIcon icon={Tick01Icon} size={16} strokeWidth={2.5} />
                </span>
              )}
            </button>
          );
        })}
      </div>
    </AnchoredPopover>
  );
}

function ThemePreview({ colors }: { colors: (typeof themes)[AppThemeId]["colors"] }) {
  return (
    <div
      className="relative h-11 w-11 shrink-0 overflow-hidden rounded-[10px] border border-white/10 shadow-sm"
      style={{ background: colors.background }}
    >
      <div className="absolute bottom-0 left-0 right-0 h-5" style={{ background: colors.surface }} />
      <div
        className="absolute bottom-1.5 left-1.5 h-2.5 w-2.5 rounded-[3px]"
        style={{ background: colors.accent }}
      />
      <div
        className="absolute bottom-1.5 right-1.5 h-1 w-4 rounded-full opacity-60"
        style={{ background: colors.textSecondary }}
      />
    </div>
  );
}
