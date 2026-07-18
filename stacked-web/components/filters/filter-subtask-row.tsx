"use client";

import type { Subtask, Task } from "@/lib/types/task";
import { useWorkbench, type SubtaskKey } from "@/components/shell/workbench-context";
import { DoneCircle } from "@/components/ui/done-circle";
import { SubtaskMetaLine } from "@/components/tasks/task-meta-line";
import { TaskRowEyebrow } from "@/components/tasks/task-row-eyebrow";
import { TaskRowTime } from "@/components/tasks/task-time-chip";
import { useTaskRowLayout } from "@/lib/theme/use-task-row-layout";
import { showsTrailingTime } from "@/lib/theme/task-row-layout";

export function FilterSubtaskRow({
  subtask,
  parent,
  subtaskIndex,
}: {
  subtask: Subtask;
  parent: Task;
  subtaskIndex: number;
}) {
  const { openTaskInspector, selectSubtask, toggleSubtaskDone } = useWorkbench();
  const layout = useTaskRowLayout();
  const key = `${parent.id}:${subtaskIndex}` as SubtaskKey;
  const trailingTime = showsTrailingTime(layout);
  const notes = subtask.notes?.trim();

  function openSubtaskInspector() {
    openTaskInspector(parent);
    selectSubtask(parent.id, subtaskIndex);
  }

  return (
    <div className="scroll-list-item filter-result-row mb-0.5 overflow-hidden rounded-[var(--radius-md)]">
      <div className="relative bg-[var(--color-bg)]">
        <div
          role="button"
          tabIndex={0}
          onClick={openSubtaskInspector}
          onKeyDown={(e) => {
            if (e.key === "Enter" || e.key === " ") {
              e.preventDefault();
              openSubtaskInspector();
            }
          }}
          className={`task-row task-row-grid task-row-grid--no-rail min-h-[52px] cursor-pointer rounded-[var(--radius-md)] border border-transparent px-2 py-2 transition-[background-color,opacity] duration-150 ${
            subtask.done ? "opacity-65" : ""
          }`}
        >
          <div className="reorder-gutter" aria-hidden />
          <DoneCircle
            done={subtask.done}
            priority={subtask.priority}
            label={`${subtask.done ? "Marcar pendente" : "Marcar concluída"}: ${subtask.name}`}
            onClick={(e) => {
              e.stopPropagation();
              toggleSubtaskDone(key);
            }}
          />
          <div className="task-row-grid__content min-w-0 flex-1">
            <TaskRowEyebrow layout={layout} priority={subtask.priority} />
            <div className="flex items-baseline gap-1.5">
              <p
                className={`min-w-0 flex-1 truncate text-[15.5px] font-semibold leading-snug ${
                  subtask.done ? "text-[var(--color-text-tertiary)] line-through" : ""
                }`}
              >
                {subtask.name}
              </p>
              {trailingTime ? <TaskRowTime time={subtask.time} /> : null}
            </div>
            {notes ? (
              <p
                className={`mt-0.5 truncate text-[12.5px] text-[var(--color-text-tertiary)] ${
                  subtask.done ? "line-through opacity-60" : ""
                }`}
              >
                {notes}
              </p>
            ) : null}
            <p className="mt-0.5 truncate text-[12.5px] text-[var(--color-text-secondary)]">
              {parent.title}
              {parent.project ? ` · ${parent.project}` : ""}
            </p>
            <SubtaskMetaLine sub={subtask} />
          </div>
        </div>
      </div>
    </div>
  );
}
