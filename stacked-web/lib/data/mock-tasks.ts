export type { Task, Subtask, Priority, ViewMode, ViewTasks, TodayStats } from "@/lib/types/task";
export type { Project, Section } from "@/lib/types/project";
export type { Label } from "@/lib/types/label";
import type { SavedFilter, SavedFilterWithCount } from "@/lib/types/saved-filter";
import {
  buildCompletedFilterResults,
  buildPendingFilterResults,
  countPendingFilterResults,
} from "@/lib/utils/filter-criteria";

export type MockProject = {
  id: string;
  name: string;
  color: string;
  icon?: string;
  count: number;
};

export const MOCK_LABELS: import("@/lib/types/label").Label[] = [
  { id: "l1", name: "Em Andamento", color: "#8FD46B", sortOrder: 0 },
  { id: "l2", name: "Ideia", color: "#B18CF5", sortOrder: 1 },
];

export const MOCK_SAVED_FILTERS: SavedFilter[] = [
  {
    id: "sf1",
    name: "Trabalho urgente",
    color: "#EF5A5F",
    sortOrder: 0,
    criteria: { labelIds: [], priorities: ["high"], projectId: "p1", dateScope: "any" },
  },
  {
    id: "sf2",
    name: "Em andamento",
    color: "#8FD46B",
    sortOrder: 1,
    criteria: { labelIds: ["l1"], priorities: [], projectId: null, dateScope: "any" },
  },
];

let mockSavedFiltersState = [...MOCK_SAVED_FILTERS];

function mockSavedFiltersList(): SavedFilter[] {
  return mockSavedFiltersState;
}

export const MOCK_PROJECTS: MockProject[] = [
  { id: "p1", name: "Trabalho", color: "#E8E8EC", icon: "work", count: 1 },
  { id: "p2", name: "Rodrigo", color: "#9A9AA2", icon: "home", count: 1 },
  { id: "p3", name: "Pessoal", color: "#65656D", icon: "folder", count: 0 },
];

export const MOCK_SECTIONS: import("@/lib/types/project").Section[] = [
  {
    id: "sec1",
    projectId: "p2",
    name: "Compras",
    order: 0,
    createdAt: "2026-01-01T00:00:00Z",
  },
];

/** Fallback quando Supabase não está configurado ou sem sessão em dev */
export const MOCK_TASKS: import("@/lib/types/task").Task[] = [
  {
    id: "1",
    title: "Revisar contrato",
    preview: "Cláusulas de rescisão e prazo de entrega",
    project: "Trabalho",
    projectId: "p1",
    date: "28 jun",
    dueDate: "2026-06-28",
    priority: "P1",
    done: false,
    labelIds: [],
  },
  {
    id: "4",
    title: "Teste 3",
    preview: "Validar fluxo de subtarefas no inspector",
    project: "Rodrigo",
    projectId: "p2",
    sectionId: "sec1",
    date: "23:05",
    dueDate: "2026-06-28",
    tag: "Em Andamento",
    labelIds: ["l1"],
    done: false,
    subtasks: [
      { id: "s1", name: "Presunto", done: false, notes: "Comprar fatias finas." },
      { id: "s2", name: "Item 2", done: true },
    ],
  },
  {
    id: "5",
    title: "Revisão geral",
    project: "Trabalho",
    projectId: "p1",
    done: false,
    labelIds: [],
    subtasks: [{ id: "s3", name: "Ajustar prioridade alta", done: false, priority: "P1" }],
  },
];

export function mockProjectsAsSidebar(): MockProject[] {
  return MOCK_PROJECTS.map((p) => ({
    ...p,
    count: MOCK_TASKS.filter((t) => t.projectId === p.id && !t.done).length,
  }));
}

export function mockProjectById(id: string): MockProject | undefined {
  return mockProjectsAsSidebar().find((p) => p.id === id);
}

export function mockProjectTasks(projectId: string) {
  const tasks = MOCK_TASKS.filter((t) => t.projectId === projectId);
  return {
    pending: tasks.filter((t) => !t.done),
    completed: tasks.filter((t) => t.done),
  };
}

