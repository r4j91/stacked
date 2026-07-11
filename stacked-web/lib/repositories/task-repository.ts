import type { SupabaseClient } from "@supabase/supabase-js";
import { TASK_SELECT } from "@/lib/supabase/task-select";
import { mapTaskList } from "@/lib/supabase/map-task";
import type { Priority, Task, TodayStats, ViewMode, ViewTasks, FilterDashboardCounts, TaskFilterKind } from "@/lib/types/task";
import type { FilterCriteria } from "@/lib/types/saved-filter";
import type { FilterResultItem } from "@/lib/types/filter-result";
import {
  buildCompletedFilterResults,
  buildPendingFilterResults,
} from "@/lib/utils/filter-criteria";
import { mapTaskRow, splitTodayPending } from "@/lib/supabase/map-task";
import { addDays, completionDayBounds, parseCompletionTimestamp, parseDueDate, startOfDay, toDateStr, toIsoTimestamp } from "@/lib/utils/date";
import { toDbPriority } from "@/lib/utils/priority";
import { requireAuthUserId } from "@/lib/supabase/require-auth-user";
import { computeNextRecurrenceDate, parseRecurrence } from "@/lib/utils/recurrence";

export class TaskRepository {
  constructor(private client: SupabaseClient) {}

  private todayStr(now = new Date()) {
    return toDateStr(startOfDay(now));
  }

  private async requireUserId(): Promise<string> {
    return requireAuthUserId(this.client);
  }

  private async getUserId(): Promise<string | null> {
    const {
      data: { user },
    } = await this.client.auth.getUser();
    return user?.id ?? null;
  }

  async fetchTodayTasks(): Promise<Task[]> {
    const todayStr = this.todayStr();
    const { data, error } = await this.client
      .from("tasks")
      .select(TASK_SELECT)
      .eq("concluida", false)
      .lte("data_vencimento", todayStr)
      .order("data_vencimento", { ascending: true })
      .order("ordem", { ascending: true })
      .order("id", { ascending: true });
    if (error) throw error;
    return mapTaskList(data);
  }

  async fetchCompletedTodayTasks(): Promise<Task[]> {
    const bounds = completionDayBounds();
    const { data, error } = await this.client
      .from("tasks")
      .select(TASK_SELECT)
      .eq("concluida", true)
      .gte("data_conclusao", bounds.start)
      .lt("data_conclusao", bounds.end)
      .order("data_conclusao", { ascending: false })
      .order("ordem", { ascending: true })
      .order("id", { ascending: true });
    if (error) throw error;
    return mapTaskList(data);
  }

  async fetchInboxTasks(): Promise<Task[]> {
    const { data, error } = await this.client
      .from("tasks")
      .select(TASK_SELECT)
      .eq("concluida", false)
      .is("data_vencimento", null)
      .is("project_id", null)
      .order("ordem", { ascending: true })
      .order("id", { ascending: true });
    if (error) throw error;
    return mapTaskList(data);
  }

  async fetchCompletedInboxTasks(): Promise<Task[]> {
    const { data, error } = await this.client
      .from("tasks")
      .select(TASK_SELECT)
      .eq("concluida", true)
      .is("data_vencimento", null)
      .is("project_id", null)
      .order("ordem", { ascending: true })
      .order("id", { ascending: true });
    if (error) throw error;
    return mapTaskList(data);
  }

  async fetchDatedPendingTasks(): Promise<Task[]> {
    const { data, error } = await this.client
      .from("tasks")
      .select(TASK_SELECT)
      .eq("concluida", false)
      .not("data_vencimento", "is", null)
      .order("data_vencimento", { ascending: true })
      .order("ordem", { ascending: true })
      .order("id", { ascending: true });
    if (error) throw error;
    return mapTaskList(data);
  }

  async fetchAllPendingTasks(): Promise<Task[]> {
    const { data, error } = await this.client
      .from("tasks")
      .select(TASK_SELECT)
      .eq("concluida", false)
      .order("data_vencimento", { ascending: true, nullsFirst: false })
      .order("ordem", { ascending: true })
      .order("id", { ascending: true });
    if (error) throw error;
    return mapTaskList(data);
  }

