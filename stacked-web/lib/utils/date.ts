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

export function parseDueDate(raw: unknown): Date | null {
  if (raw == null) return null;
  const str = String(raw).trim();
  if (!str) return null;
  const dt = new Date(str.length === 10 ? `${str}T12:00:00` : str);
  return Number.isNaN(dt.getTime()) ? null : startOfDay(dt);
}

export function formatTodaySubtitle(d = new Date()): string {
  return `${WEEKDAYS[d.getDay()]}, ${d.getDate()} de ${MONTHS[d.getMonth()]}`;
}

export function formatTaskDate(due: Date | null, now = new Date()): string | null {
  if (!due) return null;
  const today = startOfDay(now);
  const diff = Math.round((due.getTime() - today.getTime()) / 86400000);
  if (diff === 0) return "hoje";
  if (diff === -1) return "ontem";
  if (diff === 1) return "amanhã";
  if (diff > -7 && diff < 7) {
    return `${due.getDate()} ${MONTHS[due.getMonth()].slice(0, 3)}`;
  }
  return `${due.getDate()} ${MONTHS[due.getMonth()].slice(0, 3)}`;
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
