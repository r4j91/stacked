import type { Subtask } from "@/lib/types/task";

function pendingSort(a: Subtask, b: Subtask): number {
  const da = a.dueDate ? new Date(a.dueDate).getTime() : null;
  const db = b.dueDate ? new Date(b.dueDate).getTime() : null;
  if (da != null && db != null) {
    if (da !== db) return da - db;
    return 0;
  }
  if (da != null) return -1;
  if (db != null) return 1;
  return 0;
}

/** Pendentes primeiro (por vencimento), concluídas no final — paridade iOS. */
export function sortSubtasksForDisplay(subtasks: Subtask[]): Subtask[] {
  const pending = subtasks.filter((s) => !s.done).sort(pendingSort);
  const done = subtasks.filter((s) => s.done);
  return [...pending, ...done];
}
