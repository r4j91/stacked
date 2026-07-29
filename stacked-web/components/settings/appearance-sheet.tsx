"use client";

import { useState, type ReactNode } from "react";
import { useTheme } from "@/components/theme/theme-provider";
import { useWorkbench } from "@/components/shell/workbench-context";
import { AnchoredPopover } from "@/components/ui/anchored-popover";
import { AppIcon } from "@/components/ui/app-icon";
import { TagChip } from "@/components/ui/tag-chip";
import { DueDateChip } from "@/components/ui/due-date-chip";
import {
  ArrowDown01Icon,
  Cancel01Icon,
  GridIcon,
  ListViewIcon,
  PaintBoardIcon,
  Tick01Icon,
} from "@/lib/icons/nav-icons";
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
import { writeSubtaskProgressRing } from "@/lib/theme/subtask-progress-ring";
import { useSubtaskProgressRing } from "@/lib/theme/use-subtask-progress-ring";
import { writeSubtaskBranch } from "@/lib/theme/subtask-branch";
import { useSubtaskBranch } from "@/lib/theme/use-subtask-branch";
import {
  DISPLAY_MODES,
  writeDisplayMode,
  type DisplayMode,
} from "@/lib/theme/display-mode";
import { useDisplayMode } from "@/lib/theme/use-display-mode";

type SectionId = "theme" | "display" | "advanced";

