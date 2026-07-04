"use client";

import { useMemo } from "react";
import { useRouter } from "next/navigation";
import type { Subtask, Task } from "@/lib/types/task";
import { useWorkbench, type SubtaskKey } from "@/components/shell/workbench-context";
import { SwipeableTaskRow } from "@/components/tasks/swipeable-task-row";
import { useTaskContextMenu } from "@/components/tasks/task-context-menu";
import { isOverdueDate, parseDueDate, dateKey, startOfDay } from "@/lib/utils/date";
import { priorityColor } from "@/lib/utils/priority";
import { EmptyState } from "@/components/ui/empty-state";
import { CalendarEventRow } from "@/components/calendar/calendar-event-row";
import { buildTodayTimeline } from "@/lib/utils/schedule-items";
import { AppIcon } from "@/components/ui/app-icon";
import { DoneCircle } from "@/components/ui/done-circle";
import { TagChip } from "@/components/ui/tag-chip";
import { useTaskListKeyboard } from "@/lib/hooks/use-task-list-keyboard";
import {
  Sun01Icon,
  InboxIcon,
  TaskDone01Icon,
  Calendar03Icon,
  Flag01Icon,
  ArrowDown01Icon,
} from "@/lib/icons/nav-icons";

function TaskMetaLine({ task }: { task: Task }) {
  const { labels: allLabels } = useWorkbench();
  const subs = task.subtasks ?? [];
  const due = parseDueDate(task.dueDate);

  let taskLabels =
    task.labels ??
    (task.labelIds ?? [])
      .map((id) => allLabels.find((l) => l.id === id))
      .filter((l): l is NonNullable<typeof l> => Boolean(l));

  if (!taskLabels.length && task.tag) {
    const matched = allLabels.find((l) => l.name === task.tag);
    if (matched) taskLabels = [matched];
  }

  const items: React.ReactNode[] = [];

  for (const label of taskLabels.slice(0, 3)) {
    items.push(<TagChip key={label.id} label={label.name} color={label.color} />);
  }
  if (taskLabels.length > 3) {
    items.push(
      <TagChip key="more" label={`+${taskLabels.length - 3}`} color="var(--color-text-tertiary)" showIcon={false} />,
    );
  }

  if (task.date) {
    const overdue = isOverdueDate(due, task.done);
    items.push(
      <TagChip
        key="d"
        label={task.date}
        color={overdue ? "var(--color-overdue)" : "var(--color-text-tertiary)"}
        icon={Calendar03Icon}
      />,
    );
  }

  if (task.priority) {
    items.push(
      <span key="pri" className="inline-flex items-center gap-1 text-[12px]" style={{ color: priorityColor(task.priority) }}>
        <AppIcon icon={Flag01Icon} size={11} strokeWidth={1.75} />
        <span>{task.priority}</span>
      </span>,
    );
  }

  if (subs.length) {
    const doneSubs = subs.filter((s) => s.done).length;
    items.push(
      <span key="sub" className="inline-flex items-center gap-1 text-[12px] text-[var(--color-text-tertiary)]">
        <AppIcon icon={TaskDone01Icon} size={12} strokeWidth={1.75} />
        <span className="tabular-nums">
          {doneSubs}/{subs.length}
        </span>
      </span>,
    );
  }

  if (!items.length) return task.done ? <span className="text-xs text-[var(--color-text-tertiary)]">—</span> : null;

  return (
    <div className="mt-1.5 flex flex-wrap items-center gap-1.5">
      {items}
    </div>
  );
}

