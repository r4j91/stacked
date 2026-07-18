"use client";

import type { Task } from "@/lib/types/task";
import { AppIcon } from "@/components/ui/app-icon";
import { ArrowDown01Icon } from "@/lib/icons/nav-icons";
import { WhatsAppTaskCopyButton } from "@/components/tasks/whatsapp-task-copy-button";
import { taskShowsWhatsAppCopy } from "@/lib/utils/whatsapp-routine-message";

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
  const showWhatsApp = taskShowsWhatsAppCopy(task);
  if (!hasSubtasks && !showWhatsApp) return null;

  return (
    <div className="task-row-rail flex w-[var(--task-row-rail)] shrink-0 flex-col items-end gap-1 self-stretch">
      {hasSubtasks ? (
        <button
          type="button"
          onClick={(e) => {
            e.stopPropagation();
            onToggleSubtasks();
          }}
          className="flex h-8 w-8 shrink-0 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-tertiary)] transition-colors duration-150 hover:bg-[var(--color-hover-overlay)] hover:text-[var(--color-text-secondary)]"
          aria-expanded={isExpanded}
          aria-label={isExpanded ? "Recolher subtarefas" : "Expandir subtarefas"}
        >
          <AppIcon
            icon={ArrowDown01Icon}
            size={18}
            className={`transition-transform duration-200 ease-out ${isExpanded ? "rotate-180" : ""}`}
          />
        </button>
      ) : (
        <span className="h-8 w-8 shrink-0" aria-hidden />
      )}
      {showWhatsApp ? (
        <div className="mt-auto flex justify-end">
          <WhatsAppTaskCopyButton
            task={task}
            className="flex h-8 w-8 shrink-0 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-accent)] transition-colors duration-150 hover:bg-[var(--color-hover-overlay)]"
          />
        </div>
      ) : null}
    </div>
  );
}
