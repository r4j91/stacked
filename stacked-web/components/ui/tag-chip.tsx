import { AppIcon } from "@/components/ui/app-icon";
import { Tag01Icon } from "@/lib/icons/nav-icons";
import type { Home01Icon } from "@hugeicons/core-free-icons";

type TagChipProps = {
  label: string;
  color: string;
  icon?: typeof Tag01Icon;
  showIcon?: boolean;
  maxWidth?: number;
};

export function TagChip({ label, color, icon = Tag01Icon, showIcon = true, maxWidth }: TagChipProps) {
  const chip = (
    <span
      className="inline-flex max-w-full items-center gap-1 rounded-md border px-1.5 py-0.5 text-xs font-medium"
      style={{
        color,
        backgroundColor: `color-mix(in srgb, ${color} 12%, transparent)`,
        borderColor: `color-mix(in srgb, ${color} 30%, transparent)`,
        maxWidth: maxWidth ? `${maxWidth}px` : undefined,
      }}
    >
      {showIcon && <AppIcon icon={icon as typeof Home01Icon} size={11} strokeWidth={1.75} />}
      <span className="truncate">{label}</span>
    </span>
  );
  return chip;
}