  async fetchUpcomingTasks(): Promise<Task[]> {
    const todayStr = this.todayStr();
    const { data, error } = await this.client
      .from("tasks")
      .select(TASK_SELECT)
      .eq("concluida", false)
      .gt("data_vencimento", todayStr)
      .order("data_vencimento", { ascending: true })
      .order("ordem", { ascending: true })
      .order("id", { ascending: true });
    if (error) throw error;
    return mapTaskList(data);
  }

  async toggleTaskDone(id: string, done: boolean): Promise<void> {
    const { error } = await this.client
      .from("tasks")
      .update({
        concluida: done,
        data_conclusao: done ? toIsoTimestamp(new Date()) : null,
      })
      .eq("id", id);
    if (error) throw error;
  }

  /** Marca concluída e cria próxima ocorrência quando aplicável. */
  async completeTask(task: Task): Promise<string | null> {
    await this.toggleTaskDone(task.id, true);
    return this.createNextOccurrence(task);
  }

  async createNextOccurrence(task: Task): Promise<string | null> {
    if (!task.recurrence || !task.dueDate) return null;
    const recurrence = parseRecurrence(task.recurrence);
    if (!recurrence) return null;
    const due = parseDueDate(task.dueDate);
    if (!due) return null;
    const next = computeNextRecurrenceDate(due, recurrence);
    if (!next) return null;

    const userId = await this.requireUserId();

    const { data: ordemRow } = await this.client
      .from("tasks")
      .select("ordem")
      .eq("id", task.id)
      .maybeSingle();
    const ordem = ordemRow?.ordem != null ? Number(ordemRow.ordem) : null;

    const { data: inserted, error } = await this.client
      .from("tasks")
      .insert({
        titulo: task.title,
        descricao: task.notes ?? null,
        prioridade: toDbPriority(task.priority),
        project_id: task.projectId ?? null,
        section_id: task.sectionId ?? null,
        data_vencimento: toDateStr(next),
        hora: task.time ?? null,
        recorrencia: task.recurrence,
        concluida: false,
        ...(ordem != null ? { ordem } : {}),
        user_id: userId,
      })
      .select("id")
      .single();
    if (error) throw error;

    const newId = String(inserted.id);
    if (task.labelIds?.length) {
      const { error: labelError } = await this.client.from("task_labels").insert(
        task.labelIds.map((labelId) => ({ task_id: newId, label_id: labelId })),
      );
      if (labelError) throw labelError;
    }
    return newId;
  }

  async toggleSubtaskDone(id: string, done: boolean): Promise<void> {
    const { error } = await this.client
      .from("subtasks")
      .update({
        concluida: done,
        data_conclusao: done ? toIsoTimestamp(new Date()) : null,
      })
      .eq("id", id);
    if (error) throw error;
  }

  async fetchProjectTasks(projectId: string): Promise<ViewTasks> {
    const { data, error } = await this.client
      .from("tasks")
      .select(TASK_SELECT)
      .eq("project_id", projectId)
      .order("concluida", { ascending: true })
      .order("ordem", { ascending: true })
      .order("id", { ascending: true });
    if (error) throw error;
    const tasks = mapTaskList(data);
    return {
      pending: tasks.filter((t) => !t.done),
      completed: tasks.filter((t) => t.done),
    };
  }

  async loadView(mode: ViewMode, projectId?: string | null): Promise<ViewTasks> {
    if (mode === "project" && projectId) {
      return this.fetchProjectTasks(projectId);
    }
    switch (mode) {
      case "today": {
        const [pending, completed] = await Promise.all([
          this.fetchTodayTasks(),
          this.fetchCompletedTodayTasks(),
        ]);
        const { overdue, today } = splitTodayPending(pending);
        return { pending, completed, overdue, today };
      }
      case "inbox": {
        const [pending, completed] = await Promise.all([
          this.fetchInboxTasks(),
          this.fetchCompletedInboxTasks(),
        ]);
        return { pending, completed };
      }
      case "upcoming": {
        const pending = await this.fetchDatedPendingTasks();
        return { pending, completed: [] };
      }
      case "done": {
        const completed = await this.fetchLogbook(200);
        return { pending: [], completed };
      }
      case "project":
      case "filters":
      default:
        return { pending: [], completed: [] };
    }
  }

