"use client";

import type { Label } from "@/lib/types/label";
import type { Subtask, Task } from "@/lib/types/task";
import { useWorkbench } from "@/components/shell/workbench-context";
import {
  parseDueDate,
  formatTaskDate,
  formatDueDateTimeLabel,
  formatTimeDisplay,
  dueDateChipColor,
} from "@/lib/utils/date";
import { TagChip } from "@/components/ui/tag-chip";
import { DueDateChip } from "@/components/ui/due-date-chip";
import { TaskRowTime } from "@/components/tasks/task-time-chip";
import { AppIcon } from "@/components/ui/app-icon";
import { TaskDone01Icon, Folder01Icon, Calendar03Icon } from "@/lib/icons/nav-icons";
import { useLabelChipStyle } from "@/lib/theme/use-label-chip-style";
import { useDueDateChipStyle } from "@/lib/theme/use-due-date-chip-style";
import { useTaskRowLayout } from "@/lib/theme/use-task-row-layout";
import { priorityColor } from "@/lib/utils/priority";

type TaskMetaLineProps = {
  task: Task;
  /** Em breve: tarefas já agrupadas por dia — omitir chip de data */
  hideDate?: boolean;
  labels?: Label[];
};

type ChipLabel = { id: string; name: string; color: string };

function resolveTaskLabels(task: Task, allLabels: Label[]): ChipLabel[] {
  let taskLabels: ChipLabel[] =
    task.labels ??
    (task.labelIds ?? [])
      .map((id) => allLabels.find((l) => l.id === id))
      .filter((l): l is Label => Boolean(l));

  if (!taskLabels.length && task.tag) {
    const matched = allLabels.find((l) => l.name === task.tag);
    if (matched) taskLabels = [matched];
  }
  return taskLabels;
}

function FusedScheduleFlat({
  dueDate,
  time,
  done,
  hideDate,
}: {
  dueDate?: string | null;
  time?: string | null;
  done?: boolean;
  hideDate?: boolean;
}) {
  const due = parseDueDate(dueDate);
  const color = dueDateChipColor(due, Boolean(done));

  if (!hideDate && dueDate) {
    const label = formatDueDateTimeLabel(dueDate, time);
    if (!label) return null;
    return (
      <span
        className="inline-flex max-w-full items-center gap-1 truncate text-xs font-semibold tabular-nums"
        style={{ color }}
      >
        <AppIcon icon={Calendar03Icon} size={14} strokeWidth={1.75} />
        <span className="truncate">{label}</span>
      </span>
    );
  }

  const timeLabel = formatTimeDisplay(time);
  if (!timeLabel) return null;
  return <TaskRowTime time={time} />;
}

function PriorityFlag({ priority }: { priority: NonNullable<Task["priority"]> }) {
  const color = priorityColor(priority);
  return (
    <span
      className="inline-flex shrink-0 items-center rounded px-1.5 py-0.5 text-[10px] font-bold tracking-wide"
      style={{
        color,
        backgroundColor: `color-mix(in srgb, ${color} 14%, transparent)`,
      }}
    >
      {priority}
    </span>
  );
}

function LabelItems({
  taskLabels,
  labelChipStyle,
}: {
  taskLabels: ChipLabel[];
  labelChipStyle: ReturnType<typeof useLabelChipStyle>;
}) {
  const items: React.ReactNode[] = [];
  for (const label of taskLabels.slice(0, 3)) {
    items.push(
      <TagChip key={label.id} label={label.name} color={label.color} style={labelChipStyle} />,
    );
  }
  if (taskLabels.length > 3) {
    items.push(
      <TagChip
        key="more"
        label={`+${taskLabels.length - 3}`}
        color="var(--color-text-tertiary)"
        showIcon={false}
        style={labelChipStyle}
      />,
    );
  }
  return items;
}

function SubtaskCount({ subs }: { subs: Subtask[] }) {
  if (!subs.length) return null;
  const doneSubs = subs.filter((s) => s.done).length;
  return (
    <span className="inline-flex items-center gap-1 text-[12px] text-[var(--color-text-tertiary)]">
      <AppIcon icon={TaskDone01Icon} size={12} strokeWidth={1.75} />
      <span className="tabular-nums">
        {doneSubs}/{subs.length}
      </span>
    </span>
  );
}

