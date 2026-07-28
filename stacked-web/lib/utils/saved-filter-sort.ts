import type { FilterResultItem } from "@/lib/types/filter-result";

/** Ordenação da lista de resultados de filtro salvo/preset (⋮ do drill-down) — paridade iOS SavedFilterSortPreferences. */
export type SavedFilterSortMode = "dueDate" | "alphabetical" | "priority";

export const DEFAULT_SAVED_FILTER_SORT_MODE: SavedFilterSortMode = "dueDate";

export const SAVED_FILTER_SORT_MODES: SavedFilterSortMode[] = ["dueDate", "alphabetical", "priority"];

export const SAVED_FILTER_SORT_LABELS: Record<SavedFilterSortMode, string> = {
  dueDate: "Por vencimento",
  alphabetical: "Ordem alfabética",
  priority: "Por prioridade",
};

export function savedFilterSortKey(filterId: string): string {
  return `saved_filter_sort_${filterId}`;
}

export function loadSavedFilterSortMode(filterId: string): SavedFilterSortMode {
  if (typeof window === "undefined") return DEFAULT_SAVED_FILTER_SORT_MODE;
  try {
    const raw = window.localStorage.getItem(savedFilterSortKey(filterId));
    if (raw && SAVED_FILTER_SORT_MODES.includes(raw as SavedFilterSortMode)) {
      return raw as SavedFilterSortMode;
    }
  } catch {
    // ignore
  }
  return DEFAULT_SAVED_FILTER_SORT_MODE;
}

export function saveSavedFilterSortMode(filterId: string, mode: SavedFilterSortMode): void {
  if (typeof window === "undefined") return;
  try {
    window.localStorage.setItem(savedFilterSortKey(filterId), mode);
  } catch {
    // ignore
  }
}

function titleOf(item: FilterResultItem): string {
  return item.kind === "task" ? item.task.title : item.subtask.name;
}

/** ISO date string; itens sem data vão para o fim (sentinel bem distante). */
function dueDateOf(item: FilterResultItem): string {
  const raw = item.kind === "task" ? item.task.dueDate : item.subtask.dueDate;
  return raw ?? "9999-12-31";
}

function priorityRankOf(item: FilterResultItem): number {
  const priority = item.kind === "task" ? item.task.priority : item.subtask.priority;
  switch (priority) {
    case "P1":
      return 0;
    case "P2":
      return 1;
    case "P3":
      return 2;
    default:
      return 3;
  }
}

export function sortFilterResults(
  items: FilterResultItem[],
  mode: SavedFilterSortMode,
): FilterResultItem[] {
  const withTitleCompare = (a: FilterResultItem, b: FilterResultItem) =>
    titleOf(a).localeCompare(titleOf(b), "pt-BR", { sensitivity: "base" });

  const sorted = [...items];
  switch (mode) {
    case "dueDate":
      sorted.sort((a, b) => {
        const diff = dueDateOf(a).localeCompare(dueDateOf(b));
        return diff !== 0 ? diff : withTitleCompare(a, b);
      });
      break;
    case "alphabetical":
      sorted.sort(withTitleCompare);
      break;
    case "priority":
      sorted.sort((a, b) => {
        const diff = priorityRankOf(a) - priorityRankOf(b);
        return diff !== 0 ? diff : withTitleCompare(a, b);
      });
      break;
  }
  return sorted;
}
