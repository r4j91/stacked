export type Priority = "P1" | "P2" | "P3";

export type Subtask = {
  id?: string;
  name: string;
  done: boolean;
  notes?: string;
  date?: string | null;
  dueDate?: string | null;
  time?: string | null;
  /** Prazo final (Deadline) — independente de dueDate. ISO date YYYY-MM-DD. */
  deadline?: string | null;
  tag?: string;
  priority?: Priority;
  project?: string | null;
  labelIds?: string[];
  /** Valor monetário (parcelas). */
  valor?: number | null;
  /** Se false, esta subtarefa fica fora do fluxo de caixa. */
  includeInCashFlow?: boolean;
};

export type Task = {
  id: string;
  title: string;
  preview?: string;
  notes?: string;
  project?: string | null;
  projectId?: string | null;
  sectionId?: string | null;
  date?: string | null;
  dueDate?: string | null;
  /** Prazo final (Deadline) — independente de dueDate. ISO date YYYY-MM-DD. */
  deadline?: string | null;
  tag?: string;
  priority?: Priority;
  done: boolean;
  time?: string | null;
  subtasks?: Subtask[];
  commentCount?: number;
  labelIds?: string[];
  labels?: { id: string; name: string; color: string }[];
  recurrence?: string;
  order?: number;
  whatsappRoutine?: boolean;
  /** Se false, valores desta tarefa ficam fora do fluxo de caixa (iOS). */
  includeInCashFlow?: boolean;
};

export type ViewMode = "today" | "inbox" | "upcoming" | "done" | "project" | "filters";

export type TaskFilterKind = "overdue" | "today" | "week" | "completedToday";

export type FilterDashboardCounts = {
  overdue: number;
  today: number;
  week: number;
  completedToday: number;
};

export type TodayStats = {
  overdue: number;
  today: number;
  completed: number;
};

export type ViewTasks = {
  pending: Task[];
  completed: Task[];
  overdue?: Task[];
  today?: Task[];
};
