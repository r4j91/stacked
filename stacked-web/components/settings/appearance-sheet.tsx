"use client";

import { useTheme } from "@/components/theme/theme-provider";
import { useWorkbench } from "@/components/shell/workbench-context";
import { AnchoredPopover } from "@/components/ui/anchored-popover";
import { AppIcon } from "@/components/ui/app-icon";
import { TagChip } from "@/components/ui/tag-chip";
import { DueDateChip } from "@/components/ui/due-date-chip";
import { Cancel01Icon, Tick01Icon } from "@/lib/icons/nav-icons";
import {
  themes,
  RECOMMENDED_THEME_IDS,
  type AppTheme,
  type AppThemeId,
} from "@/lib/theme/themes";
import {
  LABEL_CHIP_STYLES,
  writeLabelChipStyle,
  type LabelChipStyle,
} from "@/lib/theme/label-chip-style";
import { useLabelChipStyle } from "@/lib/theme/use-label-chip-style";
import {
  DUE_DATE_CHIP_STYLES,
  writeDueDateChipStyle,
  type DueDateChipStyle,
} from "@/lib/theme/due-date-chip-style";
import { useDueDateChipStyle } from "@/lib/theme/use-due-date-chip-style";
import {
  TASK_ROW_LAYOUTS,
  writeTaskRowLayout,
  type TaskRowLayout,
} from "@/lib/theme/task-row-layout";
import { useTaskRowLayout } from "@/lib/theme/use-task-row-layout";