export function TaskMetaLine({ task, hideDate, labels: labelsProp }: TaskMetaLineProps) {
  const { labels: contextLabels } = useWorkbench();
  const labelChipStyle = useLabelChipStyle();
  const dueDateChipStyle = useDueDateChipStyle();
  const layout = useTaskRowLayout();
  const allLabels = labelsProp ?? contextLabels;
  const subs = task.subtasks ?? [];
  const due = parseDueDate(task.dueDate);
  const taskLabels = resolveTaskLabels(task, allLabels);

  const items: React.ReactNode[] = [];

  if (layout === "f2" || layout === "x2") {
    if (layout === "x2" && task.priority) {
      items.push(<PriorityFlag key="prio" priority={task.priority} />);
    }

    const hasFusedSchedule =
      (!hideDate && Boolean(task.dueDate)) || Boolean(formatTimeDisplay(task.time));
    if (hasFusedSchedule) {
      items.push(
        <FusedScheduleFlat
          key="sched"
          dueDate={task.dueDate}
          time={task.time}
          done={task.done}
          hideDate={hideDate}
        />,
      );
    }

    items.push(...LabelItems({ taskLabels, labelChipStyle }));

    if (subs.length) {
      items.push(<SubtaskCount key="sub" subs={subs} />);
    }
  } else {
    if (task.project && task.project !== "Sem projeto") {
      items.push(
        <span
          key="proj"
          className="inline-flex max-w-full items-center gap-1 truncate text-xs font-medium text-[var(--color-text-secondary)]"
        >
          <AppIcon icon={Folder01Icon} size={14} strokeWidth={1.75} />
          <span className="truncate">{task.project}</span>
        </span>,
      );
    }

    if (task.time) {
      items.push(<TaskRowTime key="time" time={task.time} />);
    }

    items.push(...LabelItems({ taskLabels, labelChipStyle }));

    if (!hideDate && task.dueDate) {
      const dateLabel = formatTaskDate(due);
      if (dateLabel) {
        items.push(
          <DueDateChip
            key="d"
            label={dateLabel}
            color={dueDateChipColor(due, task.done)}
            day={due?.getDate() ?? null}
            style={dueDateChipStyle}
          />,
        );
      }
    }

    if (subs.length) {
      items.push(<SubtaskCount key="sub" subs={subs} />);
    }
  }

  if (!items.length) return task.done ? <span className="text-xs text-[var(--color-text-tertiary)]">—</span> : null;

  return (
    <div className="task-meta-line mt-1.5 flex min-h-[22px] flex-wrap items-center gap-1.5">
      {items}
    </div>
  );
}

export function SubtaskMetaLine({ sub, maxLabels = 2 }: { sub: Subtask; maxLabels?: number }) {
  const { labels: allLabels } = useWorkbench();
  const labelChipStyle = useLabelChipStyle();
  const dueDateChipStyle = useDueDateChipStyle();
  const layout = useTaskRowLayout();

  let subLabels =
    (sub.labelIds ?? [])
      .map((id) => allLabels.find((l) => l.id === id))
      .filter((l): l is NonNullable<typeof l> => Boolean(l));

  if (!subLabels.length && sub.tag) {
    const matched = allLabels.find((l) => l.name === sub.tag);
    if (matched) subLabels = [matched];
  }

  const items: React.ReactNode[] = [];

  if (layout === "f2" || layout === "x2") {
    if (layout === "x2" && sub.priority) {
      items.push(<PriorityFlag key="prio" priority={sub.priority} />);
    }

    const hasFusedSchedule =
      Boolean(sub.dueDate) || Boolean(formatTimeDisplay(sub.time));
    if (hasFusedSchedule) {
      items.push(
        <FusedScheduleFlat
          key="sched"
          dueDate={sub.dueDate}
          time={sub.time}
          done={sub.done}
        />,
      );
    }

    items.push(...LabelItems({ taskLabels: subLabels.slice(0, maxLabels), labelChipStyle }));
    if (subLabels.length > maxLabels) {
      items.push(
        <TagChip
          key="more"
          label={`+${subLabels.length - maxLabels}`}
          color="var(--color-text-tertiary)"
          showIcon={false}
          style={labelChipStyle}
        />,
      );
    }
  } else {
    for (const label of subLabels.slice(0, maxLabels)) {
      items.push(
        <TagChip key={label.id} label={label.name} color={label.color} style={labelChipStyle} />,
      );
    }
    if (subLabels.length > maxLabels) {
      items.push(
        <TagChip
          key="more"
          label={`+${subLabels.length - maxLabels}`}
          color="var(--color-text-tertiary)"
          showIcon={false}
          style={labelChipStyle}
        />,
      );
    }

    if (sub.dueDate) {
      const due = parseDueDate(sub.dueDate);
      const dateLabel = formatTaskDate(due);
      if (dateLabel) {
        items.push(
          <DueDateChip
            key="d"
            label={dateLabel}
            color={dueDateChipColor(due, sub.done)}
            day={due?.getDate() ?? null}
            style={dueDateChipStyle}
          />,
        );
      }
    }

    if (sub.time) {
      items.push(<TaskRowTime key="time" time={sub.time} />);
    }
  }

  if (!items.length) return null;

  return <div className="mt-0.5 flex flex-wrap items-center gap-1">{items}</div>;
}
