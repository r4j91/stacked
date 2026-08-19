import type { Priority, Subtask, Task } from "@/lib/types/task";
import { formatTaskDate, parseDueDate, startOfDay, toDateStr } from "@/lib/utils/date";
import { sortSubtasksForDisplay } from "@/lib/utils/subtask-ordering";

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
  const deadline = parseDueDate(row.deadline);
  const time = row.hora ? String(row.hora) : null;
  const rawLabels = row.label_ids;
  const labelIds = Array.isArray(rawLabels)
    ? rawLabels.map((id) => String(id)).filter(Boolean)
    : undefined;
  return {
    id: row.id != null ? String(row.id) : undefined,
    name: String(row.titulo ?? ""),
    done: Boolean(row.concluida),
    notes: row.descricao ? String(row.descricao) : undefined,
    dueDate: due ? toDateStr(due) : null,
    date: formatTaskDate(due),
    deadline: deadline ? toDateStr(deadline) : null,
    time,
    priority: parsePriority(row.prioridade),
    labelIds: labelIds?.length ? labelIds : undefined,
    valor: row.valor != null && Number.isFinite(Number(row.valor)) ? Number(row.valor) : null,
    includeInCashFlow: row.incluir_fluxo_caixa !== false,
    isIncome: row.valor_entrada === true,
  };
}

export function mapTaskRow(row: DbRow): Task {
  const projectName =
    (row.projects as DbRow | null)?.nome != null
      ? String((row.projects as DbRow).nome)
      : null;
  const due = parseDueDate(row.data_vencimento);
  const deadline = parseDueDate(row.deadline);

  const subtasks = sortSubtasksForDisplay(
    ((row.subtasks as DbRow[] | null) ?? []).map(mapSubtask),
  );

  const taskLabels = ((row.task_labels as DbRow[] | null) ?? [])
    .slice()
    .sort((a, b) => Number(a.sort_order ?? 0) - Number(b.sort_order ?? 0));
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
    dueDate: due ? toDateStr(due) : null,
    date: formatTaskDate(due),
    deadline: deadline ? toDateStr(deadline) : null,
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
    whatsappRoutine: Boolean(row.whatsapp_rotina),
    includeInCashFlow: row.incluir_fluxo_caixa !== false,
  };
}

export function mapTaskList(rows: unknown): Task[] {
  if (!Array.isArray(rows)) return [];
  return rows.map((r) => mapTaskRow(r as DbRow));
}

/** Paridade today_screen.dart — separa atrasadas vs hoje (due OU deadline vencido). */
export function splitTodayPending(tasks: Task[], now = new Date()): {
  overdue: Task[];
  today: Task[];
} {
  const todayStart = startOfDay(now);
  const overdue: Task[] = [];
  const today: Task[] = [];

  for (const t of tasks) {
    if (isTaskOverdue(t, now, todayStart)) overdue.push(t);
    else today.push(t);
  }
  return { overdue, today };
}

/** Atrasada se data de vencimento ou prazo (deadline) for antes de hoje. */
export function isTaskOverdue(
  task: Pick<Task, "dueDate" | "deadline" | "done">,
  now = new Date(),
  todayStart = startOfDay(now),
): boolean {
  if (task.done) return false;
  const due = parseDueDate(task.dueDate);
  const deadline = parseDueDate(task.deadline);
  if (due && due.getTime() < todayStart.getTime()) return true;
  if (deadline && deadline.getTime() < todayStart.getTime()) return true;
  return false;
}
