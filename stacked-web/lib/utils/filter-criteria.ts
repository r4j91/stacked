import type { Label } from "@/lib/types/label";
import type { Priority, Subtask, Task } from "@/lib/types/task";
import type { Project } from "@/lib/types/project";
import type { FilterCriteria, FilterDateScope, FilterPriorityCriteria } from "@/lib/types/saved-filter";
import type { FilterResultItem } from "@/lib/types/filter-result";
import { addDays, parseDueDate, startOfDay, toDateStr } from "@/lib/utils/date";
import { priorityLabel } from "@/lib/utils/priority";

export function criteriaSummary(
  criteria: FilterCriteria,
  labels: Label[],
  projects: Project[],
): string {
  const parts: string[] = [];
  if (criteria.labelIds.length) {
    const names = criteria.labelIds
      .map((id) => labels.find((l) => l.id === id)?.name)
      .filter(Boolean) as string[];
    if (names.length === 1) parts.push(`Etiqueta ${names[0]}`);
    else if (names.length > 1) parts.push(`${names.length} etiquetas`);
  }
  if (criteria.priorities.length === 1) {
    const p = criteria.priorities[0]!;
    parts.push(
      p === "none"
        ? "Sem prioridade"
        : p === "high"
          ? "Prioridade Alta"
          : p === "medium"
            ? "Prioridade Média"
            : "Prioridade Baixa",
    );
  } else if (criteria.priorities.length > 1) {
    parts.push(`${criteria.priorities.length} prioridades`);
  }
  if (criteria.projectId) {
    const proj = projects.find((p) => p.id === criteria.projectId);
    if (proj) parts.push(proj.name);
  }
  if (criteria.dateScope !== "any") {
    parts.push(dateScopeLabel(criteria.dateScope));
  }
  return parts.length ? parts.join(" · ") : "Todos os critérios";
}

export function dateScopeLabel(scope: FilterDateScope): string {
  switch (scope) {
    case "overdue":
      return "Atrasadas";
    case "today":
      return "Hoje";
    case "week":
      return "Próximos 7 dias";
    case "no_date":
      return "Sem data";
    default:
      return "Qualquer data";
  }
}

function priorityToCriteria(p?: Priority | null): FilterPriorityCriteria {
  if (!p) return "none";
  if (p === "P1") return "high";
  if (p === "P2") return "medium";
  return "low";
}

function matchesPriority(priority: Priority | undefined | null, priorities: FilterPriorityCriteria[]): boolean {
  if (!priorities.length) return true;
  return priorities.includes(priorityToCriteria(priority));
}

function matchesLabels(labelIds: string[], required: string[]): boolean {
  if (!required.length) return true;
  const ids = new Set(labelIds);
  return required.every((id) => ids.has(id));
}

function matchesDate(due: string | null | undefined, scope: FilterDateScope, now = new Date()): boolean {
  if (scope === "any") return true;
  const todayStr = toDateStr(startOfDay(now));
  const weekStr = toDateStr(addDays(startOfDay(now), 7));
  if (scope === "no_date") return !due;
  if (!due) return false;
  const dueStr = due.length >= 10 ? due.slice(0, 10) : due;
  switch (scope) {
    case "overdue":
      return dueStr < todayStr;
    case "today":
      return dueStr === todayStr;
    case "week":
      return dueStr > todayStr && dueStr <= weekStr;
    default:
      return true;
  }
}

function taskLabelIds(task: Task): string[] {
  return task.labelIds ?? task.labels?.map((l) => l.id) ?? [];
}

function subtaskDueStr(sub: Subtask): string | null | undefined {
  return sub.dueDate ?? sub.date ?? null;
}

export function taskMatchesCriteria(task: Task, criteria: FilterCriteria, now = new Date()): boolean {
  if (criteria.projectId && task.projectId !== criteria.projectId) return false;
  if (!matchesPriority(task.priority, criteria.priorities)) return false;
  if (!matchesLabels(taskLabelIds(task), criteria.labelIds)) return false;
  if (!matchesDate(task.dueDate ?? task.date, criteria.dateScope, now)) return false;
  return true;
}

export function subtaskMatchesCriteria(
  sub: Subtask,
  parent: Task,
  criteria: FilterCriteria,
  now = new Date(),
): boolean {
  if (criteria.projectId && parent.projectId !== criteria.projectId) return false;
  if (!matchesPriority(sub.priority, criteria.priorities)) return false;
  if (!matchesLabels(sub.labelIds ?? [], criteria.labelIds)) return false;
  if (!matchesDate(subtaskDueStr(sub), criteria.dateScope, now)) return false;
  return true;
}

/** Lista estilo Todoist: tarefa inteira ou subtarefas avulsas quando só elas batem. */
export function buildPendingFilterResults(
  tasks: Task[],
  criteria: FilterCriteria,
  now = new Date(),
): FilterResultItem[] {
  const results: FilterResultItem[] = [];
  for (const task of tasks) {
    if (task.done) continue;
    if (taskMatchesCriteria(task, criteria, now)) {
      results.push({ kind: "task", task });
      continue;
    }
    const subs = task.subtasks ?? [];
    subs.forEach((sub, index) => {
      if (sub.done) return;
      if (subtaskMatchesCriteria(sub, task, criteria, now)) {
        results.push({ kind: "subtask", subtask: sub, parent: task, subtaskIndex: index });
      }
    });
  }
  return results;
}

export function buildCompletedFilterResults(
  tasks: Task[],
  criteria: FilterCriteria,
  now = new Date(),
): FilterResultItem[] {
  const results: FilterResultItem[] = [];
  for (const task of tasks) {
    if (task.done && taskMatchesCriteria(task, criteria, now)) {
      results.push({ kind: "task", task });
      continue;
    }
    const subs = task.subtasks ?? [];
    subs.forEach((sub, index) => {
      if (!sub.done) return;
      if (subtaskMatchesCriteria(sub, task, criteria, now)) {
        results.push({ kind: "subtask", subtask: sub, parent: task, subtaskIndex: index });
      }
    });
  }
  return results;
}

export function countPendingFilterResults(
  tasks: Task[],
  criteria: FilterCriteria,
  now = new Date(),
): number {
  return buildPendingFilterResults(tasks, criteria, now).length;
}

export function dbPrioritiesFromCriteria(priorities: FilterPriorityCriteria[]): {
  includeNull: boolean;
  values: string[];
} {
  const includeNull = priorities.includes("none");
  const values = priorities
    .filter((p): p is "high" | "medium" | "low" => p !== "none")
    .map((p) => p);
  return { includeNull, values };
}

export function priorityCriteriaLabel(p: FilterPriorityCriteria): string {
  switch (p) {
    case "high":
      return "Prioridade 1";
    case "medium":
      return "Prioridade 2";
    case "low":
      return "Prioridade 3";
    case "none":
      return "Sem prioridade";
  }
}

export function priorityCriteriaColor(p: FilterPriorityCriteria): string {
  switch (p) {
    case "high":
      return "var(--color-p1)";
    case "medium":
      return "var(--color-p2)";
    case "low":
      return "var(--color-p3)";
    default:
      return "var(--color-text-tertiary)";
  }
}

export { priorityLabel };