function SubtaskMetaLine({ sub }: { sub: Subtask }) {
  const { labels: allLabels } = useWorkbench();

  let subLabels =
    (sub.labelIds ?? [])
      .map((id) => allLabels.find((l) => l.id === id))
      .filter((l): l is NonNullable<typeof l> => Boolean(l));

  if (!subLabels.length && sub.tag) {
    const matched = allLabels.find((l) => l.name === sub.tag);
    if (matched) subLabels = [matched];
  }

  const items: React.ReactNode[] = [];

  for (const label of subLabels.slice(0, 2)) {
    items.push(<TagChip key={label.id} label={label.name} color={label.color} />);
  }
  if (subLabels.length > 2) {
    items.push(
      <TagChip key="more" label={`+${subLabels.length - 2}`} color="var(--color-text-tertiary)" showIcon={false} />,
    );
  }

  if (sub.date) {
    const overdue = isOverdueDate(parseDueDate(sub.dueDate), sub.done);
    items.push(
      <TagChip
        key="d"
        label={sub.date}
        color={overdue ? "var(--color-overdue)" : "var(--color-text-tertiary)"}
        icon={Calendar03Icon}
      />,
    );
  }

  if (sub.priority) {
    items.push(
      <span key="pri" className="inline-flex items-center gap-1 text-[11px]" style={{ color: priorityColor(sub.priority) }}>
        <AppIcon icon={Flag01Icon} size={10} strokeWidth={1.75} />
        <span>{sub.priority}</span>
      </span>,
    );
  }

  if (!items.length) return null;

  return <div className="mt-0.5 flex flex-wrap items-center gap-1">{items}</div>;
}

