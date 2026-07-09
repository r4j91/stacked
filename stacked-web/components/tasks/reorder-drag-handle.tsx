"use client";

type ReorderDragHandleProps = {
  dragProps: Record<string, unknown>;
  label?: string;
};

export function ReorderDragHandle({ dragProps, label = "Reordenar" }: ReorderDragHandleProps) {
  return (
    <button
      type="button"
      {...dragProps}
      onClick={(e) => e.stopPropagation()}
      className="reorder-handle mt-0.5 flex h-8 w-6 shrink-0 cursor-grab items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-tertiary)] opacity-35 transition-opacity hover:bg-[var(--color-hover-overlay)] hover:text-[var(--color-text-secondary)] hover:opacity-100 group-hover/task-row:opacity-70 group-hover/list-section:opacity-70 focus-visible:opacity-100 active:cursor-grabbing"
      aria-label={label}
      title={label}
    >
      <svg width="10" height="14" viewBox="0 0 10 14" fill="currentColor" aria-hidden>
        <circle cx="2.5" cy="2.5" r="1.25" />
        <circle cx="7.5" cy="2.5" r="1.25" />
        <circle cx="2.5" cy="7" r="1.25" />
        <circle cx="7.5" cy="7" r="1.25" />
        <circle cx="2.5" cy="11.5" r="1.25" />
        <circle cx="7.5" cy="11.5" r="1.25" />
      </svg>
    </button>
  );
}