export function mockSectionsForProject(projectId: string) {
  return MOCK_SECTIONS.filter((s) => s.projectId === projectId);
}

export function mockDatedPendingTasks() {
  return MOCK_TASKS.filter((t) => !t.done && t.dueDate);
}

export function mockAllPendingTasks() {
  return MOCK_TASKS.filter((t) => !t.done);
}

export function mockFilterCounts(): import("@/lib/types/task").FilterDashboardCounts {
  const today = "2026-06-28";
  const weekEnd = "2026-07-05";
  let overdue = 0;
  let todayCount = 0;
  let week = 0;
  for (const t of MOCK_TASKS.filter((x) => !x.done && x.dueDate)) {
    const d = t.dueDate!;
    if (d < today) overdue++;
    else if (d === today) todayCount++;
    else if (d > today && d <= weekEnd) week++;
  }
  return {
    overdue,
    today: todayCount,
    week,
    completedToday: MOCK_TASKS.filter((t) => t.done).length,
  };
}

export function mockFilteredTasks(kind: import("@/lib/types/task").TaskFilterKind) {
  const today = "2026-06-28";
  const weekEnd = "2026-07-05";
  return MOCK_TASKS.filter((t) => {
    if (!t.dueDate && kind !== "completedToday") return false;
    switch (kind) {
      case "overdue":
        return !t.done && t.dueDate! < today;
      case "today":
        return !t.done && t.dueDate === today;
      case "week":
        return !t.done && t.dueDate! > today && t.dueDate! <= weekEnd;
      case "completedToday":
        return t.done;
      default:
        return false;
    }
  });
}

export function mockSavedFiltersWithCounts(): SavedFilterWithCount[] {
  return mockSavedFiltersList().map((f) => ({
    ...f,
    pendingCount: countPendingFilterResults(MOCK_TASKS, f.criteria),
  }));
}

export function mockSavedFilterById(id: string): SavedFilter | undefined {
  return mockSavedFiltersList().find((f) => f.id === id);
}

export function mockCreateSavedFilter(input: {
  name: string;
  color: string | null;
  criteria: SavedFilter["criteria"];
}): SavedFilter {
  const filter: SavedFilter = {
    id: `sf-mock-${Date.now()}`,
    name: input.name,
    color: input.color,
    criteria: input.criteria,
    sortOrder: mockSavedFiltersState.length,
  };
  mockSavedFiltersState = [...mockSavedFiltersState, filter];
  return filter;
}

export function mockUpdateSavedFilter(
  id: string,
  input: { name: string; color: string | null; criteria: SavedFilter["criteria"] },
): SavedFilter | undefined {
  const idx = mockSavedFiltersState.findIndex((f) => f.id === id);
  if (idx < 0) return undefined;
  const updated: SavedFilter = {
    ...mockSavedFiltersState[idx]!,
    name: input.name,
    color: input.color,
    criteria: input.criteria,
  };
  mockSavedFiltersState = mockSavedFiltersState.map((f) => (f.id === id ? updated : f));
  return updated;
}

export function mockDeleteSavedFilter(id: string): void {
  mockSavedFiltersState = mockSavedFiltersState.filter((f) => f.id !== id);
}

export function mockTasksMatchingCriteria(
  criteria: import("@/lib/types/saved-filter").FilterCriteria,
  includeCompleted = false,
) {
  const pending = buildPendingFilterResults(MOCK_TASKS, criteria);
  const completed = buildCompletedFilterResults(MOCK_TASKS, criteria);
  if (includeCompleted) return [...pending, ...completed];
  return pending;
}

export function mockPendingAndCompletedMatchingCriteria(
  criteria: import("@/lib/types/saved-filter").FilterCriteria,
) {
  return {
    pending: buildPendingFilterResults(MOCK_TASKS, criteria),
    completed: buildCompletedFilterResults(MOCK_TASKS, criteria),
  };
}
