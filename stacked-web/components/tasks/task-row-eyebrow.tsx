"use client";

import type { Priority } from "@/lib/types/task";
import { priorityColor } from "@/lib/utils/priority";
import type { TaskRowLayout } from "@/lib/theme/task-row-layout";

type TaskRowEyebrowProps = {
  layout: TaskRowLayout;
  project?: string | null;
  priority?: Priority | null;
};

export function TaskRowEyebrow({ layout, project, priority }: TaskRowEyebrowProps) {
  if (layout !== "f2" && layout !== "x2") return null;

  const hasProject = Boolean(project && project !== "Sem projeto");
  const showPriority = layout === "f2" && Boolean(priority);

  if (!hasProject && !showPriority) return null;

  return (
    <div className="mb-0.5 flex min-w-0 items-center gap-1.5">
      {hasProject && (
        <span className="truncate text-[11px] font-semibold text-[var(--color-text-tertiary)]">
          {project}
        </span>
      )}
      {hasProject && showPriority && (
        <span className="h-0.5 w-0.5 shrink-0 rounded-full bg-[var(--color-text-tertiary)] opacity-60" />
      )}
      {showPriority && (
        <span
          className="shrink-0 text-[10px] font-bold uppercase tracking-wide"
          style={{ color: priorityColor(priority) }}
        >
          {priority}
        </span>
      )}
    </div>
  );
}
