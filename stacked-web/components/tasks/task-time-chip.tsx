"use client";

import { AppIcon } from "@/components/ui/app-icon";
import { Clock01Icon } from "@/lib/icons/nav-icons";
import { formatTimeDisplay } from "@/lib/utils/date";

export function TaskRowTime({ time, className = "" }: { time?: string | null; className?: string }) {
  const label = formatTimeDisplay(time);
  if (!label) return null;
  return (
    <span
      className={`inline-flex shrink-0 items-center gap-1 tabular-nums text-xs font-semibold text-[var(--color-text-tertiary)] ${className}`}
    >
      <AppIcon icon={Clock01Icon} size={11} strokeWidth={1.75} />
      {label}
    </span>
  );
}