  async fetchFilterDashboardCounts(now = new Date()): Promise<FilterDashboardCounts> {
    const todayStr = this.todayStr(now);
    const weekStr = toDateStr(addDays(startOfDay(now), 7));
    const [overdue, today, week, completedToday] = await Promise.all([
      this.client
        .from("tasks")
        .select("id", { count: "exact", head: true })
        .eq("concluida", false)
        .lt("data_vencimento", todayStr),
      this.client
        .from("tasks")
        .select("id", { count: "exact", head: true })
        .eq("concluida", false)
        .eq("data_vencimento", todayStr),
      this.client
        .from("tasks")
        .select("id", { count: "exact", head: true })
        .eq("concluida", false)
        .gt("data_vencimento", todayStr)
        .lte("data_vencimento", weekStr),
      this.client
        .from("tasks")
        .select("id", { count: "exact", head: true })
        .eq("concluida", true)
        .gte("data_conclusao", completionDayBounds(now).start)
        .lt("data_conclusao", completionDayBounds(now).end),
    ]);
    if (overdue.error) throw overdue.error;
    if (today.error) throw today.error;
    if (week.error) throw week.error;
    if (completedToday.error) throw completedToday.error;
    return {
      overdue: overdue.count ?? 0,
      today: today.count ?? 0,
      week: week.count ?? 0,
      completedToday: completedToday.count ?? 0,
    };
  }

  async fetchFilteredTasks(kind: TaskFilterKind, now = new Date()): Promise<Task[]> {
    const todayStr = this.todayStr(now);
    const weekStr = toDateStr(addDays(startOfDay(now), 7));
    let q = this.client.from("tasks").select(TASK_SELECT);

    switch (kind) {
      case "overdue":
        q = q.eq("concluida", false).lt("data_vencimento", todayStr);
        break;
      case "today":
        q = q.eq("concluida", false).eq("data_vencimento", todayStr);
        break;
      case "week":
        q = q.eq("concluida", false).gt("data_vencimento", todayStr).lte("data_vencimento", weekStr);
        break;
      case "completedToday": {
        const bounds = completionDayBounds(now);
        q = q.eq("concluida", true).gte("data_conclusao", bounds.start).lt("data_conclusao", bounds.end);
        break;
      }
    }

    const { data, error } = await q
      .order("data_vencimento", { ascending: true })
      .order("ordem", { ascending: true })
      .order("id", { ascending: true });
    if (error) throw error;
    return mapTaskList(data);
  }

  async fetchFilterResults(
    criteria: FilterCriteria,
    now = new Date(),
  ): Promise<{ pending: FilterResultItem[]; completed: FilterResultItem[] }> {
    const tasks = await this.fetchTasksForFilterMatching(criteria, now);
    return {
      pending: buildPendingFilterResults(tasks, criteria, now),
      completed: buildCompletedFilterResults(tasks, criteria, now),
    };
  }

  async fetchPresetFilterResults(kind: TaskFilterKind, now = new Date()): Promise<FilterResultItem[]> {
    if (kind === "completedToday") {
      const tasks = await this.fetchFilteredTasks(kind, now);
      return tasks.map((task) => ({ kind: "task", task }));
    }
    if (kind === "overdue" || kind === "today") {
      const pending = await this.fetchTodayTasks();
      const split = splitTodayPending(pending, now);
      const tasks = kind === "overdue" ? split.overdue : split.today;
      const dateScope: FilterCriteria["dateScope"] = kind === "overdue" ? "overdue" : "today";
      const criteria: FilterCriteria = {
        labelIds: [],
        priorities: [],
        projectId: null,
        dateScope,
      };
      return buildPendingFilterResults(tasks, criteria, now);
    }
    const criteria: FilterCriteria = {
      labelIds: [],
      priorities: [],
      projectId: null,
      dateScope: "week",
    };
    const tasks = await this.fetchFilteredTasks(kind, now);
    return buildPendingFilterResults(tasks, criteria, now);
  }