export function AppearanceSheet() {
  const { appearanceOpen, appearanceAnchor, closeAppearance } = useWorkbench();
  const { themeId, setThemeId } = useTheme();
  const labelChipStyle = useLabelChipStyle();
  const dueDateChipStyle = useDueDateChipStyle();
  const taskRowLayout = useTaskRowLayout();

  return (
    <AnchoredPopover
      open={appearanceOpen}
      onClose={closeAppearance}
      anchorRect={appearanceAnchor}
      width={300}
      preferSide="right"
      className="max-h-[min(85vh,640px)] p-0"
      labelledBy="appearance-sheet-title"
    >
      <div className="flex items-center justify-between border-b border-[var(--color-border)] px-4 py-3">
        <h2 id="appearance-sheet-title" className="text-base font-bold">
          Aparência
        </h2>
        <button
          type="button"
          onClick={closeAppearance}
          className="flex h-8 w-8 items-center justify-center rounded-full text-[var(--color-text-tertiary)] hover:bg-[var(--color-surface-variant)]"
          aria-label="Fechar"
        >
          <AppIcon icon={Cancel01Icon} size={16} />
        </button>
      </div>

      <div className="scroll-thin space-y-4 overflow-y-auto p-2">
        <section>
          <p className="px-2.5 pb-1.5 pt-1 text-[11px] font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)]">
            Tema · Recomendados
          </p>
          <div className="space-y-1">
            {RECOMMENDED_THEME_IDS.map((id) => (
              <ThemeOption
                key={id}
                theme={themes[id]}
                selected={themeId === id}
                onSelect={() => setThemeId(id)}
              />
            ))}
          </div>
        </section>

        <section>
          <p className="px-2.5 pb-1.5 text-[11px] font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)]">
            Tema · Mais
          </p>
          <div className="space-y-1">
            {(Object.keys(themes) as AppThemeId[])
              .filter((id) => !RECOMMENDED_THEME_IDS.includes(id))
              .map((id) => (
                <ThemeOption
                  key={id}
                  theme={themes[id]}
                  selected={themeId === id}
                  onSelect={() => setThemeId(id)}
                />
              ))}
          </div>
        </section>

        <section>
          <p className="px-2.5 pb-1.5 text-[11px] font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)]">
            Layout dos cards
          </p>
          <div className="space-y-1">
            {TASK_ROW_LAYOUTS.map((option) => {
              const selected = taskRowLayout === option.id;
              return (
                <button
                  key={option.id}
                  type="button"
                  onClick={() => writeTaskRowLayout(option.id)}
                  className={`flex w-full items-center gap-3 rounded-[var(--radius-md)] px-2.5 py-2.5 text-left transition-colors ${
                    selected
                      ? "bg-[var(--color-hover-overlay-strong)] ring-1 ring-[var(--color-border-strong)]"
                      : "hover:bg-[var(--color-hover-overlay)]"
                  }`}
                >
                  <TaskRowLayoutPreview layout={option.id} selected={selected} />
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-semibold">{option.name}</p>
                    <p className="text-[11px] text-[var(--color-text-tertiary)]">{option.subtitle}</p>
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
        </section>

        <section>
          <p className="px-2.5 pb-1.5 text-[11px] font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)]">
            Etiquetas nos cards
          </p>
          <div className="space-y-1">
            {LABEL_CHIP_STYLES.map((option) => {
              const selected = labelChipStyle === option.id;
              return (
                <button
                  key={option.id}
                  type="button"
                  onClick={() => writeLabelChipStyle(option.id)}
                  className={`flex w-full items-center gap-3 rounded-[var(--radius-md)] px-2.5 py-2.5 text-left transition-colors ${
                    selected
                      ? "bg-[var(--color-hover-overlay-strong)] ring-1 ring-[var(--color-border-strong)]"
                      : "hover:bg-[var(--color-hover-overlay)]"
                  }`}
                >
                  <LabelChipStylePreview style={option.id} selected={selected} />
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-semibold">{option.name}</p>
                    <p className="text-[11px] text-[var(--color-text-tertiary)]">{option.subtitle}</p>
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
        </section>

        <section>
          <p className="px-2.5 pb-1.5 text-[11px] font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)]">
            Data nos cards
          </p>
          <div className="space-y-1">
            {DUE_DATE_CHIP_STYLES.map((option) => {
              const selected = dueDateChipStyle === option.id;
              return (
                <button
                  key={option.id}
                  type="button"
                  onClick={() => writeDueDateChipStyle(option.id)}
                  className={`flex w-full items-center gap-3 rounded-[var(--radius-md)] px-2.5 py-2.5 text-left transition-colors ${
                    selected
                      ? "bg-[var(--color-hover-overlay-strong)] ring-1 ring-[var(--color-border-strong)]"
                      : "hover:bg-[var(--color-hover-overlay)]"
                  }`}
                >
                  <DueDateChipStylePreview style={option.id} selected={selected} />
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-semibold">{option.name}</p>
                    <p className="text-[11px] text-[var(--color-text-tertiary)]">{option.subtitle}</p>
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
        </section>
      </div>
    </AnchoredPopover>
  );
}

function ThemeOption({
  theme,
  selected,
  onSelect,
}: {
  theme: AppTheme;
  selected: boolean;
  onSelect: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onSelect}
      className={`flex w-full items-center gap-3 rounded-[var(--radius-md)] px-2.5 py-2.5 text-left transition-colors duration-150 ${
        selected
          ? "bg-[var(--color-hover-overlay-strong)] ring-1 ring-[var(--color-border-strong)]"
          : "hover:bg-[var(--color-hover-overlay)]"
      }`}
    >
      <ThemePreview theme={theme} />
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
}

function ThemePreview({ theme }: { theme: AppTheme }) {
  const swatch = theme.previewSwatch ?? {
    background: theme.colors.background,
    surface: theme.colors.surface,
    accent: theme.colors.accent,
  };
  return (
    <div
      className="relative h-11 w-11 shrink-0 overflow-hidden rounded-[10px] border border-white/10 shadow-sm"
      style={{ background: swatch.background }}
    >
      <div className="absolute bottom-0 left-0 right-0 h-5" style={{ background: swatch.surface }} />
      <div
        className="absolute bottom-1.5 left-1.5 h-2.5 w-2.5 rounded-[3px]"
        style={{ background: swatch.accent }}
      />
      <div
        className="absolute bottom-1.5 right-1.5 h-1 w-4 rounded-full opacity-60"
        style={{ background: theme.colors.textSecondary }}
      />
    </div>
  );
}

function TaskRowLayoutPreview({
  layout,
  selected,
}: {
  layout: TaskRowLayout;
  selected: boolean;
}) {
  return (
    <div
      className={`flex h-11 w-[4.5rem] shrink-0 flex-col justify-center gap-0.5 rounded-[10px] border px-1.5 ${
        selected ? "border-[var(--color-accent)]" : "border-[var(--color-border)]"
      } bg-[var(--color-surface)]`}
    >
      {layout === "f2" && (
        <>
          <div className="flex items-center gap-0.5">
            <span className="h-0.5 w-3 rounded-full bg-[var(--color-text-tertiary)]" />
            <span className="h-0.5 w-0.5 rounded-full bg-[var(--color-p1)]" />
          </div>
          <span className="h-1 w-full rounded-full bg-[var(--color-text)]/70" />
          <span className="h-0.5 w-[80%] rounded-full bg-[var(--color-accent)]/80" />
        </>
      )}
      {layout === "x2" && (
        <>
          <span className="h-0.5 w-3 rounded-full bg-[var(--color-text-tertiary)]" />
          <span className="h-1 w-full rounded-full bg-[var(--color-text)]/70" />
          <div className="flex items-center gap-0.5">
            <span className="h-1.5 w-2 rounded-[2px] bg-[var(--color-p1)]/40" />
            <span className="h-0.5 flex-1 rounded-full bg-[var(--color-accent)]/80" />
          </div>
        </>
      )}
      {layout === "default" && (
        <>
          <span className="h-1 w-full rounded-full bg-[var(--color-text)]/70" />
          <div className="flex items-center gap-0.5">
            <span className="h-0.5 w-2.5 rounded-full bg-[var(--color-text-secondary)]" />
            <span className="h-1 w-2.5 rounded-[2px] bg-[#B18CF5]/35" />
            <span className="h-1 w-2.5 rounded-[2px] bg-[var(--color-accent)]/35" />
          </div>
        </>
      )}
    </div>
  );
}

function LabelChipStylePreview({
  style,
  selected,
}: {
  style: LabelChipStyle;
  selected: boolean;
}) {
  return (
    <div
      className={`flex h-11 w-[4.5rem] shrink-0 items-center justify-center rounded-[10px] border ${
        selected ? "border-[var(--color-accent)]" : "border-[var(--color-border)]"
      } bg-[var(--color-surface)]`}
    >
      <TagChip label="Ideia" color="#B18CF5" style={style} />
    </div>
  );
}

function DueDateChipStylePreview({
  style,
  selected,
}: {
  style: DueDateChipStyle;
  selected: boolean;
}) {
  return (
    <div
      className={`flex h-11 w-[4.5rem] shrink-0 items-center justify-center rounded-[10px] border ${
        selected ? "border-[var(--color-accent)]" : "border-[var(--color-border)]"
      } bg-[var(--color-surface)]`}
    >
      <DueDateChip label="Hoje" color="#5FD3DC" day={17} style={style} />
    </div>
  );
}
