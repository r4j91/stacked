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
    <div className="flex flex-col items-center justify-center px-6 py-20 text-center">
      <div className="mb-5 flex h-16 w-16 items-center justify-center rounded-[var(--radius-lg)] bg-[var(--color-surface)] text-[var(--color-text-tertiary)]">
        <AppIcon icon={icon} size={32} strokeWidth={1.5} />
      </div>
      <h3 className="text-lg font-semibold text-[var(--color-text)]">{title}</h3>
      {subtitle && (
        <p className="mt-2 max-w-sm text-sm leading-relaxed text-[var(--color-text-secondary)]">
          {subtitle}
        </p>
      )}
      {action && (
        <button
          type="button"
          onClick={action.onClick}
          className="mt-6 rounded-[var(--radius-sm)] btn-primary px-4 py-2.5 text-sm"
        >
          {action.label}
        </button>
      )}
      {children}
    </div>
  )
}