  /** Base fetch — critérios de etiqueta/prioridade/data aplicados em memória (inclui subtarefas). */
  private async fetchTasksForFilterMatching(criteria: FilterCriteria, _now = new Date()) {
    let q = this.client.from("tasks").select(TASK_SELECT);

    if (criteria.projectId) {
      q = q.eq("project_id", criteria.projectId);
    }

    const { data, error } = await q
      .order("data_vencimento", { ascending: true, nullsFirst: false })
      .order("ordem", { ascending: true })
      .order("id", { ascending: true });
    if (error) throw error;
    return mapTaskList(data);
  }

  async fetchTasksMatchingCriteria(
    criteria: FilterCriteria,
    includeCompleted: boolean,
    now = new Date(),
  ): Promise<Task[]> {
    const { pending, completed } = await this.fetchFilterResults(criteria, now);
    const tasks = includeCompleted
      ? [...pending, ...completed]
          .map((item) => (item.kind === "task" ? item.task : null))
          .filter((t): t is Task => Boolean(t))
      : pending
          .map((item) => (item.kind === "task" ? item.task : null))
          .filter((t): t is Task => Boolean(t));
    return tasks;
  }

  async fetchPendingAndCompletedMatchingCriteria(
    criteria: FilterCriteria,
    now = new Date(),
  ): Promise<{ pending: FilterResultItem[]; completed: FilterResultItem[] }> {
    return this.fetchFilterResults(criteria, now);
  }

  computeTodayStats(view: ViewTasks): TodayStats {
    const overdue = view.overdue?.length ?? 0;
    const today = view.today?.length ?? view.pending.length;
    return {
      overdue,
      today,
      completed: view.completed.length,
    };
  }

  async createTask(input: {
    title: string;
    description?: string;
    priority?: Priority;
    projectId?: string | null;
    sectionId?: string | null;
    dueDate?: string | null;
    time?: string | null;
    labelIds?: string[];
  }): Promise<string> {
    const userId = await this.requireUserId();
    const { data, error } = await this.client
      .from("tasks")
      .insert({
        titulo: input.title.trim(),
        descricao: input.description?.trim() || null,
        prioridade: toDbPriority(input.priority),
        project_id: input.projectId ?? null,
        section_id: input.sectionId ?? null,
        data_vencimento: input.dueDate ?? null,
        hora: input.time ?? null,
        concluida: false,
        user_id: userId,
      })
      .select("id")
      .single();
    if (error) throw error;
    const taskId = String(data.id);
    if (input.labelIds?.length) {
      const { error: labelError } = await this.client.from("task_labels").insert(
        input.labelIds.map((labelId) => ({ task_id: taskId, label_id: labelId })),
      );
      if (labelError) throw labelError;
    }
    return taskId;
  }

  async deleteTask(id: string): Promise<void> {
    const { error } = await this.client.from("tasks").delete().eq("id", id);
    if (error) throw error;
  }

  async deferTask(taskId: string, currentDueDate?: string | null): Promise<void> {
    const today = startOfDay(new Date());
    let next: Date;
    if (!currentDueDate) {
      next = addDays(today, 1);
    } else {
      const due = parseDueDate(currentDueDate);
      next = !due || due.getTime() <= today.getTime() ? addDays(today, 1) : addDays(due, 1);
    }
    await this.updateTaskMeta(taskId, { dueDate: toDateStr(next) });
  }

  async duplicateTask(taskId: string): Promise<string> {
    const { data: row, error } = await this.client
      .from("tasks")
      .select(TASK_SELECT)
      .eq("id", taskId)
      .single();
    if (error) throw error;

    const task = mapTaskRow(row as Record<string, unknown>);
    const userId = await this.requireUserId();
    const { data: inserted, error: insertError } = await this.client
      .from("tasks")
      .insert({
        titulo: `${task.title} (cópia)`,
        descricao: task.notes ?? null,
        prioridade: toDbPriority(task.priority),
        hora: task.time ?? null,
        data_vencimento: task.dueDate ?? null,
        project_id: task.projectId ?? null,
        section_id: task.sectionId ?? null,
        concluida: false,
        user_id: userId,
      })
      .select("id")
      .single();
    if (insertError) throw insertError;

    const newId = String(inserted.id);
    const labelRows = ((row as Record<string, unknown>).task_labels as Record<string, unknown>[] | null) ?? [];
    const labelIds = labelRows
      .map((entry) => {
        const label = entry.labels as Record<string, unknown> | null;
        return label?.id != null ? String(label.id) : null;
      })
      .filter((id): id is string => Boolean(id));

    if (labelIds.length > 0) {
      const { error: labelError } = await this.client.from("task_labels").insert(
        labelIds.map((labelId) => ({ task_id: newId, label_id: labelId })),
      );
      if (labelError) throw labelError;
    }

    return newId;
  }

