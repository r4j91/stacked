import { HugeiconsIcon } from "@hugeicons/react"
import type { Home01Icon } from "@hugeicons/core-free-icons"

type IconData = typeof Home01Icon

type AppIconProps = {
  icon: IconData
  size?: number
  className?: string
  strokeWidth?: number
}

export function AppIcon({
  icon,
  size = 20,
  className,
  strokeWidth = 1.75,
}: AppIconProps) {
  return (
    <HugeiconsIcon
      icon={icon}
      size={size}
      className={className}
      strokeWidth={strokeWidth}
    />
  )
}
