import type { Subtask, Task } from "@/lib/types/task";

export type FilterResultItem =
  | { kind: "task"; task: Task }
  | { kind: "subtask"; subtask: Subtask; parent: Task; subtaskIndex: number };

export function filterResultId(item: FilterResultItem): string {
  if (item.kind === "task") return `task-${item.task.id}`;
  const subId = item.subtask.id ?? `${item.parent.id}:${item.subtaskIndex}`;
  return `subtask-${subId}`;
}

export function filterResultCountLabel(count: number): string {
  if (count === 0) return "0 itens";
  if (count === 1) return "1 item";
  return `${count} itens`;
}