export function AppearanceSheet() {
  const { appearanceOpen, appearanceAnchor, closeAppearance } = useWorkbench();
  const { themeId, setThemeId } = useTheme();
  const labelChipStyle = useLabelChipStyle();
  const dueDateChipStyle = useDueDateChipStyle();
  const taskRowLayout = useTaskRowLayout();
  const subtaskProgressRing = useSubtaskProgressRing();
  const subtaskBranch = useSubtaskBranch();
  const displayMode = useDisplayMode();
  const [openSections, setOpenSections] = useState<Record<SectionId, boolean>>({
    theme: true,
    display: false,
    advanced: false,
  });
  const [moreThemesOpen, setMoreThemesOpen] = useState(false);
  const [advancedSub, setAdvancedSub] = useState({
    layout: false,
    subtasks: false,
    labels: false,
    dates: false,
  });

  function toggleSection(id: SectionId) {
    setOpenSections((prev) => ({ ...prev, [id]: !prev[id] }));
  }

  const moreThemes = (Object.keys(themes) as AppThemeId[]).filter(
    (id) => !RECOMMENDED_THEME_IDS.includes(id),
  );

  return (
    <AnchoredPopover
      open={appearanceOpen}
      onClose={closeAppearance}
      anchorRect={appearanceAnchor}
      width={300}
      preferSide="right"
      className="max-h-[min(85vh,640px)] p-0"
      labelledBy="appearance-sheet-title"
      lockOverflow
    >
      <div className="flex shrink-0 items-center justify-between border-b border-[var(--color-border)] px-4 py-3">
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

      <div className="min-h-0 flex-1 space-y-1 overflow-y-auto scroll-thin p-2">
        <AppearanceAccordion
          id="theme"
          title="Tema"
          icon={PaintBoardIcon}
          summary={themes[themeId]?.name ?? themeId}
          open={openSections.theme}
          onToggle={() => toggleSection("theme")}
        >
          <p className="px-2.5 pb-1.5 pt-1 text-[11px] font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)]">
            Recomendados
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
          {moreThemes.length > 0 && (
            <div className="pt-2">
              <button
                type="button"
                onClick={() => setMoreThemesOpen((v) => !v)}
                aria-expanded={moreThemesOpen}
                className="flex w-full items-center gap-2 rounded-[var(--radius-md)] px-2.5 py-2 text-left text-xs font-semibold text-[var(--color-text-secondary)] transition-colors hover:bg-[var(--color-hover-overlay)] hover:text-[var(--color-text)]"
              >
                <span className="flex-1">Mais temas</span>
                <AppIcon
                  icon={ArrowDown01Icon}
                  size={14}
                  className={`shrink-0 text-[var(--color-text-tertiary)] transition-transform duration-200 ${
                    moreThemesOpen ? "rotate-180" : ""
                  }`}
                />
              </button>
              {moreThemesOpen ? (
                <div className="mt-1 space-y-1">
                  {moreThemes.map((id) => (
                    <ThemeOption
                      key={id}
                      theme={themes[id]}
                      selected={themeId === id}
                      onSelect={() => setThemeId(id)}
                    />
                  ))}
                </div>
              ) : null}
            </div>
          )}
        </AppearanceAccordion>

        <AppearanceAccordion
          id="display"
          title="Visualização"
          icon={GridIcon}
          summary={DISPLAY_MODES.find((m) => m.id === displayMode)?.name ?? "Lista"}
          open={openSections.display}
          onToggle={() => toggleSection("display")}
        >
          <div className="space-y-1">
            {DISPLAY_MODES.map((option) => {
              const selected = displayMode === option.id;
              return (
                <button
                  key={option.id}
                  type="button"
                  onClick={() => writeDisplayMode(option.id)}
                  className={`flex w-full items-center gap-3 rounded-[var(--radius-md)] px-2.5 py-2.5 text-left transition-colors ${
                    selected
                      ? "bg-[var(--color-hover-overlay-strong)] ring-1 ring-[var(--color-border-strong)]"
                      : "hover:bg-[var(--color-hover-overlay)]"
                  }`}
                >
                  <DisplayModePreview mode={option.id} selected={selected} />
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
        </AppearanceAccordion>

        <AppearanceAccordion
          id="advanced"
          title="Avançado"
          icon={ListViewIcon}
          summary="Layout, chips e subtarefas"
          open={openSections.advanced}
          onToggle={() => toggleSection("advanced")}
        >
          <div className="space-y-0.5">
            <AdvancedSubSection
              title="Layout dos cards"
              summary={TASK_ROW_LAYOUTS.find((l) => l.id === taskRowLayout)?.name ?? "Atual"}
              open={advancedSub.layout}
              onToggle={() => setAdvancedSub((s) => ({ ...s, layout: !s.layout }))}
            >
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
            </AdvancedSubSection>

            <AdvancedSubSection
              title="Subtarefas"
              summary={[
                subtaskProgressRing ? "Anel" : null,
                subtaskBranch ? "Galho" : null,
              ]
                .filter(Boolean)
                .join(" · ") || "Padrão"}
              open={advancedSub.subtasks}
              onToggle={() => setAdvancedSub((s) => ({ ...s, subtasks: !s.subtasks }))}
            >
              <div className="space-y-1">
                <AppearanceToggleRow
                  title="Anel de progresso"
                  subtitle="Mostra o progresso das subtarefas no lugar da seta."
                  checked={subtaskProgressRing}
                  onChange={writeSubtaskProgressRing}
                />
                <AppearanceToggleRow
                  title="Galho"
                  subtitle="Trilho vertical na lista expandida de subtarefas."
                  checked={subtaskBranch}
                  onChange={writeSubtaskBranch}
                />
              </div>
            </AdvancedSubSection>

            <AdvancedSubSection
              title="Etiquetas"
              summary={LABEL_CHIP_STYLES.find((s) => s.id === labelChipStyle)?.name ?? ""}
              open={advancedSub.labels}
              onToggle={() => setAdvancedSub((s) => ({ ...s, labels: !s.labels }))}
            >
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
            </AdvancedSubSection>

            <AdvancedSubSection
              title="Data nos cards"
              summary={DUE_DATE_CHIP_STYLES.find((s) => s.id === dueDateChipStyle)?.name ?? ""}
              open={advancedSub.dates}
              onToggle={() => setAdvancedSub((s) => ({ ...s, dates: !s.dates }))}
            >
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
            </AdvancedSubSection>
          </div>
        </AppearanceAccordion>
      </div>
    </AnchoredPopover>
  );
}

function AdvancedSubSection({
  title,
  summary,
  open,
  onToggle,
  children,
}: {
  title: string;
  summary: string;
  open: boolean;
  onToggle: () => void;
  children: ReactNode;
}) {
  return (
    <div className="rounded-[var(--radius-sm)]">
      <button
        type="button"
        onClick={onToggle}
        aria-expanded={open}
        className="flex w-full items-center gap-2 rounded-[var(--radius-md)] px-2.5 py-2 text-left transition-colors hover:bg-[var(--color-hover-overlay)]"
      >
        <div className="min-w-0 flex-1">
          <p className="text-sm font-semibold">{title}</p>
          {!open && summary ? (
            <p className="truncate text-[11px] text-[var(--color-text-tertiary)]">{summary}</p>
          ) : null}
        </div>
        <AppIcon
          icon={ArrowDown01Icon}
          size={14}
          className={`shrink-0 text-[var(--color-text-tertiary)] transition-transform duration-200 ${
            open ? "rotate-180" : ""
          }`}
        />
      </button>
      {open ? <div className="pb-1.5 pt-0.5">{children}</div> : null}
    </div>
  );
}

function AppearanceAccordion({
  title,
  icon,
  summary,
  open,
  onToggle,
  children,
}: {
  id: SectionId;
  title: string;
  icon: typeof PaintBoardIcon;
  summary: string;
  open: boolean;
  onToggle: () => void;
  children: ReactNode;
}) {
  return (
    <section className="rounded-[var(--radius-md)]">
      <button
        type="button"
        onClick={onToggle}
        aria-expanded={open}
        className="flex w-full items-center gap-2.5 rounded-[var(--radius-md)] px-2.5 py-2.5 text-left transition-colors hover:bg-[var(--color-hover-overlay)]"
      >
        <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-[var(--color-surface-variant)] text-[var(--color-text-secondary)]">
          <AppIcon icon={icon} size={16} strokeWidth={1.75} />
        </span>
        <div className="min-w-0 flex-1">
          <p className="text-sm font-semibold">{title}</p>
          {!open && summary ? (
            <p className="truncate text-[11px] text-[var(--color-text-tertiary)]">{summary}</p>
          ) : null}
        </div>
        <AppIcon
          icon={ArrowDown01Icon}
          size={16}
          className={`shrink-0 text-[var(--color-text-tertiary)] transition-transform duration-200 ${
            open ? "rotate-180" : ""
          }`}
        />
      </button>
      {open ? <div className="pb-2 pt-0.5">{children}</div> : null}
    </section>
  );
}

function AppearanceToggleRow({
  title,
  subtitle,
  checked,
  onChange,
}: {
  title: string;
  subtitle: string;
  checked: boolean;
  onChange: (next: boolean) => void;
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      onClick={() => onChange(!checked)}
      className="flex w-full items-center gap-3 rounded-[var(--radius-md)] px-2.5 py-2.5 text-left transition-colors hover:bg-[var(--color-hover-overlay)]"
    >
      <div className="min-w-0 flex-1">
        <p className="text-sm font-semibold">{title}</p>
        <p className="text-[11px] text-[var(--color-text-tertiary)]">{subtitle}</p>
      </div>
      <span
        className={`relative h-6 w-10 shrink-0 rounded-full transition-colors ${
          checked ? "bg-[var(--color-accent)]" : "bg-[var(--color-surface-variant)]"
        }`}
        aria-hidden
      >
        <span
          className={`absolute top-0.5 h-5 w-5 rounded-full bg-white shadow transition-transform ${
            checked ? "translate-x-[18px]" : "translate-x-0.5"
          }`}
        />
      </span>
    </button>
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
      className="relative h-11 w-11 shrink-0 overflow-hidden rounded-[10px] border border-[var(--color-border)] shadow-sm"
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

function DisplayModePreview({
  mode,
  selected,
}: {
  mode: DisplayMode;
  selected: boolean;
}) {
  return (
    <div
      className={`flex h-11 w-[4.5rem] shrink-0 flex-col justify-center gap-1 rounded-[10px] border px-1.5 ${
        selected ? "border-[var(--color-accent)]" : "border-[var(--color-border)]"
      } bg-[var(--color-background)]`}
    >
      {mode === "halo" ? (
        <span className="h-6 w-full rounded-md border border-[color-mix(in_srgb,var(--color-text)_8%,transparent)] bg-[color-mix(in_srgb,var(--color-surface)_72%,var(--color-background))]" />
      ) : mode === "balloons" ? (
        <div className="flex flex-col gap-1">
          <span className="h-2.5 w-full rounded-[5px] border border-[color-mix(in_srgb,var(--color-text)_9%,transparent)] bg-[var(--color-surface)]" />
          <span className="h-2.5 w-full rounded-[5px] border border-[color-mix(in_srgb,var(--color-text)_9%,transparent)] bg-[var(--color-surface)]" />
        </div>
      ) : mode === "listPlus" ? (
        <>
          <span className="mx-auto h-1 w-[80%] rounded-full bg-[var(--color-text)]/50" />
          <span className="mx-auto h-1 w-[55%] rounded-full bg-[var(--color-text)]/35" />
        </>
      ) : (
        <>
          <span className="h-1 w-full rounded-full bg-[var(--color-text)]/50" />
          <span className="h-1 w-[70%] rounded-full bg-[var(--color-text)]/35" />
        </>
      )}
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
