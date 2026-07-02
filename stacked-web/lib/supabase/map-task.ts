import type { Priority, Subtask, Task } from "@/lib/types/task";
import { formatTaskDate, parseDueDate } from "@/lib/utils/date";

type DbRow = Record<string, unknown>;

function parsePriority(value: unknown): Priority | undefined {
  const v = String(value ?? "");
  if (v === "high") return "P1";
  if (v === "medium") return "P2";
  if (v === "low") return "P3";
  return undefined;
}

function mapSubtask(row: DbRow): Subtask {
  const due = parseDueDate(row.data_vencimento);
  const rawLabels = row.label_ids;
  const labelIds = Array.isArray(rawLabels)
    ? rawLabels.map((id) => String(id)).filter(Boolean)
    : undefined;
  return {
    id: row.id != null ? String(row.id) : undefined,
    name: String(row.titulo ?? ""),
    done: Boolean(row.concluida),
    notes: row.descricao ? String(row.descricao) : undefined,
    dueDate: due ? due.toISOString().slice(0, 10) : null,
    date: formatTaskDate(due),
    priority: parsePriority(row.prioridade),
    labelIds: labelIds?.length ? labelIds : undefined,
  };
}

export function mapTaskRow(row: DbRow): Task {
  const projectName =
    (row.projects as DbRow | null)?.nome != null
      ? String((row.projects as DbRow).nome)
      : null;
  const due = parseDueDate(row.data_vencimento);

  const subtasks = ((row.subtasks as DbRow[] | null) ?? [])
    .slice()
    .sort((a, b) => (Number(a.ordem) || 0) - (Number(b.ordem) || 0))
    .map(mapSubtask);

  const taskLabels = ((row.task_labels as DbRow[] | null) ?? []);
  const labelMeta = taskLabels
    .map((tl) => {
      const label = tl.labels as DbRow | null;
      if (!label?.id) return null;
      return {
        id: String(label.id),
        name: String(label.nome ?? ""),
        color: String(label.cor ?? "#9296A0"),
      };
    })
    .filter((l): l is { id: string; name: string; color: string } => l != null);
  const labelIds = labelMeta.map((l) => l.id);
  const labels = labelMeta.map((l) => l.name);

  let commentCount = 0;
  const comments = row.task_comments;
  if (Array.isArray(comments) && comments[0] && typeof comments[0] === "object") {
    commentCount = Number((comments[0] as DbRow).count) || 0;
  }

  const time = row.hora ? String(row.hora) : null;

  return {
    id: String(row.id),
    title: String(row.titulo ?? ""),
    preview: row.descricao ? String(row.descricao) : undefined,
    notes: row.descricao ? String(row.descricao) : undefined,
    project: projectName,
    projectId: row.project_id != null ? String(row.project_id) : null,
    sectionId: row.section_id != null ? String(row.section_id) : null,
    dueDate: due ? due.toISOString().slice(0, 10) : null,
    date: time ?? formatTaskDate(due),
    tag: labels[0],
    priority: parsePriority(row.prioridade),
    done: Boolean(row.concluida),
    time,
    subtasks,
    commentCount,
    labelIds: labelIds.length > 0 ? labelIds : undefined,
    labels: labelMeta.length > 0 ? labelMeta : undefined,
    recurrence:
      row.recorrencia != null && String(row.recorrencia).trim()
        ? String(row.recorrencia)
        : undefined,
    order: row.ordem != null ? Number(row.ordem) : undefined,
  };
}

export function mapTaskList(rows: unknown): Task[] {
  if (!Array.isArray(rows)) return [];
  return rows.map((r) => mapTaskRow(r as DbRow));
}

/** Paridade today_screen.dart — separa atrasadas vs hoje */
export function splitTodayPending(tasks: Task[], now = new Date()): {
  overdue: Task[];
  today: Task[];
} {
  const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const overdue: Task[] = [];
  const today: Task[] = [];

  for (const t of tasks) {
    const due = parseDueDate(t.dueDate);
    if (due && due.getTime() < todayStart.getTime()) overdue.push(t);
    else today.push(t);
  }
  return { overdue, today };
}
