"use client";

import type { Label } from "@/lib/types/label";
import type { Subtask, Task } from "@/lib/types/task";
import { useWorkbench } from "@/components/shell/workbench-context";
import {
  parseDueDate,
  formatTaskDate,
  dueDateChipColor,
  deadlineChipColor,
  deadlineChipLabel,
} from "@/lib/utils/date";
import { TagChip } from "@/components/ui/tag-chip";
import { DueDateChip } from "@/components/ui/due-date-chip";
import { AppIcon } from "@/components/ui/app-icon";
import {
  TaskDone01Icon,
  Folder01Icon,
  Calendar03Icon,
  BubbleChatIcon,
  Target01Icon,
} from "@/lib/icons/nav-icons";
import { useLabelChipStyle } from "@/lib/theme/use-label-chip-style";
import { useDueDateChipStyle } from "@/lib/theme/use-due-date-chip-style";
import { useTaskRowLayout } from "@/lib/theme/use-task-row-layout";
import { layoutUsesEyebrow } from "@/lib/theme/task-row-layout";
import { useSubtaskProgressRing } from "@/lib/theme/use-subtask-progress-ring";
import { priorityColor } from "@/lib/utils/priority";

type TaskMetaLineProps = {
  task: Task;
  /** Em breve: tarefas já agrupadas por dia — omitir chip de data */
  hideDate?: boolean;
  labels?: Label[];
  maxLabels?: number;
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
  time: _time,
  done,
  hideDate,
}: {
  dueDate?: string | null;
  time?: string | null;
  done?: boolean;
  hideDate?: boolean;
}) {
  // Hora fica no trailing do card (paridade iOS) — meta só mostra a data.
  void _time;
  const due = parseDueDate(dueDate);
  const color = dueDateChipColor(due, Boolean(done));

  if (hideDate || !dueDate) return null;
  const label = formatTaskDate(due);
  if (!label) return null;
  return (
    <span
      className="inline-flex max-w-full shrink items-center gap-1 truncate text-xs font-semibold tabular-nums"
      style={{ color }}
    >
      <AppIcon icon={Calendar03Icon} size={14} strokeWidth={1.75} />
      <span className="truncate">{label}</span>
    </span>
  );
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
  maxLabels,
}: {
  taskLabels: ChipLabel[];
  labelChipStyle: ReturnType<typeof useLabelChipStyle>;
  maxLabels: number;
}) {
  const items: React.ReactNode[] = [];
  for (const label of taskLabels.slice(0, maxLabels)) {
    items.push(
      <TagChip key={label.id} label={label.name} color={label.color} style={labelChipStyle} />,
    );
  }
  if (taskLabels.length > maxLabels) {
    items.push(
      <TagChip
        key="more"
        label={`+${taskLabels.length - maxLabels}`}
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
    <span className="inline-flex shrink-0 items-center gap-1 text-[12px] text-[var(--color-text-tertiary)]">
      <AppIcon icon={TaskDone01Icon} size={12} strokeWidth={1.75} />
      <span className="tabular-nums">
        {doneSubs}/{subs.length}
      </span>
    </span>
  );
}

function CommentCount({ count }: { count?: number }) {
  if (!count || count <= 0) return null;
  return (
    <span className="inline-flex shrink-0 items-center gap-1 text-[12px] text-[var(--color-text-tertiary)]">
      <AppIcon icon={BubbleChatIcon} size={12} strokeWidth={1.75} />
      <span className="tabular-nums">{count}</span>
    </span>
  );
}

function ProjectChip({ name }: { name: string }) {
  return (
    <span className="inline-flex max-w-[40%] shrink items-center gap-1 truncate text-xs font-medium text-[var(--color-text-secondary)]">
      <AppIcon icon={Folder01Icon} size={14} strokeWidth={1.75} />
      <span className="truncate">{name}</span>
    </span>
  );
}

export function TaskMetaLine({
  task,
  hideDate,
  labels: labelsProp,
  maxLabels = 2,
}: TaskMetaLineProps) {
  const { labels: contextLabels } = useWorkbench();
  const labelChipStyle = useLabelChipStyle();
  const dueDateChipStyle = useDueDateChipStyle();
  const layout = useTaskRowLayout();
  const progressRing = useSubtaskProgressRing();
  const allLabels = labelsProp ?? contextLabels;
  const subs = task.subtasks ?? [];
  const due = parseDueDate(task.dueDate);
  const taskLabels = resolveTaskLabels(task, allLabels);
  const usesEyebrow = layoutUsesEyebrow(layout);
  const showSubtaskCount = subs.length > 0 && !progressRing;

  const items: React.ReactNode[] = [];

  if (usesEyebrow) {
    if (layout === "x2" && task.priority) {
      items.push(<PriorityFlag key="prio" priority={task.priority} />);
    }

    const hasFusedSchedule = !hideDate && Boolean(task.dueDate);
    if (hasFusedSchedule) {
      items.push(
        <FusedScheduleFlat
          key="sched"
          dueDate={task.dueDate}
          done={task.done}
          hideDate={hideDate}
        />,
      );
    }

    if (task.deadline) {
      const dl = parseDueDate(task.deadline);
      const dlLabel = deadlineChipLabel(dl);
      if (dlLabel) {
        items.push(
          <DueDateChip
            key="deadline"
            label={dlLabel}
            color={deadlineChipColor(dl, task.done)}
            day={dl?.getDate() ?? null}
            style={dueDateChipStyle}
            icon={Target01Icon}
          />,
        );
      }
    }

    items.push(...LabelItems({ taskLabels, labelChipStyle, maxLabels }));

    if (showSubtaskCount) {
      items.push(<SubtaskCount key="sub" subs={subs} />);
    }

    items.push(<CommentCount key="cmt" count={task.commentCount} />);
  } else {
    // Paridade iOS: projeto → data → subtarefas → comentários → etiquetas
    // (hora vai no trailing do título, não na meta)
    if (task.project && task.project !== "Sem projeto") {
      items.push(<ProjectChip key="proj" name={task.project} />);
    }

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

    if (task.deadline) {
      const dl = parseDueDate(task.deadline);
      const dlLabel = deadlineChipLabel(dl);
      if (dlLabel) {
        items.push(
          <DueDateChip
            key="deadline"
            label={dlLabel}
            color={deadlineChipColor(dl, task.done)}
            day={dl?.getDate() ?? null}
            style={dueDateChipStyle}
            icon={Target01Icon}
          />,
        );
      }
    }

    if (showSubtaskCount) {
      items.push(<SubtaskCount key="sub" subs={subs} />);
    }

    items.push(<CommentCount key="cmt" count={task.commentCount} />);

    items.push(...LabelItems({ taskLabels, labelChipStyle, maxLabels }));
  }

  if (!items.length) return task.done ? <span className="text-xs text-[var(--color-text-tertiary)]">—</span> : null;

  return (
    <div className="task-meta-line mt-1.5 flex min-h-[22px] items-center gap-1.5 overflow-hidden">
      {items}
    </div>
  );
}

export function SubtaskMetaLine({ sub, maxLabels = 2 }: { sub: Subtask; maxLabels?: number }) {
  const { labels: allLabels } = useWorkbench();
  const labelChipStyle = useLabelChipStyle();
  const dueDateChipStyle = useDueDateChipStyle();
  const layout = useTaskRowLayout();
  const usesEyebrow = layoutUsesEyebrow(layout);

  let subLabels =
    (sub.labelIds ?? [])
      .map((id) => allLabels.find((l) => l.id === id))
      .filter((l): l is NonNullable<typeof l> => Boolean(l));

  if (!subLabels.length && sub.tag) {
    const matched = allLabels.find((l) => l.name === sub.tag);
    if (matched) subLabels = [matched];
  }

  const items: React.ReactNode[] = [];

  if (usesEyebrow) {
    if (layout === "x2" && sub.priority) {
      items.push(<PriorityFlag key="prio" priority={sub.priority} />);
    }

    const hasFusedSchedule = Boolean(sub.dueDate);
    if (hasFusedSchedule) {
      items.push(
        <FusedScheduleFlat
          key="sched"
          dueDate={sub.dueDate}
          done={sub.done}
        />,
      );
    }

    if (sub.deadline) {
      const dl = parseDueDate(sub.deadline);
      const dlLabel = deadlineChipLabel(dl);
      if (dlLabel) {
        items.push(
          <DueDateChip
            key="deadline"
            label={dlLabel}
            color={deadlineChipColor(dl, sub.done)}
            day={dl?.getDate() ?? null}
            style={dueDateChipStyle}
            icon={Target01Icon}
          />,
        );
      }
    }

    items.push(...LabelItems({ taskLabels: subLabels, labelChipStyle, maxLabels }));
  } else {
    // Paridade iOS default: data → etiquetas (hora no trailing do título)
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

    if (sub.deadline) {
      const dl = parseDueDate(sub.deadline);
      const dlLabel = deadlineChipLabel(dl);
      if (dlLabel) {
        items.push(
          <DueDateChip
            key="deadline"
            label={dlLabel}
            color={deadlineChipColor(dl, sub.done)}
            day={dl?.getDate() ?? null}
            style={dueDateChipStyle}
            icon={Target01Icon}
          />,
        );
      }
    }

    items.push(...LabelItems({ taskLabels: subLabels, labelChipStyle, maxLabels }));
  }

  if (!items.length) return null;

  return (
    <div className="task-meta-line mt-0.5 flex items-center gap-1 overflow-hidden">{items}</div>
  );
}
