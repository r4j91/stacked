import type { Task, ViewMode, ViewTasks } from "@/lib/types/task";
import { splitTodayPending } from "@/lib/supabase/map-task";

/** Move tarefa entre buckets pending/overdue/today/completed após toggle de conclusão. */
export function reclassifyTaskDoneInView(
  prev: ViewTasks,
  task: Task,
  done: boolean,
  view: ViewMode,
): ViewTasks {
  const updated = { ...task, done };
  const without = (list: Task[]) => list.filter((t) => t.id !== task.id);
  const base: ViewTasks = {
    pending: without(prev.pending),
    completed: without(prev.completed),
    overdue: prev.overdue ? without(prev.overdue) : undefined,
    today: prev.today ? without(prev.today) : undefined,
  };

  if (done) {
    return { ...base, completed: [updated, ...base.completed] };
  }

  if (view === "today") {
    const activePending = [...base.pending, updated];
    const { overdue, today } = splitTodayPending(activePending);
    return { ...base, pending: activePending, overdue, today };
  }

  return { ...base, pending: [...base.pending, updated] };
}
