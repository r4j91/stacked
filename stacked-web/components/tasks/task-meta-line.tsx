"use client";

import type { Label } from "@/lib/types/label";
import type { Subtask, Task } from "@/lib/types/task";
import { useWorkbench } from "@/components/shell/workbench-context";
import { parseDueDate, formatTaskDate, dueDateChipColor } from "@/lib/utils/date";
import { TagChip } from "@/components/ui/tag-chip";
import { AppIcon } from "@/components/ui/app-icon";
import { TaskDone01Icon, Calendar03Icon } from "@/lib/icons/nav-icons";

type TaskMetaLineProps = {
  task: Task;
  /** Em breve: tarefas já agrupadas por dia — omitir chip de data */
  hideDate?: boolean;
  labels?: Label[];
};

export function TaskMetaLine({ task, hideDate, labels: labelsProp }: TaskMetaLineProps) {
  const { labels: contextLabels } = useWorkbench();
  const allLabels = labelsProp ?? contextLabels;
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

  if (task.project && task.project !== "Sem projeto") {
    items.push(
      <span key="proj" className="truncate text-[12px] text-[var(--color-text-tertiary)]">
        {task.project}
      </span>,
    );
  }

  for (const label of taskLabels.slice(0, 3)) {
    items.push(<TagChip key={label.id} label={label.name} color={label.color} />);
  }
  if (taskLabels.length > 3) {
    items.push(
      <TagChip key="more" label={`+${taskLabels.length - 3}`} color="var(--color-text-tertiary)" showIcon={false} />,
    );
  }

  if (!hideDate && task.dueDate) {
    const dateLabel = formatTaskDate(due);
    if (dateLabel) {
      items.push(
        <TagChip
          key="d"
          label={dateLabel}
          color={dueDateChipColor(due, task.done)}
          icon={Calendar03Icon}
        />,
      );
    }
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
    <div className="task-meta-line mt-1.5 flex min-h-[22px] flex-wrap items-center gap-1.5">
      {items}
    </div>
  );
}

export function SubtaskMetaLine({ sub, maxLabels = 2 }: { sub: Subtask; maxLabels?: number }) {
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

  for (const label of subLabels.slice(0, maxLabels)) {
    items.push(<TagChip key={label.id} label={label.name} color={label.color} />);
  }
  if (subLabels.length > maxLabels) {
    items.push(
      <TagChip
        key="more"
        label={`+${subLabels.length - maxLabels}`}
        color="var(--color-text-tertiary)"
        showIcon={false}
      />,
    );
  }

  if (sub.dueDate) {
    const due = parseDueDate(sub.dueDate);
    const dateLabel = formatTaskDate(due);
    if (dateLabel) {
      items.push(
        <TagChip
          key="d"
          label={dateLabel}
          color={dueDateChipColor(due, sub.done)}
          icon={Calendar03Icon}
        />,
      );
    }
  }

  if (!items.length) return null;

  return <div className="mt-0.5 flex flex-wrap items-center gap-1">{items}</div>;
}
