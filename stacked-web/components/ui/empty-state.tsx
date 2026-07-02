import type { ReactNode } from "react"
import { AppIcon } from "@/components/ui/app-icon"
import type { Home01Icon } from "@hugeicons/core-free-icons"

type IconData = typeof Home01Icon

type EmptyStateProps = {
  icon: IconData
  title: string
  subtitle?: string
  action?: {
    label: string
    onClick: () => void
  }
  children?: ReactNode
}

export function EmptyState({ icon, title, subtitle, action, children }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center px-6 py-16 text-center">
      <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-[var(--color-surface-variant)] text-[var(--color-text-tertiary)]">
        <AppIcon icon={icon} size={24} />
      </div>
      <h3 className="text-base font-semibold text-[var(--color-text)]">{title}</h3>
      {subtitle && (
        <p className="mt-1.5 max-w-xs text-sm text-[var(--color-text-secondary)]">{subtitle}</p>
      )}
      {action && (
        <button
          type="button"
          onClick={action.onClick}
          className="mt-5 rounded-[var(--radius-sm)] btn-primary px-4 py-2 text-sm"
        >
          {action.label}
        </button>
      )}
      {children}
    </div>
  )
}
