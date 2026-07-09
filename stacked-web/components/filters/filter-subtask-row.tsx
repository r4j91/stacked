"use client";

import type { Subtask, Task } from "@/lib/types/task";
import { useWorkbench, type SubtaskKey } from "@/components/shell/workbench-context";
import { DoneCircle } from "@/components/ui/done-circle";
import { SubtaskMetaLine } from "@/components/tasks/task-meta-line";
import { TaskRowTime } from "@/components/tasks/task-time-chip";

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
  const key = `${parent.id}:${subtaskIndex}` as SubtaskKey;

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
          className={`task-row flex min-h-[52px] cursor-pointer items-start gap-2 rounded-[var(--radius-md)] border border-transparent py-2 pl-1 pr-3 ${
            subtask.done ? "opacity-65" : ""
          }`}
        >
          <DoneCircle
            done={subtask.done}
            priority={subtask.priority}
            label={`${subtask.done ? "Marcar pendente" : "Marcar concluída"}: ${subtask.name}`}
            onClick={(e) => {
              e.stopPropagation();
              toggleSubtaskDone(key);
            }}
          />
          <div className="min-w-0 flex-1">
            <div className="flex items-start gap-2">
              <p
                className={`min-w-0 flex-1 truncate text-[15.5px] font-semibold leading-snug ${
                  subtask.done ? "text-[var(--color-text-tertiary)] line-through" : ""
                }`}
              >
                {subtask.name}
              </p>
              <TaskRowTime time={subtask.time} className="mt-1" />
            </div>
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
