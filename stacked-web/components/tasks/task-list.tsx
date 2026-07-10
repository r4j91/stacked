"use client";

import { useMemo } from "react";
import { useRouter } from "next/navigation";
import type { Subtask, Task } from "@/lib/types/task";
import { useWorkbench, type SubtaskKey } from "@/components/shell/workbench-context";
import { SwipeableTaskRow } from "@/components/tasks/swipeable-task-row";
import { useTaskContextMenu } from "@/components/tasks/task-context-menu";
import { parseDueDate, dateKey, startOfDay } from "@/lib/utils/date";
import { EmptyState } from "@/components/ui/empty-state";
import { CalendarEventRow } from "@/components/calendar/calendar-event-row";
import { buildTodayTimeline } from "@/lib/utils/schedule-items";
import { AppIcon } from "@/components/ui/app-icon";
import { DoneCircle } from "@/components/ui/done-circle";
import { TaskMetaLine, SubtaskMetaLine } from "@/components/tasks/task-meta-line";
import { TaskRowTime } from "@/components/tasks/task-time-chip";
import { WhatsAppTaskCopyButton } from "@/components/tasks/whatsapp-task-copy-button";
import { taskShowsWhatsAppCopy } from "@/lib/utils/whatsapp-routine-message";
import { useTaskListKeyboard } from "@/lib/hooks/use-task-list-keyboard";
import { ListSectionHeader } from "@/components/tasks/list-section-header";
import { ReorderDragHandle } from "@/components/tasks/reorder-drag-handle";
import {
  Sun01Icon,
  InboxIcon,
  TaskDone01Icon,
  Calendar03Icon,
  ArrowDown01Icon,
} from "@/lib/icons/nav-icons";

