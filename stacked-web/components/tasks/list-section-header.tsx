"use client";

import type { AnchorRect } from "@/components/ui/anchored-popover";
import { ReorderDragHandle } from "@/components/tasks/reorder-drag-handle";

type ListSectionHeaderProps = {
  title: string;
  count?: number;
  overdue?: boolean;
  expanded?: boolean;
  onToggle?: () => void;
  onMenu?: (anchor: AnchorRect) => void;
  dropSectionId?: string;
  reorderDropProps?: Record<string, unknown>;
  reorderHoldProps?: Record<string, unknown>;
  reorderHandleProps?: Record<string, unknown>;
  reorderDragOver?: boolean;
  reorderDropPosition?: "before" | "after" | null;
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
  reorderDropProps,
  reorderHoldProps,
  reorderHandleProps,
  reorderDragOver,
  reorderDropPosition,
}: ListSectionHeaderProps) {
  return (
    <div
      data-reorder-item
      {...(reorderDropProps ?? {})}
      {...(reorderHoldProps ?? {})}
      data-task-drop-section={dropSectionId}
      className={`group/reorder-row flex items-center gap-2 px-2 pb-2 pt-4 ${
        reorderHandleProps ? "reorder-row-with-gutter" : ""
      } ${
        reorderDragOver
          ? reorderDropPosition === "after"
            ? "reorder-drop-target reorder-drop-target-after"
            : "reorder-drop-target"
          : ""
      }`}
    >
      {reorderHandleProps ? (
        <div className="reorder-gutter flex shrink-0 items-center justify-center self-center">
          <ReorderDragHandle dragProps={reorderHandleProps} label={`Reordenar seção ${title}`} />
        </div>
      ) : null}
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
