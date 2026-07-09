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
      className="reorder-handle flex h-7 w-4 shrink-0 cursor-grab items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-tertiary)] opacity-0 transition-[opacity,background-color,color] duration-150 ease-out hover:bg-[var(--color-hover-overlay)] hover:text-[var(--color-text-secondary)] group-hover/reorder-row:opacity-55 hover:!opacity-100 focus-visible:opacity-100 active:cursor-grabbing"
      aria-label={label}
      title={label}
    >
      <svg width="8" height="12" viewBox="0 0 8 12" fill="currentColor" aria-hidden>
        <circle cx="2" cy="2" r="1" />
        <circle cx="6" cy="2" r="1" />
        <circle cx="2" cy="6" r="1" />
        <circle cx="6" cy="6" r="1" />
        <circle cx="2" cy="10" r="1" />
        <circle cx="6" cy="10" r="1" />
      </svg>
    </button>
  );
}
