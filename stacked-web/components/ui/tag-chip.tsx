"use client";

import { AppIcon } from "@/components/ui/app-icon";
import { Tag01Icon } from "@/lib/icons/nav-icons";
import type { Home01Icon } from "@hugeicons/core-free-icons";
import type { LabelChipStyle } from "@/lib/theme/label-chip-style";

type TagChipProps = {
  label: string;
  color: string;
  icon?: typeof Tag01Icon;
  showIcon?: boolean;
  maxWidth?: number;
  /** Etiquetas usam a preferência; prioridade/data omitem (fica soft). */
  style?: LabelChipStyle;
};

export function TagChip({
  label,
  color,
  icon = Tag01Icon,
  showIcon = true,
  maxWidth,
  style = "soft",
}: TagChipProps) {
  const maxW = maxWidth ? `${maxWidth}px` : undefined;

  if (style === "dot") {
    return (
      <span className="inline-flex max-w-full items-center gap-1.5" style={{ maxWidth: maxW }}>
        <span className="h-1.5 w-1.5 shrink-0 rounded-full" style={{ backgroundColor: color }} />
        <span className="truncate text-xs font-medium text-[var(--color-text-secondary)]">{label}</span>
      </span>
    );
  }

  if (style === "flat" || style === "ink") {
    const textColor = style === "ink" ? "var(--color-text-secondary)" : color;
    return (
      <span
        className="inline-flex max-w-full items-center gap-1 text-xs font-medium"
        style={{ color: textColor, maxWidth: maxW }}
      >
        {showIcon && (
          <span style={{ color }} className="inline-flex shrink-0">
            <AppIcon icon={icon as typeof Home01Icon} size={14} strokeWidth={1.75} />
          </span>
        )}
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
          maxWidth: maxW,
        }}
      >
        {showIcon && <AppIcon icon={icon as typeof Home01Icon} size={14} strokeWidth={1.75} />}
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
        maxWidth: maxW,
      }}
    >
      {showIcon && <AppIcon icon={icon as typeof Home01Icon} size={14} strokeWidth={1.75} />}
      <span className="truncate">{label}</span>
    </span>
  );
}
