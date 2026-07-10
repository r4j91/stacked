const KEY = "subtask_expanded_task_ids";

export function loadExpandedSubtaskIds(): Set<string> {
  if (typeof window === "undefined") return new Set();
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return new Set();
    const parsed = JSON.parse(raw) as unknown;
    if (!Array.isArray(parsed)) return new Set();
    return new Set(parsed.map(String));
  } catch {
    return new Set();
  }
}

export function saveExpandedSubtaskIds(ids: Set<string>): void {
  if (typeof window === "undefined") return;
  localStorage.setItem(KEY, JSON.stringify([...ids]));
}
