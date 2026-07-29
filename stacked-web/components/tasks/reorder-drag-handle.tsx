"use client";

type ReorderDragHandleProps = {
  dragProps: Record<string, unknown>;
  label?: string;
  /** Sempre visível (modo Editar) — senão só no hover da row. */
  alwaysVisible?: boolean;
};

export function ReorderDragHandle({
  dragProps,
  label = "Reordenar",
  alwaysVisible = false,
}: ReorderDragHandleProps) {
  return (
    <button
      type="button"
      {...dragProps}
      onClick={(e) => e.stopPropagation()}
      className={`reorder-handle flex h-7 w-4 shrink-0 cursor-grab items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-tertiary)] transition-[opacity,background-color,color] duration-150 ease-out hover:bg-[var(--color-hover-overlay)] hover:text-[var(--color-text-secondary)] hover:!opacity-100 focus-visible:opacity-100 active:cursor-grabbing ${
        alwaysVisible
          ? "opacity-55"
          : "opacity-0 group-hover/reorder-row:opacity-55"
      }`}
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
