const WEEKDAYS = [
  "Domingo",
  "Segunda-feira",
  "Terça-feira",
  "Quarta-feira",
  "Quinta-feira",
  "Sexta-feira",
  "Sábado",
];
const MONTHS = [
  "janeiro",
  "fevereiro",
  "março",
  "abril",
  "maio",
  "junho",
  "julho",
  "agosto",
  "setembro",
  "outubro",
  "novembro",
  "dezembro",
];

export function toDateStr(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

export function startOfDay(d: Date): Date {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

export function toIsoTimestamp(d: Date): string {
  return d.toISOString();
}

/** Limites [início, fim) do dia civil local em ISO8601 para `data_conclusao`. */
export function completionDayBounds(date = new Date()): { start: string; end: string } {
  const start = startOfDay(date);
  const end = new Date(start);
  end.setDate(end.getDate() + 1);
  return { start: toIsoTimestamp(start), end: toIsoTimestamp(end) };
}

export function parseCompletionTimestamp(raw: unknown): Date | null {
  if (raw == null) return null;
  const str = String(raw).trim();
  if (!str) return null;
  const dt = new Date(str);
  return Number.isNaN(dt.getTime()) ? null : dt;
}

export function parseDueDate(raw: unknown): Date | null {
  if (raw == null) return null;
  const str = String(raw).trim();
  if (!str) return null;

  // Sempre preferir YYYY-MM-DD civil (paridade iOS TaskMapper.parseDueDate).
  // timestamptz "2026-07-01T00:00:00+00:00" vira 30/jun no Brasil se parsear ISO completo.
  const head = str.length >= 10 ? str.slice(0, 10) : str;
  if (/^\d{4}-\d{2}-\d{2}$/.test(head)) {
    const dt = new Date(`${head}T12:00:00`);
    return Number.isNaN(dt.getTime()) ? null : startOfDay(dt);
  }

  const dt = new Date(str);
  return Number.isNaN(dt.getTime()) ? null : startOfDay(dt);
}

export function formatTodaySubtitle(d = new Date()): string {
  return `${WEEKDAYS[d.getDay()]}, ${d.getDate()} de ${MONTHS[d.getMonth()]}`;
}

export function formatTaskDate(due: Date | null, now = new Date()): string | null {
  if (!due) return null;
  const today = startOfDay(now);
  const diff = Math.round((due.getTime() - today.getTime()) / 86400000);
  if (diff === 0) return "Hoje";
  if (diff === -1) return "ontem";
  if (diff === 1) return "amanhã";
  if (diff > -7 && diff < 7) {
    return `${due.getDate()} ${MONTHS[due.getMonth()].slice(0, 3)}`;
  }
  return `${due.getDate()} ${MONTHS[due.getMonth()].slice(0, 3)}`;
}

/** HH:MM ou HH:MM:SS → exibição compacta (paridade TaskMapper.formatTimeDisplay). */
export function formatTimeDisplay(time: string | null | undefined): string | null {
  if (!time) return null;
  const trimmed = time.trim();
  if (!trimmed) return null;
  const parts = trimmed.split(":");
  if (parts.length < 2) return trimmed;
  const h = Number(parts[0]);
  const m = Number(parts[1]);
  if (Number.isNaN(h) || Number.isNaN(m)) return trimmed;
  return `${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}`;
}

export function formatDueDateTimeLabel(
  dueDate: string | null | undefined,
  time?: string | null,
  now = new Date(),
): string | null {
  const due = parseDueDate(dueDate);
  if (!due) return null;
  const datePart = formatDayLabel(due, now);
  const timePart = formatTimeDisplay(time);
  return timePart ? `${datePart} · ${timePart}` : datePart;
}

export function addDays(d: Date, days: number): Date {
  const next = new Date(d);
  next.setDate(next.getDate() + days);
  return startOfDay(next);
}

const SHORT_WEEKDAYS = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"];
const SHORT_MONTHS = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"];

export function formatDayLabel(date: Date, now = new Date()): string {
  const today = startOfDay(now);
  const d = startOfDay(date);
  const diff = Math.round((d.getTime() - today.getTime()) / 86400000);
  if (diff === 0) return "Hoje";
  if (diff === 1) return "Amanhã";
  return `${SHORT_WEEKDAYS[d.getDay()]}, ${d.getDate()} ${SHORT_MONTHS[d.getMonth()]}`;
}

export function dateKey(d: Date): string {
  return toDateStr(startOfDay(d));
}

export function parseDateKey(key: string): Date {
  return parseDueDate(key)!;
}

export function monthLabel(d: Date): string {
  return `${MONTHS[d.getMonth()]} ${d.getFullYear()}`;
}

export function isOverdueDate(due: Date | null, done: boolean, now = new Date()): boolean {
  if (!due || done) return false;
  return due.getTime() < startOfDay(now).getTime();
}

export function isDueToday(due: Date | null, now = new Date()): boolean {
  if (!due) return false;
  return due.getTime() === startOfDay(now).getTime();
}

export function dueDateChipColor(
  due: Date | null,
  done: boolean,
  now = new Date(),
): string {
  if (!due || done) return "var(--color-text-tertiary)";
  if (isOverdueDate(due, done, now)) return "var(--color-overdue)";
  if (isDueToday(due, now)) return "var(--color-due-today)";
  return "var(--color-date-upcoming)";
}
