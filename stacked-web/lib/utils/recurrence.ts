/** Paridade lib/models/recurrence.dart */
export type RecurrenceType = "daily" | "weekly" | "monthly" | "yearly" | "custom"

export type Recurrence = {
  type: RecurrenceType
  weekdays?: string[]
  interval?: number
  intervalUnit?: "dias" | "semanas" | "meses"
}

const TYPE_TO_DB: Record<RecurrenceType, string> = {
  daily: "diario",
  weekly: "semanal",
  monthly: "mensal",
  yearly: "anual",
  custom: "personalizado",
}

const DB_TO_TYPE: Record<string, RecurrenceType> = {
  diario: "daily",
  semanal: "weekly",
  mensal: "monthly",
  anual: "yearly",
  personalizado: "custom",
}

const WEEKDAY_MAP: Record<string, number> = {
  seg: 1,
  ter: 2,
  qua: 3,
  qui: 4,
  sex: 5,
  sab: 6,
  dom: 7,
}

export function parseRecurrence(raw: unknown): Recurrence | null {
  if (raw == null) return null
  let map: Record<string, unknown>
  if (typeof raw === "string") {
    const trimmed = raw.trim()
    if (!trimmed) return null
    try {
      map = JSON.parse(trimmed) as Record<string, unknown>
    } catch {
      return null
    }
  } else if (typeof raw === "object") {
    map = raw as Record<string, unknown>
  } else {
    return null
  }

  const tipo = map.tipo
  if (typeof tipo !== "string") return null
  const type = DB_TO_TYPE[tipo]
  if (!type) return null

  return {
    type,
    weekdays: Array.isArray(map.dias) ? map.dias.map(String) : undefined,
    interval: typeof map.intervalo === "number" ? map.intervalo : undefined,
    intervalUnit:
      map.unidade === "dias" || map.unidade === "semanas" || map.unidade === "meses"
        ? map.unidade
        : undefined,
  }
}

export function recurrenceToJson(recurrence: Recurrence): string {
  const map: Record<string, unknown> = { tipo: TYPE_TO_DB[recurrence.type] }
  if (recurrence.weekdays?.length) map.dias = recurrence.weekdays
  if (recurrence.interval != null) map.intervalo = recurrence.interval
  if (recurrence.intervalUnit) map.unidade = recurrence.intervalUnit
  return JSON.stringify(map)
}

export function recurrenceLabel(recurrence: Recurrence): string {
  switch (recurrence.type) {
    case "daily":
      return "Todo dia"
    case "weekly":
      return "Toda semana"
    case "monthly":
      return "Todo mês"
    case "yearly":
      return "Todo ano"
    case "custom":
      if (recurrence.weekdays?.length) {
        const labels: Record<string, string> = {
          seg: "Seg",
          ter: "Ter",
          qua: "Qua",
          qui: "Qui",
          sex: "Sex",
          sab: "Sáb",
          dom: "Dom",
        }
        return recurrence.weekdays.map((day) => labels[day] ?? day).join(", ")
      }
      if (recurrence.interval != null && recurrence.intervalUnit) {
        return `A cada ${recurrence.interval} ${recurrence.intervalUnit}`
      }
      return "Personalizado"
  }
}

export function computeNextRecurrenceDate(from: Date, recurrence: Recurrence): Date | null {
  const base = new Date(from.getFullYear(), from.getMonth(), from.getDate())

  switch (recurrence.type) {
    case "daily":
      return addDays(base, 1)
    case "weekly":
      return addDays(base, 7)
    case "monthly":
      return new Date(base.getFullYear(), base.getMonth() + 1, base.getDate())
    case "yearly":
      return new Date(base.getFullYear() + 1, base.getMonth(), base.getDate())
    case "custom":
      if (recurrence.interval != null && recurrence.intervalUnit) {
        switch (recurrence.intervalUnit) {
          case "dias":
            return addDays(base, recurrence.interval)
          case "semanas":
            return addDays(base, recurrence.interval * 7)
          case "meses":
            return new Date(
              base.getFullYear(),
              base.getMonth() + recurrence.interval,
              base.getDate(),
            )
        }
      }
      if (recurrence.weekdays?.length) {
        for (let i = 1; i <= 7; i++) {
          const next = addDays(base, i)
          const weekday = next.getDay() === 0 ? 7 : next.getDay()
          if (recurrence.weekdays.some((day) => WEEKDAY_MAP[day] === weekday)) {
            return next
          }
        }
      }
      return null
  }
}

function addDays(date: Date, days: number): Date {
  const next = new Date(date)
  next.setDate(next.getDate() + days)
  return next
}