function InlineSubtasks({ task, open }: { task: Task; open: boolean }) {
  const { selectedSubtaskKey, selectSubtask, toggleSubtaskDone } = useWorkbench();
  if (!open || !task.subtasks?.length) return null;

  const subs = task.subtasks;

  return (
    <div className="relative ml-[22px] mr-2 mt-0.5 space-y-0.5 pb-1.5">
      <div
        className="pointer-events-none absolute left-[9px] top-0 w-px bg-gradient-to-b from-[var(--color-border)] via-[var(--color-border)]/60 to-transparent"
        style={{ height: `calc(100% - 10px)` }}
        aria-hidden
      />
      {subs.map((s, i) => {
        const key = `${task.id}:${i}` as SubtaskKey;
        const selected = selectedSubtaskKey === key;
        const isLast = i === subs.length - 1;
        return (
          <div key={key} className="relative pl-5">
            <div
              className="pointer-events-none absolute left-0 top-[17px] h-px w-4 rounded-full bg-[var(--color-border)]/90"
              aria-hidden
            />
            {!isLast && (
              <div
                className="pointer-events-none absolute left-0 top-[17px] w-px bg-[var(--color-border)]/70"
                style={{ height: "calc(100% + 2px)" }}
                aria-hidden
              />
            )}
            <div
              role="button"
              tabIndex={0}
              onClick={() => selectSubtask(task.id, i)}
              onKeyDown={(e) => {
                if (e.key === "Enter" || e.key === " ") {
                  e.preventDefault();
                  selectSubtask(task.id, i);
                }
              }}
              className={`flex min-h-9 cursor-pointer items-start gap-2.5 rounded-[var(--radius-sm)] px-2 py-1 transition-colors ${
                selected ? "bg-[var(--color-hover-overlay)]" : "hover:bg-[var(--color-hover-overlay)]/70"
              }`}
            >
              <DoneCircle
                small
                done={s.done}
                label={`${s.done ? "Marcar pendente" : "Marcar concluída"}: ${s.name}`}
                onClick={(e) => {
                  e.stopPropagation();
                  toggleSubtaskDone(key);
                }}
              />
              <div className="min-w-0 flex-1">
                <span className={`block truncate text-[13px] font-medium ${s.done ? "text-[var(--color-text-tertiary)] line-through" : "text-[var(--color-text-secondary)]"}`}>
                  {s.name}
                </span>
                <SubtaskMetaLine sub={s} />
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}

export function TaskRow({
  task,
  keyboardFocused,
  reorderRowProps,
  reorderHolding,
  reorderDragOver,
  reorderDragging,
  onReorderConsumeClick,
}: {
  task: Task;
  keyboardFocused?: boolean;
  reorderRowProps?: Record<string, unknown>;
  reorderHolding?: boolean;
  reorderDragOver?: boolean;
  reorderDragging?: boolean;
  onReorderConsumeClick?: () => boolean;
}) {
  const { selectedTaskId, selectTask, toggleTaskDone, deferTask, deleteTask, expandedSubtasks, toggleSubtaskExpand } =
    useWorkbench();
  const { menu, onContextMenu, onTouchStart, onTouchMove, onTouchEnd } = useTaskContextMenu();
  const subs = task.subtasks ?? [];
  const isExpanded = expandedSubtasks.has(task.id);

  return (
    <>
      <SwipeableTaskRow
        onComplete={() => toggleTaskDone(task.id)}
        onDefer={() => void deferTask(task.id)}
        onDelete={() => void deleteTask(task.id)}
        allowOverflow={Boolean(reorderDragging || reorderHolding)}
        dragGhost={Boolean(reorderDragging)}
        reserveRight={subs.length > 0 ? 40 : 0}
      >
        <div
          role="button"
          tabIndex={0}
          {...(reorderRowProps ?? {})}
          onClick={() => {
            if (onReorderConsumeClick?.()) return;
            selectTask(task.id);
          }}
          onContextMenu={(e) => onContextMenu(task, e)}
          onTouchStart={(e) => onTouchStart(task, e)}
          onTouchMove={onTouchMove}
          onTouchEnd={onTouchEnd}
          onTouchCancel={onTouchEnd}
          onKeyDown={(e) => {
            if (e.key === "Enter" || e.key === " ") {
              e.preventDefault();
              selectTask(task.id);
            }
          }}
          className={`mb-0.5 flex min-h-[52px] cursor-pointer items-start gap-2 rounded-[var(--radius-md)] border py-2 pl-1 pr-0.5 transition-colors ${
            reorderDragging
              ? "reorder-dragging"
              : reorderHolding
                ? "reorder-holding"
                : reorderDragOver
                  ? "reorder-drop-target border-[var(--color-border-strong)]"
                  : selectedTaskId === task.id
                    ? "border-[var(--color-border-strong)] bg-[var(--color-hover-overlay)]"
                    : keyboardFocused
                      ? "border-[var(--color-border-strong)] bg-[var(--color-hover-overlay)]/80"
                      : "border-transparent hover:bg-[var(--color-hover-overlay)]"
          } ${task.done && !reorderDragging && !reorderHolding ? "opacity-65" : ""}`}
          data-task-id={task.id}
        >
          <DoneCircle
            done={task.done}
            label={task.done ? "Marcar pendente" : "Marcar concluída"}
            onClick={(e) => {
              e.stopPropagation();
              toggleTaskDone(task.id);
            }}
          />
          <div className="min-w-0 flex-1">
            <p className={`truncate text-[15.5px] font-semibold leading-snug ${task.done ? "text-[var(--color-text-tertiary)] line-through" : ""}`}>
              {task.title}
            </p>
            {task.preview && (
              <p className={`mt-0.5 truncate text-[12.5px] text-[var(--color-text-secondary)] ${task.done ? "opacity-60 line-through" : ""}`}>
                {task.preview}
              </p>
            )}
            <TaskMetaLine task={task} />
          </div>
          {subs.length > 0 ? (
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation();
                toggleSubtaskExpand(task.id);
              }}
              className="mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-tertiary)] hover:bg-[var(--color-hover-overlay)] hover:text-[var(--color-text-secondary)]"
              aria-expanded={isExpanded}
              aria-label={isExpanded ? "Recolher subtarefas" : "Expandir subtarefas"}
            >
              <AppIcon
                icon={ArrowDown01Icon}
                size={18}
                className={`transition-transform duration-200 ${isExpanded ? "rotate-180" : ""}`}
              />
            </button>
          ) : null}
        </div>
      </SwipeableTaskRow>
      {subs.length > 0 && (
        <div className="expand-panel" data-open={isExpanded ? "true" : "false"}>
          <div>
            <InlineSubtasks task={task} open={isExpanded} />
          </div>
        </div>
      )}
      {menu}
    </>
  );
}

function Section({
  title,
  count,
  overdue,
  tasks,
  focusedTaskId,
}: {
  title: string;
  count?: number;
  overdue?: boolean;
  tasks: Task[];
  focusedTaskId?: string | null;
}) {
  if (!tasks.length) return null;
  return (
    <section className="mt-2">
      <div className="flex items-center gap-2 px-2 pb-2 pt-4">
        <h2 className={`text-[13px] font-semibold ${overdue ? "text-[var(--color-overdue)]" : "text-[var(--color-text-secondary)]"}`}>
          {title}
        </h2>
        {count != null && (
          <span className="rounded-full bg-[var(--color-overdue)]/15 px-1.5 py-0.5 text-[11px] font-semibold tabular-nums text-[var(--color-overdue)]">
            {count}
          </span>
        )}
      </div>
      {tasks.map((t) => (
        <TaskRow key={t.id} task={t} keyboardFocused={focusedTaskId === t.id} />
      ))}
    </section>
  );
}

export function TaskListSkeleton() {
  return (
    <div className="mt-4 space-y-3 px-2">
      {[1, 2, 3, 4, 5].map((i) => (
        <div key={i} className="flex gap-3 py-2">
          <div className="h-5 w-5 shrink-0 animate-pulse rounded-full bg-[var(--color-surface-variant)]" />
          <div className="flex-1 space-y-2">
            <div className="h-4 w-2/3 animate-pulse rounded bg-[var(--color-surface-variant)]" />
            <div className="h-3 w-1/2 animate-pulse rounded bg-[var(--color-surface)]" />
          </div>
        </div>
      ))}
    </div>
  );
}

export function TaskList() {
  const router = useRouter();
  const {
    view,
    viewTasks,
    loading,
    error,
    refreshTasks,
    usingMock,
    isShowCompleted,
    openQuickAdd,
    calendarEvents,
    calendarError,
    googleCalendar,
  } = useWorkbench();

  const showCompleted = isShowCompleted();
  const completedTasks = showCompleted ? viewTasks.completed : [];
  const todayTimeline = useMemo(
    () => buildTodayTimeline(viewTasks.today ?? viewTasks.pending, calendarEvents),
    [viewTasks.today, viewTasks.pending, calendarEvents],
  );

  const visibleTaskIds = useMemo(() => {
    if (view === "today") {
      return [
        ...(viewTasks.overdue ?? []),
        ...(viewTasks.today ?? viewTasks.pending),
        ...(showCompleted ? completedTasks : []),
      ].map((t) => t.id);
    }
    if (view === "inbox") {
      return [...viewTasks.pending, ...(showCompleted ? completedTasks : [])].map((t) => t.id);
    }
    if (view === "done") {
      return viewTasks.completed.map((t) => t.id);
    }
    return [];
  }, [view, viewTasks, showCompleted, completedTasks]);

  const { focusedTaskId } = useTaskListKeyboard(visibleTaskIds, view);

  if (loading) return <TaskListSkeleton />;

  function logbookGroups(tasks: Task[]) {
    const today = dateKey(startOfDay(new Date()));
    const yesterday = dateKey(startOfDay(new Date(Date.now() - 86400000)));
    const groups: { title: string; tasks: Task[] }[] = [];
    const buckets = new Map<string, Task[]>();

    for (const t of tasks) {
      const key = t.dueDate ? dateKey(startOfDay(new Date(`${t.dueDate}T12:00:00`))) : "sem-data";
      if (!buckets.has(key)) buckets.set(key, []);
      buckets.get(key)!.push(t);
    }

    for (const [key, list] of buckets) {
      let title = key;
      if (key === today) title = "Hoje";
      else if (key === yesterday) title = "Ontem";
      else if (key !== "sem-data") {
        const d = new Date(`${key}T12:00:00`);
        title = d.toLocaleDateString("pt-BR", { day: "numeric", month: "long" });
      } else title = "Sem data";
      groups.push({ title, tasks: list });
    }
    return groups;
  }

  return (
    <>
      {calendarError && view === "today" && (
        <div className="mx-2 mt-3 rounded-[var(--radius-md)] border border-[var(--color-overdue)]/30 bg-[var(--color-overdue)]/10 px-3 py-2 text-sm text-[var(--color-overdue)]">
          {calendarError}
        </div>
      )}

      {googleCalendar.configured && !googleCalendar.connected && view === "today" && !loading && (
        <p className="mx-2 mt-3 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] px-3 py-2 text-xs text-[var(--color-text-secondary)]">
          Conecte o Google Calendar em Configurações → Calendário para ver compromissos aqui.
        </p>
      )}

      {error && (
        <div className="mx-2 mt-3 rounded-[var(--radius-md)] border border-[var(--color-overdue)]/30 bg-[var(--color-overdue)]/10 px-3 py-2 text-sm text-[var(--color-overdue)]">
          {error}
          {usingMock && <span className="text-[var(--color-text-secondary)]"> — exibindo dados de exemplo.</span>}
          <button type="button" onClick={() => refreshTasks()} className="ml-2 underline">
            Tentar de novo
          </button>
        </div>
      )}

      {view === "today" && (
        <>
          <Section title="Atrasadas" count={viewTasks.overdue?.length} overdue tasks={viewTasks.overdue ?? []} focusedTaskId={focusedTaskId} />
          {(todayTimeline.length > 0 || (viewTasks.today ?? viewTasks.pending).length > 0) && (
            <section>
              {(viewTasks.overdue?.length ?? 0) > 0 && (
                <div className="flex items-center gap-2 px-2 pb-2 pt-4">
                  <h2 className="text-[13px] font-semibold text-[var(--color-text-secondary)]">Hoje</h2>
                </div>
              )}
              {todayTimeline.map((item) =>
                item.kind === "calendar" ? (
                  <CalendarEventRow key={item.event.id} event={item.event} />
                ) : (
                  <TaskRow key={item.task.id} task={item.task} keyboardFocused={focusedTaskId === item.task.id} />
                ),
              )}
            </section>
          )}
          {showCompleted && completedTasks.length > 0 && (
            <Section title="Concluídas hoje" tasks={completedTasks} focusedTaskId={focusedTaskId} />
          )}
        </>
      )}

      {view === "inbox" && (
        <>
          <Section title="Inbox" tasks={viewTasks.pending} focusedTaskId={focusedTaskId} />
          {showCompleted && completedTasks.length > 0 && (
            <Section title="Concluídas" tasks={completedTasks} focusedTaskId={focusedTaskId} />
          )}
        </>
      )}

      {view === "upcoming" && null}

      {view === "done" &&
        (viewTasks.completed.length ? (
          logbookGroups(viewTasks.completed).map((g) => (
            <Section key={g.title} title={g.title} tasks={g.tasks} focusedTaskId={focusedTaskId} />
          ))
        ) : (
          <EmptyState
            icon={TaskDone01Icon}
            title="Nenhuma tarefa concluída"
            subtitle="Conclua tarefas em Hoje ou Inbox para vê-las aqui."
            action={{ label: "Ir para Hoje", onClick: () => router.push("/today") }}
          />
        ))}

      {!loading &&
        view === "today" &&
        !viewTasks.overdue?.length &&
        !todayTimeline.length &&
        !completedTasks.length && (
          <EmptyState
            icon={Sun01Icon}
            title="Nada para hoje"
            subtitle="Adicione uma tarefa ou planeje algo para os próximos dias."
            action={{ label: "Nova tarefa", onClick: () => openQuickAdd() }}
          />
        )}

      {!loading && view === "inbox" && !viewTasks.pending.length && !completedTasks.length && (
        <EmptyState
          icon={InboxIcon}
          title="Inbox vazia"
          subtitle="Capture ideias e tarefas sem data ou projeto."
          action={{ label: "Adicionar tarefa", onClick: () => openQuickAdd() }}
        />
      )}
    </>
  );
}