export function InlineSubtasks({ task, open }: { task: Task; open: boolean }) {
  const { selectedSubtaskKey, selectSubtask, toggleSubtaskDone } = useWorkbench();
  if (!open || !task.subtasks?.length) return null;

  const subs = task.subtasks;

  return (
    <div className="subtask-tree relative mr-2 mt-0.5 space-y-0.5 pb-1.5">
      <div
        className="subtask-tree-line pointer-events-none absolute top-0 w-px bg-gradient-to-b from-[var(--color-border)] via-[var(--color-border)]/60 to-transparent"
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
                priority={s.priority}
                label={`${s.done ? "Marcar pendente" : "Marcar concluída"}: ${s.name}`}
                onClick={(e) => {
                  e.stopPropagation();
                  toggleSubtaskDone(key);
                }}
              />
              <div className="min-w-0 flex-1">
                <div className="flex items-start gap-2">
                  <span className={`block min-w-0 flex-1 truncate text-[13px] font-medium ${s.done ? "text-[var(--color-text-tertiary)] line-through" : "text-[var(--color-text-secondary)]"}`}>
                    {s.name}
                  </span>
                  <TaskRowTime time={s.time} className="mt-0.5" />
                </div>
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
  embedded,
  reorderDropProps,
  reorderHoldProps,
  reorderHandleProps,
  reorderDragOver,
  reorderDropPosition,
  reorderDragging,
  onReorderConsumeClick,
}: {
  task: Task;
  keyboardFocused?: boolean;
  /** Lista embutida (ex.: drill-down de filtros) — sem borda de seleção do inspector */
  embedded?: boolean;
  reorderDropProps?: Record<string, unknown>;
  reorderHoldProps?: Record<string, unknown>;
  reorderHandleProps?: Record<string, unknown>;
  reorderDragOver?: boolean;
  reorderDropPosition?: "before" | "after" | null;
  reorderDragging?: boolean;
  onReorderConsumeClick?: () => boolean;
}) {
  const { selectedTaskId, selectTask, openTaskInspector, toggleTaskDone, deferTask, deleteTask, expandedSubtasks, toggleSubtaskExpand } =
    useWorkbench();
  const { menu, onContextMenu, onTouchStart, onTouchMove, onTouchEnd } = useTaskContextMenu();
  const subs = task.subtasks ?? [];
  const isExpanded = expandedSubtasks.has(task.id);
  const isSelected = !embedded && selectedTaskId === task.id;
  const isKeyboardFocused = !embedded && keyboardFocused;
  const showsWhatsApp = taskShowsWhatsAppCopy(task);
  const reserveRight = (subs.length > 0 ? 40 : 0) + (showsWhatsApp ? 40 : 0);

  return (
    <>
      <SwipeableTaskRow
        onComplete={() => toggleTaskDone(task.id)}
        onDefer={() => void deferTask(task.id)}
        onDelete={() => void deleteTask(task.id)}
        allowOverflow={false}
        dragGhost={Boolean(reorderDragging)}
        reserveRight={reserveRight}
      >
        <div
          role="button"
          tabIndex={0}
          data-reorder-item
          {...(reorderDropProps ?? {})}
          {...(reorderHoldProps ?? {})}
          onClick={() => {
            if (onReorderConsumeClick?.()) return;
            if (embedded) openTaskInspector(task);
            else selectTask(task.id);
          }}
          onContextMenu={(e) => onContextMenu(task, e)}
          onTouchStart={(e) => onTouchStart(task, e)}
          onTouchMove={onTouchMove}
          onTouchEnd={onTouchEnd}
          onTouchCancel={onTouchEnd}
          onKeyDown={(e) => {
            if (e.key === "Enter" || e.key === " ") {
              e.preventDefault();
              if (embedded) openTaskInspector(task);
              else selectTask(task.id);
            }
          }}
          className={`group/reorder-row task-row scroll-list-item mb-0.5 min-h-[52px] cursor-pointer rounded-[var(--radius-md)] border py-2 pl-1 pr-0.5 ${
            reorderHandleProps
              ? "reorder-row-with-gutter grid items-start gap-x-2"
              : "flex items-start gap-2"
          } ${
            reorderDragOver
              ? reorderDropPosition === "after"
                ? "reorder-drop-target reorder-drop-target-after border-transparent"
                : "reorder-drop-target border-transparent"
              : isSelected
                ? "border-[var(--color-border-strong)] bg-[var(--color-hover-overlay)]"
                : isKeyboardFocused
                  ? "border-[var(--color-border-strong)] bg-[var(--color-hover-overlay)]/80"
                  : "border-transparent"
          } ${task.done ? "opacity-65" : ""}`}
          data-task-id={task.id}
          data-selected={isSelected ? "" : undefined}
        >
          {reorderHandleProps ? (
            <div className="reorder-gutter flex items-center justify-center self-center">
              <ReorderDragHandle dragProps={reorderHandleProps} label={`Reordenar ${task.title}`} />
            </div>
          ) : null}
          <DoneCircle
            done={task.done}
            priority={task.priority}
            label={task.done ? "Marcar pendente" : "Marcar concluída"}
            onClick={(e) => {
              e.stopPropagation();
              toggleTaskDone(task.id);
            }}
          />
          <div className="min-w-0 flex-1">
            <div className="flex items-start gap-2">
              <p className={`min-w-0 flex-1 truncate text-[15.5px] font-semibold leading-snug ${task.done ? "text-[var(--color-text-tertiary)] line-through" : ""}`}>
                {task.title}
              </p>
              <TaskRowTime time={task.time} className="mt-1" />
            </div>
            {task.preview && (
              <p className={`mt-0.5 truncate text-[12.5px] text-[var(--color-text-secondary)] ${task.done ? "opacity-60 line-through" : ""}`}>
                {task.preview}
              </p>
            )}
            <TaskMetaLine task={task} />
          </div>
          <div className="mt-0.5 flex shrink-0 items-start">
            <WhatsAppTaskCopyButton task={task} />
            {subs.length > 0 ? (
              <button
                type="button"
                onClick={(e) => {
                  e.stopPropagation();
                  toggleSubtaskExpand(task.id);
                }}
                className="flex h-8 w-8 shrink-0 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-tertiary)] hover:bg-[var(--color-hover-overlay)] hover:text-[var(--color-text-secondary)]"
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
      <ListSectionHeader title={title} count={count} overdue={overdue} />
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
                <ListSectionHeader title="Hoje" />
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
