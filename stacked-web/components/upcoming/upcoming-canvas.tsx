"use client";

import { useMemo, useState } from "react";
import { TaskRow, TaskListSkeleton } from "@/components/tasks/task-list";
import { useWorkbench } from "@/components/shell/workbench-context";
import type { Task } from "@/lib/types/task";
import {
  dateKey,
  formatDayLabel,
  monthLabel,
  parseDateKey,
  parseDueDate,
  startOfDay,
} from "@/lib/utils/date";

type CalMode = "month" | "week" | "agenda";

function groupByDay(tasks: Task[]): Map<string, Task[]> {
  const map = new Map<string, Task[]>();
  for (const t of tasks) {
    const due = parseDueDate(t.dueDate);
    if (!due) continue;
    const key = dateKey(due);
    const list = map.get(key) ?? [];
    list.push(t);
    map.set(key, list);
  }
  return map;
}

function MonthGrid({
  focused,
  tasksByDay,
  selectedKey,
  onSelectDay,
  onPrev,
  onNext,
}: {
  focused: Date;
  tasksByDay: Map<string, Task[]>;
  selectedKey: string | null;
  onSelectDay: (key: string | null) => void;
  onPrev: () => void;
  onNext: () => void;
}) {
  const year = focused.getFullYear();
  const month = focused.getMonth();
  const first = new Date(year, month, 1);
  const startPad = first.getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const todayKey = dateKey(new Date());

  const cells: (Date | null)[] = [];
  for (let i = 0; i < startPad; i++) cells.push(null);
  for (let d = 1; d <= daysInMonth; d++) cells.push(new Date(year, month, d));

  return (
    <div className="mb-4 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] p-3">
      <div className="mb-3 flex items-center justify-between">
        <button
          type="button"
          onClick={onPrev}
          className="flex h-8 w-8 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-secondary)] hover:bg-[var(--color-surface-variant)]"
          aria-label="Mês anterior"
        >
          ‹
        </button>
        <span className="text-sm font-semibold capitalize">{monthLabel(focused)}</span>
        <button
          type="button"
          onClick={onNext}
          className="flex h-8 w-8 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-secondary)] hover:bg-[var(--color-surface-variant)]"
          aria-label="Próximo mês"
        >
          ›
        </button>
      </div>
      <div className="mb-1 grid grid-cols-7 gap-1 text-center text-[10px] font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)]">
        {["D", "S", "T", "Q", "Q", "S", "S"].map((d, i) => (
          <span key={i}>{d}</span>
        ))}
      </div>
      <div className="grid grid-cols-7 gap-1">
        {cells.map((date, i) => {
          if (!date) return <span key={`e-${i}`} />;
          const key = dateKey(date);
          const hasTasks = tasksByDay.has(key);
          const isToday = key === todayKey;
          const isSelected = selectedKey === key;
          return (
            <button
              key={key}
              type="button"
              onClick={() => onSelectDay(isSelected ? null : key)}
              className={`relative flex h-9 flex-col items-center justify-center rounded-[var(--radius-sm)] text-xs tabular-nums transition-colors ${
                isSelected
                  ? "bg-[var(--color-accent)] font-semibold text-[var(--color-accent-text)]"
                  : isToday
                    ? "bg-[var(--color-surface-variant)] font-semibold text-[var(--color-text)]"
                    : "text-[var(--color-text-secondary)] hover:bg-[var(--color-surface-variant)]"
              }`}
            >
              {date.getDate()}
              {hasTasks && (
                <span
                  className={`absolute bottom-1 h-1 w-1 rounded-full ${
                    isSelected ? "bg-[var(--color-accent-text)]" : "bg-[var(--color-text-tertiary)]"
                  }`}
                />
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
}

function WeekStrip({
  focused,
  tasksByDay,
  selectedKey,
  onSelectDay,
}: {
  focused: Date;
  tasksByDay: Map<string, Task[]>;
  selectedKey: string | null;
  onSelectDay: (key: string | null) => void;
}) {
  const start = startOfDay(focused);
  const day = start.getDay();
  start.setDate(start.getDate() - day);
  const days = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(start);
    d.setDate(start.getDate() + i);
    return d;
  });
  const todayKey = dateKey(new Date());

  return (
    <div className="mb-4 grid grid-cols-7 gap-1 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] p-2">
      {days.map((date) => {
        const key = dateKey(date);
        const hasTasks = tasksByDay.has(key);
        const isSelected = selectedKey === key;
        const isToday = key === todayKey;
        return (
          <button
            key={key}
            type="button"
            onClick={() => onSelectDay(isSelected ? null : key)}
            className={`flex flex-col items-center gap-0.5 rounded-[var(--radius-sm)] py-2 text-center transition-colors ${
              isSelected
                ? "bg-[var(--color-accent)] text-[var(--color-accent-text)]"
                : isToday
                  ? "bg-[var(--color-surface-variant)]"
                  : "hover:bg-[var(--color-surface-variant)]"
            }`}
          >
            <span className="text-[10px] text-[var(--color-text-tertiary)]">
              {["D", "S", "T", "Q", "Q", "S", "S"][date.getDay()]}
            </span>
            <span className="text-sm font-semibold tabular-nums">{date.getDate()}</span>
            {hasTasks && (
              <span className="h-1 w-1 rounded-full bg-[var(--color-text-tertiary)]" />
            )}
          </button>
        );
      })}
    </div>
  );
}

export function UpcomingCanvas() {
  const { viewTasks, loading } = useWorkbench();
  const [mode, setMode] = useState<CalMode>("agenda");
  const [focusedMonth, setFocusedMonth] = useState(() => startOfDay(new Date()));
  const [selectedDayKey, setSelectedDayKey] = useState<string | null>(null);

  const tasksByDay = useMemo(() => groupByDay(viewTasks.pending), [viewTasks.pending]);

  const filteredTasks = useMemo(() => {
    if (!selectedDayKey) return viewTasks.pending;
    return viewTasks.pending.filter((t) => {
      const due = parseDueDate(t.dueDate);
      return due && dateKey(due) === selectedDayKey;
    });
  }, [viewTasks.pending, selectedDayKey]);

  const groupedList = useMemo(() => {
    const map = new Map<string, Task[]>();
    for (const t of filteredTasks) {
      const due = parseDueDate(t.dueDate);
      if (!due) continue;
      const key = dateKey(due);
      const list = map.get(key) ?? [];
      list.push(t);
      map.set(key, list);
    }
    return [...map.entries()].sort(([a], [b]) => a.localeCompare(b));
  }, [filteredTasks]);

  if (loading) return <TaskListSkeleton />;

  return (
    <>
      <div className="mb-4 flex gap-1 rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-[var(--color-surface)] p-1">
        {(["month", "week", "agenda"] as CalMode[]).map((m) => (
          <button
            key={m}
            type="button"
            onClick={() => setMode(m)}
            className={`flex-1 rounded-[var(--radius-sm)] py-1.5 text-xs font-semibold capitalize transition-colors ${
              mode === m
                ? "bg-[var(--color-surface-variant)] text-[var(--color-text)]"
                : "text-[var(--color-text-tertiary)] hover:text-[var(--color-text-secondary)]"
            }`}
          >
            {m === "month" ? "Mês" : m === "week" ? "Semana" : "Agenda"}
          </button>
        ))}
      </div>

      {mode === "month" && (
        <MonthGrid
          focused={focusedMonth}
          tasksByDay={tasksByDay}
          selectedKey={selectedDayKey}
          onSelectDay={setSelectedDayKey}
          onPrev={() =>
            setFocusedMonth((d) => new Date(d.getFullYear(), d.getMonth() - 1, 1))
          }
          onNext={() =>
            setFocusedMonth((d) => new Date(d.getFullYear(), d.getMonth() + 1, 1))
          }
        />
      )}

      {mode === "week" && (
        <WeekStrip
          focused={focusedMonth}
          tasksByDay={tasksByDay}
          selectedKey={selectedDayKey}
          onSelectDay={setSelectedDayKey}
        />
      )}

      {selectedDayKey && (
        <p className="mb-2 px-2 text-xs text-[var(--color-text-tertiary)]">
          {formatDayLabel(parseDateKey(selectedDayKey))}
          <button
            type="button"
            onClick={() => setSelectedDayKey(null)}
            className="ml-2 text-[var(--color-text-secondary)] underline"
          >
            Limpar filtro
          </button>
        </p>
      )}

      {!groupedList.length ? (
        <p className="px-4 py-8 text-center text-sm text-[var(--color-text-tertiary)]">
          Nenhuma tarefa com data.
        </p>
      ) : (
        groupedList.map(([key, tasks]) => (
          <section key={key} className="mt-2">
            <h2 className="px-2 pb-2 pt-3 text-[13px] font-semibold text-[var(--color-text-secondary)]">
              {formatDayLabel(parseDateKey(key))}
            </h2>
            {tasks.map((t) => (
              <TaskRow key={t.id} task={t} />
            ))}
          </section>
        ))
      )}
    </>
  );
}
