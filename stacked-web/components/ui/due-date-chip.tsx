"use client";

import { AppIcon } from "@/components/ui/app-icon";
import { Calendar03Icon } from "@/lib/icons/nav-icons";
import type { DueDateChipStyle } from "@/lib/theme/due-date-chip-style";

type DueDateChipProps = {
  label: string;
  color: string;
  day?: number | null;
  style?: DueDateChipStyle;
};

export function DueDateChip({ label, color, day, style = "soft" }: DueDateChipProps) {
  if (style === "plain") {
    return (
      <span className="truncate text-xs font-medium" style={{ color }}>
        {label}
      </span>
    );
  }

  if (style === "day") {
    return (
      <span className="inline-flex max-w-full items-center gap-1.5">
        <span
          className="inline-flex h-3.5 w-4 shrink-0 items-center justify-center rounded-[3px] border text-[9px] font-bold leading-none"
          style={{
            color,
            backgroundColor: `color-mix(in srgb, ${color} 14%, transparent)`,
            borderColor: `color-mix(in srgb, ${color} 40%, transparent)`,
          }}
        >
          {day ?? "–"}
        </span>
        <span className="truncate text-xs font-medium" style={{ color }}>
          {label}
        </span>
      </span>
    );
  }

  if (style === "flat") {
    return (
      <span className="inline-flex max-w-full items-center gap-1 text-xs font-medium" style={{ color }}>
        <AppIcon icon={Calendar03Icon} size={14} strokeWidth={1.75} />
        <span className="truncate">{label}</span>
      </span>
    );
  }

  if (style === "outline") {
    return (
      <span
        className="inline-flex max-w-full items-center gap-1 rounded-md border px-1.5 py-0.5 text-xs font-medium"
        style={{
          color,
          backgroundColor: "transparent",
          borderColor: `color-mix(in srgb, ${color} 50%, transparent)`,
        }}
      >
        <AppIcon icon={Calendar03Icon} size={14} strokeWidth={1.75} />
        <span className="truncate">{label}</span>
      </span>
    );
  }

  return (
    <span
      className="inline-flex max-w-full items-center gap-1 rounded-md border px-1.5 py-0.5 text-xs font-medium"
      style={{
        color,
        backgroundColor: `color-mix(in srgb, ${color} 12%, transparent)`,
        borderColor: `color-mix(in srgb, ${color} 30%, transparent)`,
      }}
    >
      <AppIcon icon={Calendar03Icon} size={14} strokeWidth={1.75} />
      <span className="truncate">{label}</span>
    </span>
  );
}
