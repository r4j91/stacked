import type { Priority } from "@/lib/types/task"

export type DbPriority = "high" | "medium" | "low"

export function toDbPriority(priority?: Priority | null): DbPriority | null {
  switch (priority) {
    case "P1":
      return "high"
    case "P2":
      return "medium"
    case "P3":
      return "low"
    default:
      return null
  }
}

export function fromDbPriority(value: unknown): Priority | undefined {
  const v = String(value ?? "")
  if (v === "high") return "P1"
  if (v === "medium") return "P2"
  if (v === "low") return "P3"
  return undefined
}

export function priorityLabel(priority?: Priority | null): string {
  switch (priority) {
    case "P1":
      return "Alta"
    case "P2":
      return "Média"
    case "P3":
      return "Baixa"
    default:
      return "Nenhuma"
  }
}

export function priorityColor(priority?: Priority | null): string {
  switch (priority) {
    case "P1":
      return "var(--color-p1)"
    case "P2":
      return "var(--color-p2)"
    case "P3":
      return "var(--color-p3)"
    default:
      return "var(--color-text-secondary)"
  }
}
