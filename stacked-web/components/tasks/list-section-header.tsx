"use client";

import type { AnchorRect } from "@/components/ui/anchored-popover";

type ListSectionHeaderProps = {
  title: string;
  count?: number;
  overdue?: boolean;
  expanded?: boolean;
  onToggle?: () => void;
  onMenu?: (anchor: AnchorRect) => void;
  dropSectionId?: string;
  reorderRowProps?: Record<string, unknown>;
  reorderHolding?: boolean;
  reorderDragOver?: boolean;
  reorderDragging?: boolean;
};

function ChevronIcon({ expanded }: { expanded: boolean }) {
  return (
    <svg
      className={`h-3.5 w-3.5 transition-transform ${expanded ? "rotate-90" : ""}`}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={2}
      aria-hidden
    >
      <path d="m9 18 6-6-6-6" strokeLinecap="round" />
    </svg>
  );
}

export function ListSectionHeader({
  title,
  count,
  overdue,
  expanded = true,
  onToggle,
  onMenu,
  dropSectionId,
  reorderRowProps,
  reorderHolding,
  reorderDragOver,
  reorderDragging,
}: ListSectionHeaderProps) {
  return (
    <div
      {...(reorderRowProps ?? {})}
      data-task-drop-section={dropSectionId}
      className={`flex items-center gap-2 px-2 pb-2 pt-4 ${
        reorderDragging
          ? "reorder-dragging rounded-[var(--radius-sm)]"
          : reorderHolding
            ? "reorder-holding rounded-[var(--radius-sm)]"
            : reorderDragOver
              ? "reorder-drop-target rounded-[var(--radius-sm)]"
              : ""
      }`}
      data-reorder-dragging={reorderDragging ? "" : undefined}
    >
      {onToggle != null && (
        <button
          type="button"
          data-no-reorder
          onClick={onToggle}
          className="flex h-7 w-7 shrink-0 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-tertiary)] hover:bg-[var(--color-surface-variant)] hover:text-[var(--color-text-secondary)]"
          aria-expanded={expanded}
          aria-label={expanded ? "Recolher seção" : "Expandir seção"}
        >
          <ChevronIcon expanded={expanded} />
        </button>
      )}
      <div className="flex min-w-0 flex-1 items-center gap-2">
        <h2
          className={`type-list-section-title truncate ${overdue ? "text-[var(--color-overdue)]" : ""}`}
        >
          {title}
        </h2>
        {count != null && count > 0 && (
          overdue ? (
            <span className="rounded-full bg-[var(--color-overdue)]/15 px-1.5 py-0.5 text-[11px] font-semibold tabular-nums text-[var(--color-overdue)] lg:text-xs">
              {count}
            </span>
          ) : (
            <span className="type-list-section-count tabular-nums text-[var(--color-text-tertiary)]">
              {count}
            </span>
          )
        )}
      </div>
      {onMenu != null && (
        <button
          type="button"
          data-no-reorder
          onClick={(e) => onMenu(e.currentTarget.getBoundingClientRect())}
          className="flex h-7 w-7 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-tertiary)] hover:bg-[var(--color-surface-variant)] hover:text-[var(--color-text-secondary)]"
          aria-label={`Opções da seção ${title}`}
        >
          ···
        </button>
      )}
    </div>
  );
}
