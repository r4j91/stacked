"use client";

import { formatTimeDisplay } from "@/lib/utils/date";

/** Paridade iOS AppTypography.timeTrailing — canto direito, sem ícone de relógio. */
export function TaskRowTime({
  time,
  className = "",
}: {
  time?: string | null;
  className?: string;
}) {
  const label = formatTimeDisplay(time);
  if (!label) return null;
  return (
    <span
      className={`inline-flex shrink-0 tabular-nums text-[13px] font-bold leading-snug text-[var(--color-date-upcoming)] ${className}`}
    >
      {label}
    </span>
  );
}
