"use client";

import { useState } from "react";
import { AppIcon } from "@/components/ui/app-icon";
import { ChevronRightIcon, Calendar03Icon, Flag01Icon, TextIcon, ViewIcon, ViewOffIcon } from "@/lib/icons/nav-icons";
import { AnchoredPopover, anchorFromElement } from "@/components/ui/anchored-popover";
import { SAVED_FILTER_SORT_LABELS, SAVED_FILTER_SORT_MODES, type SavedFilterSortMode } from "@/lib/utils/saved-filter-sort";

type ViewOptionsMenuProps = {
  showCompleted?: boolean;
  onToggleCompleted?: () => void;
  extraItems?: { label: string; onClick: () => void }[];
  sort?: {
    mode: SavedFilterSortMode;
    onChange: (mode: SavedFilterSortMode) => void;
  };
};

const SORT_ICONS: Record<SavedFilterSortMode, typeof Calendar03Icon> = {
  dueDate: Calendar03Icon,
  alphabetical: TextIcon,
  priority: Flag01Icon,
};

export function ViewOptionsMenu({ showCompleted, onToggleCompleted, extraItems, sort }: ViewOptionsMenuProps) {
  const [open, setOpen] = useState(false);
  const [anchor, setAnchor] = useState<ReturnType<typeof anchorFromElement> | null>(null);
  const [sortExpanded, setSortExpanded] = useState(false);

  function close() {
    setOpen(false);
    setAnchor(null);
    setSortExpanded(false);
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
          {onToggleCompleted && (
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
          )}
          {sort && (
            <>
              <button
                type="button"
                role="menuitem"
                aria-expanded={sortExpanded}
                onClick={() => setSortExpanded((v) => !v)}
                className="flex w-full items-center gap-2.5 rounded-[var(--radius-sm)] px-3 py-2.5 text-left text-[13px] text-[var(--color-text)] hover:bg-[var(--color-hover-overlay)]"
              >
                <AppIcon icon={SORT_ICONS[sort.mode]} size={16} className="text-[var(--color-text-secondary)]" />
                <span className="flex-1">Ordenar</span>
                <span className="text-[11px] text-[var(--color-text-tertiary)]">
                  {SAVED_FILTER_SORT_LABELS[sort.mode]}
                </span>
                <AppIcon
                  icon={ChevronRightIcon}
                  size={12}
                  className={`shrink-0 text-[var(--color-text-tertiary)] transition-transform ${sortExpanded ? "rotate-90" : ""}`}
                />
              </button>
              {sortExpanded && (
                <div className="ml-2 border-l border-[var(--color-border)] pl-2">
                  {SAVED_FILTER_SORT_MODES.map((mode) => (
                    <button
                      key={mode}
                      type="button"
                      role="menuitemradio"
                      aria-checked={sort.mode === mode}
                      onClick={() => {
                        sort.onChange(mode);
                        close();
                      }}
                      className={`flex w-full items-center gap-2.5 rounded-[var(--radius-sm)] px-3 py-2 text-left text-[13px] hover:bg-[var(--color-hover-overlay)] ${
                        sort.mode === mode ? "font-semibold text-[var(--color-text)]" : "text-[var(--color-text-secondary)]"
                      }`}
                    >
                      <AppIcon icon={SORT_ICONS[mode]} size={14} className="shrink-0" />
                      <span className="flex-1">{SAVED_FILTER_SORT_LABELS[mode]}</span>
                      {sort.mode === mode && (
                        <span className="text-[var(--color-accent)]">✓</span>
                      )}
                    </button>
                  ))}
                </div>
              )}
            </>
          )}
        </div>
      </AnchoredPopover>
    </>
  );
}
