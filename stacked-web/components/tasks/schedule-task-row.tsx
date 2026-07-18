"use client";

import { memo } from "react";
import type { Task } from "@/lib/types/task";
import { DoneCircle } from "@/components/ui/done-circle";
import { TaskMetaLine } from "@/components/tasks/task-meta-line";
import { TaskRowEyebrow } from "@/components/tasks/task-row-eyebrow";
import { TaskRowTime } from "@/components/tasks/task-time-chip";
import { InlineSubtasks } from "@/components/tasks/task-list";
import { TaskRowTrailingRail } from "@/components/tasks/task-row-trailing-rail";
import { SwipeableTaskRow } from "@/components/tasks/swipeable-task-row";
import { useTaskContextMenu } from "@/components/tasks/task-context-menu";
import { useWorkbench } from "@/components/shell/workbench-context";
import { useTaskRowLayout } from "@/lib/theme/use-task-row-layout";
import { showsTrailingTime } from "@/lib/theme/task-row-layout";
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
  const { expandedSubtasks, toggleSubtaskExpand, deferTask, deleteTask } = useWorkbench();
  const { menu, onContextMenu, onTouchStart, onTouchMove, onTouchEnd } = useTaskContextMenu();
  const layout = useTaskRowLayout();
  const subs = task.subtasks ?? [];
  const isExpanded = expandedSubtasks.has(task.id);
  const hasRail = subs.length > 0 || taskShowsWhatsAppCopy(task);
  const trailingTime = showsTrailingTime(layout);

  return (
    <>
      <SwipeableTaskRow
        onComplete={() => onToggleDone(task.id)}
        onDefer={() => void deferTask(task.id)}
        onDelete={() => void deleteTask(task.id)}
        allowOverflow={false}
      >
        <div
          role="button"
          tabIndex={0}
          data-task-id={task.id}
          onClick={() => onSelect(task.id)}
          onContextMenu={(e) => onContextMenu(task, e)}
          onTouchStart={(e) => onTouchStart(task, e)}
          onTouchMove={onTouchMove}
          onTouchEnd={onTouchEnd}
          onTouchCancel={onTouchEnd}
          onKeyDown={(e) => {
            if (e.key === "Enter" || e.key === " ") {
              e.preventDefault();
              onSelect(task.id);
            }
          }}
          className={`schedule-row task-row-grid scroll-list-item mb-0.5 min-h-[52px] cursor-pointer rounded-[var(--radius-md)] border px-2 py-2 transition-[background-color,border-color,opacity] duration-150 ${
            hasRail ? "" : "task-row-grid--no-rail "
          }${
            selected
              ? "border-[var(--color-border-strong)] bg-[var(--color-hover-overlay)]"
              : "border-transparent"
          } ${task.done ? "opacity-65" : ""}`}
          data-selected={selected ? "" : undefined}
          data-completing={task.done ? "true" : undefined}
        >
          <div className="reorder-gutter" aria-hidden />
          <DoneCircle
            done={task.done}
            priority={task.priority}
            label={task.done ? "Marcar pendente" : "Marcar concluída"}
            onClick={(e) => {
              e.stopPropagation();
              onToggleDone(task.id);
            }}
          />
          <div className="task-row-grid__content min-w-0 flex-1">
            <TaskRowEyebrow
              layout={layout}
              project={task.project}
              priority={task.priority}
            />
            <div className="flex items-baseline gap-1.5">
              <p
                className={`min-w-0 flex-1 truncate text-[15.5px] font-semibold leading-snug ${
                  task.done ? "text-[var(--color-text-tertiary)] line-through" : ""
                }`}
              >
                {task.title}
              </p>
              {trailingTime ? <TaskRowTime time={task.time} /> : null}
            </div>
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
          {hasRail ? (
            <TaskRowTrailingRail
              task={task}
              hasSubtasks={subs.length > 0}
              isExpanded={isExpanded}
              onToggleSubtasks={() => toggleSubtaskExpand(task.id)}
            />
          ) : null}
        </div>
      </SwipeableTaskRow>
      {subs.length > 0 && (
        <div className="expand-panel scroll-list-item" data-open={isExpanded ? "true" : "false"}>
          <div>
            <InlineSubtasks task={task} open={isExpanded} />
          </div>
        </div>
      )}
      {menu}
    </>
  );
});
