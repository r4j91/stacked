import type { Task } from "@/lib/types/task";
import type { CalendarEvent } from "@/lib/types/calendar-event";
import { dateKey, parseDueDate, startOfDay } from "@/lib/utils/date";

export type ScheduleItem =
  | { kind: "task"; task: Task; sortTime: number }
  | { kind: "calendar"; event: CalendarEvent; sortTime: number };

function taskSortTime(task: Task, fallback: number): number {
  if (task.dueDate) {
    const due = parseDueDate(task.dueDate);
    if (due) return due.getTime();
  }
  return fallback;
}

/** Paridade iOS TaskMapper.todayTimeline */
export function buildTodayTimeline(tasks: Task[], events: CalendarEvent[], now = new Date()): ScheduleItem[] {
  const todayKey = dateKey(startOfDay(now));
  const fallback = startOfDay(now).getTime() + 12 * 3600_000;

  const taskItems: ScheduleItem[] = tasks
    .filter((task) => {
      if (!task.dueDate) return true;
      const due = parseDueDate(task.dueDate);
      return due ? dateKey(due) === todayKey : false;
    })
    .map((task) => ({
      kind: "task" as const,
      task,
      sortTime: taskSortTime(task, fallback),
    }));

  const eventItems: ScheduleItem[] = events.map((event) => ({
    kind: "calendar" as const,
    event,
    sortTime: event.isAllDay
      ? startOfDay(new Date(event.startDate)).getTime()
      : new Date(event.startDate).getTime(),
  }));

  return [...taskItems, ...eventItems].sort((a, b) => a.sortTime - b.sortTime);
}

export function groupEventsByDay(events: CalendarEvent[]): Map<string, CalendarEvent[]> {
  const map = new Map<string, CalendarEvent[]>();
  for (const event of events) {
    const key = dateKey(startOfDay(new Date(event.startDate)));
    const list = map.get(key) ?? [];
    list.push(event);
    map.set(key, list);
  }
  return map;
}

export function mergeScheduleByDay(
  tasks: Task[],
  events: CalendarEvent[],
): Map<string, ScheduleItem[]> {
  const grouped = new Map<string, ScheduleItem[]>();

  for (const task of tasks) {
    const due = parseDueDate(task.dueDate);
    if (!due) continue;
    const key = dateKey(due);
    const list = grouped.get(key) ?? [];
    list.push({ kind: "task", task, sortTime: due.getTime() });
    grouped.set(key, list);
  }

  for (const event of events) {
    const key = dateKey(startOfDay(new Date(event.startDate)));
    const list = grouped.get(key) ?? [];
    list.push({
      kind: "calendar",
      event,
      sortTime: event.isAllDay
        ? startOfDay(new Date(event.startDate)).getTime()
        : new Date(event.startDate).getTime(),
    });
    grouped.set(key, list);
  }

  for (const [key, list] of grouped) {
    grouped.set(
      key,
      list.sort((a, b) => a.sortTime - b.sortTime),
    );
  }

  return grouped;
}

export function formatEventTime(event: CalendarEvent): string | null {
  if (event.isAllDay) return null;
  const d = new Date(event.startDate);
  const h = d.getHours();
  const m = d.getMinutes();
  return `${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}`;
}
