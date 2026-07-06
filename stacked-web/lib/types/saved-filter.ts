export type FilterDateScope = "any" | "overdue" | "today" | "week" | "no_date";

export type FilterPriorityCriteria = "high" | "medium" | "low" | "none";

export type FilterCriteria = {
  labelIds: string[];
  priorities: FilterPriorityCriteria[];
  projectId: string | null;
  dateScope: FilterDateScope;
};

export type SavedFilter = {
  id: string;
  name: string;
  color: string | null;
  criteria: FilterCriteria;
  sortOrder: number;
};

export type SavedFilterWithCount = SavedFilter & {
  pendingCount: number;
};

export const EMPTY_FILTER_CRITERIA: FilterCriteria = {
  labelIds: [],
  priorities: [],
  projectId: null,
  dateScope: "any",
};

export function normalizeFilterCriteria(raw: unknown): FilterCriteria {
  if (!raw || typeof raw !== "object") return { ...EMPTY_FILTER_CRITERIA };
  const o = raw as Record<string, unknown>;
  const dateScope = o.dateScope;
  const validDate: FilterDateScope[] = ["any", "overdue", "today", "week", "no_date"];
  return {
    labelIds: Array.isArray(o.labelIds) ? o.labelIds.filter((x): x is string => typeof x === "string") : [],
    priorities: Array.isArray(o.priorities)
      ? o.priorities.filter((x): x is FilterPriorityCriteria =>
          x === "high" || x === "medium" || x === "low" || x === "none",
        )
      : [],
    projectId: typeof o.projectId === "string" ? o.projectId : null,
    dateScope: validDate.includes(dateScope as FilterDateScope) ? (dateScope as FilterDateScope) : "any",
  };
}
