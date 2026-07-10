import type { Task } from "@/lib/types/task";
import { parseDueDate } from "@/lib/utils/date";

function sanitizeInline(text: string): string {
  return text
    .replace(/\*/g, "")
    .replace(/_/g, "")
    .replace(/~/g, "")
    .trim();
}

function formatDate(date: Date): string {
  return date.toLocaleDateString("pt-BR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  });
}

function parseDescriptionLines(description?: string | null): string[] {
  if (!description) return [];
  return description
    .split(/\r?\n/)
    .map(sanitizeInline)
    .filter(Boolean);
}

export function composeWhatsAppRoutineMessage(input: {
  taskTitle: string;
  dueDate?: Date | null;
  description?: string | null;
}): string {
  const title = sanitizeInline(input.taskTitle);
  const dateStr = formatDate(input.dueDate ?? new Date());
  const descLines = parseDescriptionLines(input.description);

  const lines: string[] = [`*${title} — ${dateStr}*`];

  if (descLines.length === 0) return lines.join("\n");

  lines.push("");

  if (descLines.length === 1) {
    lines.push(`• *${descLines[0]}*`);
  } else {
    lines.push(`*${descLines[0]}*`);
    lines.push("");
    for (const item of descLines.slice(1)) {
      lines.push(`• *${item}*`);
    }
  }

  return lines.join("\n");
}

export function taskShowsWhatsAppCopy(task: Pick<Task, "whatsappRoutine" | "notes">): boolean {
  return Boolean(task.whatsappRoutine && task.notes?.trim());
}

export function buildWhatsAppRoutineMessage(task: Pick<Task, "title" | "dueDate" | "notes">): string {
  return composeWhatsAppRoutineMessage({
    taskTitle: task.title,
    dueDate: task.dueDate ? parseDueDate(task.dueDate) : new Date(),
    description: task.notes,
  });
}
