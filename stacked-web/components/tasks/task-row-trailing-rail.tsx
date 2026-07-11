"use client";

import type { Task } from "@/lib/types/task";
import { AppIcon } from "@/components/ui/app-icon";
import { ArrowDown01Icon } from "@/lib/icons/nav-icons";
import { WhatsAppTaskCopyButton } from "@/components/tasks/whatsapp-task-copy-button";

type TaskRowTrailingRailProps = {
  task: Task;
  hasSubtasks: boolean;
  isExpanded: boolean;
  onToggleSubtasks: () => void;
};

export function TaskRowTrailingRail({
  task,
  hasSubtasks,
  isExpanded,
  onToggleSubtasks,
}: TaskRowTrailingRailProps) {
  return (
    <div className="task-row-rail mt-0.5 grid w-[var(--task-row-rail)] shrink-0 grid-cols-2 self-start">
      <div className="flex justify-center">
        <WhatsAppTaskCopyButton
          task={task}
          className="flex h-8 w-8 shrink-0 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-accent)] hover:bg-[var(--color-hover-overlay)]"
        />
      </div>
      <div className="flex justify-center">
        {hasSubtasks ? (
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              onToggleSubtasks();
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
  );
}
