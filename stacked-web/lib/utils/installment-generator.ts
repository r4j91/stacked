/** Paridade stacked-ios InstallmentGeneratorLogic + lib/widgets/installment_generator_sheet.dart */

export type InstallmentFrequency = "monthly" | "biweekly" | "weekly";

const MONTH_ABBREV = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"];

export function parseInstallmentValor(raw: string): number | null {
  const trimmed = raw.trim();
  if (!trimmed) return null;
  const normalized = trimmed.replace(",", ".");
  const n = Number(normalized);
  return Number.isFinite(n) ? n : null;
}

function addMonths(date: Date, months: number): Date {
  const day = date.getDate();
  const hours = date.getHours();
  const minutes = date.getMinutes();
  const totalMonths = date.getMonth() + months;
  const year = date.getFullYear() + Math.floor(totalMonths / 12);
  const month = ((totalMonths % 12) + 12) % 12;
  const lastDay = new Date(year, month + 1, 0).getDate();
  return new Date(year, month, Math.min(day, lastDay), hours, minutes, 0, 0);
}

export function generateInstallmentDates(
  quantity: number,
  firstDueDate: Date,
  frequency: InstallmentFrequency,
): Date[] {
  return Array.from({ length: quantity }, (_, index) => {
    switch (frequency) {
      case "weekly":
        return new Date(firstDueDate.getTime() + index * 7 * 86400000);
      case "biweekly":
        return new Date(firstDueDate.getTime() + index * 14 * 86400000);
      case "monthly":
      default:
        return addMonths(firstDueDate, index);
    }
  });
}

export function formatInstallmentDate(date: Date): string {
  const day = String(date.getDate()).padStart(2, "0");
  const month = MONTH_ABBREV[date.getMonth()] ?? "";
  return `${day} ${month} ${date.getFullYear()}`;
}

export function formatInstallmentTime(date: Date): string {
  const h = String(date.getHours()).padStart(2, "0");
  const m = String(date.getMinutes()).padStart(2, "0");
  return `${h}:${m}`;
}

export function formatInstallmentValor(value: number): string {
  return new Intl.NumberFormat("pt-BR", {
    style: "currency",
    currency: "BRL",
  }).format(value);
}

export const INSTALLMENT_FREQUENCY_OPTIONS: { value: InstallmentFrequency; label: string }[] = [
  { value: "monthly", label: "Mensal" },
  { value: "biweekly", label: "Quinzenal" },
  { value: "weekly", label: "Semanal" },
];
