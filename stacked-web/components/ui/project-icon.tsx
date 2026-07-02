import { AppIcon } from "@/components/ui/app-icon"
import { resolveProjectIcon } from "@/lib/icons/project-icons"

type ProjectIconProps = {
  iconKey?: string | null
  color: string
  size?: number
  className?: string
}

export function ProjectIcon({ iconKey, color, size = 18, className }: ProjectIconProps) {
  return (
    <span
      className={`flex shrink-0 items-center justify-center ${className ?? ""}`}
      style={{ color }}
      aria-hidden
    >
      <AppIcon icon={resolveProjectIcon(iconKey)} size={size} strokeWidth={1.75} />
    </span>
  )
}
