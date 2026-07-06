"use client";

import type { Subtask, Task } from "@/lib/types/task";
import { useWorkbench, type SubtaskKey } from "@/components/shell/workbench-context";
import { DoneCircle } from "@/components/ui/done-circle";
import { SubtaskMetaLine } from "@/components/tasks/task-meta-line";

export function FilterSubtaskRow({
  subtask,
  parent,
  subtaskIndex,
}: {
  subtask: Subtask;
  parent: Task;
  subtaskIndex: number;
}) {
  const { selectedSubtaskKey, selectSubtask, toggleSubtaskDone } = useWorkbench();
  const key = `${parent.id}:${subtaskIndex}` as SubtaskKey;
  const selected = selectedSubtaskKey === key;

  return (
    <div
      role="button"
      tabIndex={0}
      onClick={() => selectSubtask(parent.id, subtaskIndex)}
      onKeyDown={(e) => {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          selectSubtask(parent.id, subtaskIndex);
        }
      }}
      className={`mx-2 mb-0.5 flex min-h-[52px] cursor-pointer items-start gap-2.5 rounded-[var(--radius-sm)] border border-[var(--color-border)]/40 bg-[var(--color-surface)] px-3 py-2.5 transition-colors ${
        selected ? "bg-[var(--color-hover-overlay)]" : "hover:bg-[var(--color-hover-overlay)]/70"
      }`}
    >
      <DoneCircle
        small
        done={subtask.done}
        priority={subtask.priority}
        label={`${subtask.done ? "Marcar pendente" : "Marcar concluída"}: ${subtask.name}`}
        onClick={(e) => {
          e.stopPropagation();
          toggleSubtaskDone(key);
        }}
      />
      <div className="min-w-0 flex-1">
        <span
          className={`block truncate text-[15px] font-semibold ${
            subtask.done ? "text-[var(--color-text-tertiary)] line-through" : "text-[var(--color-text)]"
          }`}
        >
          {subtask.name}
        </span>
        <p className="mt-0.5 truncate text-xs text-[var(--color-text-tertiary)]">
          {parent.title}
          {parent.project ? ` · ${parent.project}` : ""}
        </p>
        <SubtaskMetaLine sub={subtask} />
      </div>
    </div>
  );
}