  async updateTaskMeta(
    taskId: string,
    meta: {
      priority?: Priority | null;
      dueDate?: string | null;
      projectId?: string | null;
      sectionId?: string | null;
      order?: number;
    },
  ): Promise<void> {
    const patch: Record<string, unknown> = {};
    if ("priority" in meta) patch.prioridade = toDbPriority(meta.priority);
    if ("dueDate" in meta) patch.data_vencimento = meta.dueDate ?? null;
    if ("projectId" in meta) patch.project_id = meta.projectId ?? null;
    if ("sectionId" in meta) patch.section_id = meta.sectionId ?? null;
    if ("order" in meta && meta.order != null) patch.ordem = meta.order;
    if (Object.keys(patch).length === 0) return;
    const { error } = await this.client.from("tasks").update(patch).eq("id", taskId);
    if (error) throw error;
  }

  async updateTaskOrders(items: { id: string; order: number }[]): Promise<void> {
    if (!items.length) return;
    const results = await Promise.all(
      items.map(({ id, order }) =>
        this.client.from("tasks").update({ ordem: order }).eq("id", id),
      ),
    );
    const failed = results.find((r) => r.error);
    if (failed?.error) throw failed.error;
  }

  async fetchLogbook(limit = 200): Promise<Task[]> {
    const { data, error } = await this.client
      .from("tasks")
      .select(TASK_SELECT)
      .eq("concluida", true)
      .order("data_vencimento", { ascending: false, nullsFirst: false })
      .order("ordem", { ascending: false })
      .limit(limit);
    if (error) throw error;
    return mapTaskList(data);
  }

  async createSubtasksBatch(
    rows: {
      task_id: string;
      titulo: string;
      data_vencimento: string;
      hora?: string | null;
      valor?: number;
      concluida: boolean;
      ordem: number;
    }[],
  ): Promise<void> {
    if (!rows.length) return;
    const { error } = await this.client.from("subtasks").insert(rows);
    if (error) throw error;
  }

  async createSubtask(taskId: string, title: string): Promise<string> {
    const trimmed = title.trim();
    if (!trimmed) throw new Error("Subtask title is required");

    const { data: existing, error: orderError } = await this.client
      .from("subtasks")
      .select("ordem")
      .eq("task_id", taskId)
      .order("ordem", { ascending: false })
      .limit(1);
    if (orderError) throw orderError;

    const ordem =
      existing?.[0]?.ordem != null ? Number(existing[0].ordem) + 1 : 0;

    const { data, error } = await this.client
      .from("subtasks")
      .insert({
        task_id: taskId,
        titulo: trimmed,
        concluida: false,
        ordem,
      })
      .select("id")
      .single();
    if (error) throw error;
    return String(data.id);
  }

  async deleteSubtask(subtaskId: string): Promise<void> {
    const { error } = await this.client.from("subtasks").delete().eq("id", subtaskId);
    if (error) throw error;
  }

  async fetchNavCounts(): Promise<{ inbox: number; today: number }> {
    const todayStr = this.todayStr();
    const [inboxRes, todayRes] = await Promise.all([
      this.client
        .from("tasks")
        .select("id", { count: "exact", head: true })
        .eq("concluida", false)
        .is("data_vencimento", null)
        .is("project_id", null),
      this.client
        .from("tasks")
        .select("id", { count: "exact", head: true })
        .eq("concluida", false)
        .lte("data_vencimento", todayStr),
    ]);
    if (inboxRes.error) throw inboxRes.error;
    if (todayRes.error) throw todayRes.error;
    return {
      inbox: inboxRes.count ?? 0,
      today: todayRes.count ?? 0,
    };
  }
}
