"use client";

import { memo } from "react";
import type { Task } from "@/lib/types/task";
import { DoneCircle } from "@/components/ui/done-circle";
import { TaskMetaLine } from "@/components/tasks/task-meta-line";
import { InlineSubtasks } from "@/components/tasks/task-list";
import { useWorkbench } from "@/components/shell/workbench-context";
import { AppIcon } from "@/components/ui/app-icon";
import { ArrowDown01Icon } from "@/lib/icons/nav-icons";
import { WhatsAppTaskCopyButton } from "@/components/tasks/whatsapp-task-copy-button";
import { taskShowsWhatsAppCopy } from "@/lib/utils/whatsapp-routine-message";

type ScheduleTaskRowProps = {
  task: Task;
  selected: boolean;
  onSelect: (id: string) => void;
  onToggleDone: (id: string) => void;
};

export const ScheduleTaskRow = memo(function ScheduleTaskRow({
  task,
  selected,
  onSelect,
  onToggleDone,
}: ScheduleTaskRowProps) {
  const { expandedSubtasks, toggleSubtaskExpand } = useWorkbench();
  const subs = task.subtasks ?? [];
  const isExpanded = expandedSubtasks.has(task.id);
  const showsWhatsApp = taskShowsWhatsAppCopy(task);

  return (
    <>
      <div
        role="button"
        tabIndex={0}
        data-task-id={task.id}
        onClick={() => onSelect(task.id)}
        onKeyDown={(e) => {
          if (e.key === "Enter" || e.key === " ") {
            e.preventDefault();
            onSelect(task.id);
          }
        }}
        className={`schedule-row scroll-list-item mb-0.5 flex min-h-[52px] cursor-pointer items-start gap-2 rounded-[var(--radius-md)] border py-2 pl-1 ${
          subs.length > 0 || showsWhatsApp ? "pr-0.5" : "pr-3"
        } ${
          selected
            ? "border-[var(--color-border-strong)] bg-[var(--color-hover-overlay)]"
            : "border-transparent"
        }`}
        data-selected={selected ? "" : undefined}
      >
        <DoneCircle
          done={task.done}
          priority={task.priority}
          label={task.done ? "Marcar pendente" : "Marcar concluída"}
          onClick={(e) => {
            e.stopPropagation();
            onToggleDone(task.id);
          }}
        />
        <div className="min-w-0 flex-1">
          <p
            className={`truncate text-[15.5px] font-semibold leading-snug ${
              task.done ? "text-[var(--color-text-tertiary)] line-through" : ""
            }`}
          >
            {task.title}
          </p>
          {task.preview && (
            <p
              className={`mt-0.5 truncate text-[12.5px] text-[var(--color-text-secondary)] ${
                task.done ? "opacity-60 line-through" : ""
              }`}
            >
              {task.preview}
            </p>
          )}
          <TaskMetaLine task={task} hideDate />
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
      {subs.length > 0 && (
        <div className="expand-panel scroll-list-item" data-open={isExpanded ? "true" : "false"}>
          <div>
            <InlineSubtasks task={task} open={isExpanded} />
          </div>
        </div>
      )}
    </>
  );
});
