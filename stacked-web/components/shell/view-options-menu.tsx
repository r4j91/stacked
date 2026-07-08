"use client";

import { useState } from "react";
import { AppIcon } from "@/components/ui/app-icon";
import { ViewIcon, ViewOffIcon, GridIcon, ListViewIcon } from "@/lib/icons/nav-icons";
import { AnchoredPopover, anchorFromElement } from "@/components/ui/anchored-popover";
import type { ProjectDisplayMode } from "@/lib/theme/project-display-mode";
import { PROJECT_DISPLAY_MODES } from "@/lib/theme/project-display-mode";

type ViewOptionsMenuProps = {
  showCompleted: boolean;
  onToggleCompleted: () => void;
  extraItems?: { label: string; onClick: () => void }[];
  displayMode?: ProjectDisplayMode;
  onDisplayModeChange?: (mode: ProjectDisplayMode) => void;
};

const MODE_ICONS: Record<ProjectDisplayMode, typeof GridIcon> = {
  cards: GridIcon,
  cardsRefined: GridIcon,
  list: ListViewIcon,
};

export function ViewOptionsMenu({
  showCompleted,
  onToggleCompleted,
  extraItems,
  displayMode,
  onDisplayModeChange,
}: ViewOptionsMenuProps) {
  const [open, setOpen] = useState(false);
  const [anchor, setAnchor] = useState<ReturnType<typeof anchorFromElement> | null>(null);

  function close() {
    setOpen(false);
    setAnchor(null);
  }

  return (
    <>
      <button
        type="button"
        onClick={(e) => {
          setAnchor(anchorFromElement(e.currentTarget));
          setOpen(true);
        }}
        className="btn-secondary inline-flex items-center gap-1.5 rounded-[var(--radius-sm)] px-3 py-1.5 text-[13px]"
        aria-expanded={open}
        aria-haspopup="menu"
      >
        Opções
      </button>
      <AnchoredPopover open={open} onClose={close} anchorRect={anchor} width={240} placement="below" className="p-1" labelledBy="view-options-title">
        <div role="menu">
          <p id="view-options-title" className="sr-only">Opções de visualização</p>
          {extraItems?.map((item) => (
            <button
              key={item.label}
              type="button"
              role="menuitem"
              onClick={() => {
                item.onClick();
                close();
              }}
              className="flex w-full items-center gap-2.5 rounded-[var(--radius-sm)] px-3 py-2.5 text-left text-[13px] text-[var(--color-text)] hover:bg-[var(--color-hover-overlay)]"
            >
              {item.label}
            </button>
          ))}
          {displayMode != null && onDisplayModeChange && (
            <>
              <div className="my-1 h-px bg-[var(--color-border)]" role="separator" />
              <p className="px-3 py-1.5 text-[10px] font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)]">
                Visualização
              </p>
              {PROJECT_DISPLAY_MODES.map((opt) => {
                const selected = displayMode === opt.value;
                return (
                  <button
                    key={opt.value}
                    type="button"
                    role="menuitemradio"
                    aria-checked={selected}
                    onClick={() => {
                      onDisplayModeChange(opt.value);
                      close();
                    }}
                    className={`flex w-full items-center gap-2.5 rounded-[var(--radius-sm)] px-3 py-2.5 text-left text-[13px] hover:bg-[var(--color-hover-overlay)] ${
                      selected
                        ? "bg-[var(--color-hover-overlay)] font-semibold text-[var(--color-text)]"
                        : "text-[var(--color-text-secondary)]"
                    }`}
                  >
                    <AppIcon icon={MODE_ICONS[opt.value]} size={16} />
                    {opt.label}
                    {selected && (
                      <span className="ml-auto text-[var(--color-accent)]" aria-hidden>
                        ✓
                      </span>
                    )}
                  </button>
                );
              })}
            </>
          )}
          <div className="my-1 h-px bg-[var(--color-border)]" role="separator" />
          <button
            type="button"
            role="menuitem"
            onClick={() => {
              onToggleCompleted();
              close();
            }}
            className="flex w-full items-center gap-2.5 rounded-[var(--radius-sm)] px-3 py-2.5 text-left text-[13px] text-[var(--color-text)] hover:bg-[var(--color-hover-overlay)]"
          >
            <AppIcon icon={showCompleted ? ViewOffIcon : ViewIcon} size={16} className="text-[var(--color-text-secondary)]" />
            {showCompleted ? "Ocultar concluídas" : "Mostrar concluídas"}
          </button>
        </div>
      </AnchoredPopover>
    </>
  );
}
