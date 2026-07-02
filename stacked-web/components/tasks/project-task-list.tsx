"use client";

import { useEffect, useMemo, useState } from "react";
import type { Section } from "@/lib/types/project";
import { TaskRow, TaskListSkeleton } from "@/components/tasks/task-list";
import { useWorkbench } from "@/components/shell/workbench-context";
import { computeProjectListItems } from "@/lib/utils/project-list-items";
import { SectionNameDialog } from "@/components/projects/section-name-dialog";
import { AnchoredPopover, type AnchorRect } from "@/components/ui/anchored-popover";
import { EmptyState } from "@/components/ui/empty-state";
import { useTaskListKeyboard } from "@/lib/hooks/use-task-list-keyboard";
import { useHoldToReorder } from "@/lib/hooks/use-hold-to-reorder";
import { Add01Icon } from "@/lib/icons/nav-icons";

function CollapsibleSectionHeader({
  section,
  count,
  expanded,
  onToggle,
  onMenu,
  reorderRowProps,
  reorderHolding,
  reorderDragOver,
  reorderDragging,
}: {
  section: Section;
  count: number;
  expanded: boolean;
  onToggle: () => void;
  onMenu: (anchor: AnchorRect) => void;
  reorderRowProps?: Record<string, unknown>;
  reorderHolding?: boolean;
  reorderDragOver?: boolean;
  reorderDragging?: boolean;
}) {
  return (
    <div
      {...(reorderRowProps ?? {})}
      data-task-drop-section={section.id}
      className={`flex items-center gap-2 px-2 pb-2 pt-4 ${
        reorderDragging
          ? "reorder-dragging rounded-[var(--radius-sm)]"
          : reorderHolding
            ? "reorder-holding rounded-[var(--radius-sm)]"
            : reorderDragOver
              ? "reorder-drop-target rounded-[var(--radius-sm)]"
              : ""
      }`}
      data-reorder-dragging={reorderDragging ? "" : undefined}
    >
      <button
        type="button"
        data-no-reorder
        onClick={onToggle}
        className="flex h-7 w-7 shrink-0 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-tertiary)] hover:bg-[var(--color-surface-variant)] hover:text-[var(--color-text-secondary)]"
        aria-expanded={expanded}
        aria-label={expanded ? "Recolher seção" : "Expandir seção"}
      >
        <svg
          className={`h-3.5 w-3.5 transition-transform ${expanded ? "rotate-90" : ""}`}
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth={2}
        >
          <path d="m9 18 6-6-6-6" strokeLinecap="round" />
        </svg>
      </button>
      <div className="flex min-w-0 flex-1 items-center gap-2">
        <h2 className="truncate text-[13px] font-semibold text-[var(--color-text-secondary)]">
          {section.name}
        </h2>
        {count > 0 && (
          <span className="text-xs tabular-nums text-[var(--color-text-tertiary)]">{count}</span>
        )}
      </div>
      <button
        type="button"
        data-no-reorder
        onClick={(e) => onMenu(e.currentTarget.getBoundingClientRect())}
        className="flex h-7 w-7 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-tertiary)] hover:bg-[var(--color-surface-variant)] hover:text-[var(--color-text-secondary)]"
        aria-label={`Opções da seção ${section.name}`}
      >
        ···
      </button>
    </div>
  );
}

export function ProjectTaskList() {
  const {
    loading,
    viewTasks,
    sections,
    collapsedSectionIds,
    projectCompletedExpanded,
    toggleSectionCollapsed,
    toggleProjectCompletedExpanded,
    renameSection,
    deleteSection,
    reorderProjectTasks,
    reorderSections,
    isShowCompleted,
    currentProject,
    openQuickAdd,
  } = useWorkbench();

  const [dialog, setDialog] = useState<{ mode: "rename"; section: Section } | null>(null);
  const [menuSection, setMenuSection] = useState<Section | null>(null);
  const [menuAnchor, setMenuAnchor] = useState<AnchorRect | null>(null);

  const taskDrag = useHoldToReorder((from, to, kind) => {
    void reorderProjectTasks(from, to, kind);
  }, "task");
  const sectionDrag = useHoldToReorder((from, to) => {
    void reorderSections(from, to);
  }, "section");

  const taskDragActive = Boolean(taskDrag.holdingId || taskDrag.draggingId);

  const isReordering = Boolean(
    taskDragActive ||
      sectionDrag.holdingId ||
      sectionDrag.draggingId,
  );

  useEffect(() => {
    if (isReordering) {
      document.documentElement.dataset.reorderActive = "";
    } else {
      delete document.documentElement.dataset.reorderActive;
    }
    return () => {
      delete document.documentElement.dataset.reorderActive;
    };
  }, [isReordering]);

  const items = useMemo(
    () =>
      computeProjectListItems({
        pending: viewTasks.pending,
        completed: viewTasks.completed,
        sections,
        collapsedSectionIds,
        completedExpanded: projectCompletedExpanded,
        showCompleted: isShowCompleted("project"),
      }),
    [
      viewTasks.pending,
      viewTasks.completed,
      sections,
      collapsedSectionIds,
      projectCompletedExpanded,
      isShowCompleted,
    ],
  );

  const visibleTaskIds = useMemo(
    () =>
      items
        .filter((item) => item.kind === "task" || item.kind === "completedTask")
        .map((item) => item.task.id),
    [items],
  );

  const { focusedTaskId } = useTaskListKeyboard(visibleTaskIds, currentProject?.id);

  if (loading) return <TaskListSkeleton />;

  if (!viewTasks.pending.length && !viewTasks.completed.length && !sections.length) {
    return (
      <EmptyState
        icon={Add01Icon}
        title="Nenhuma tarefa neste projeto"
        subtitle="Adicione a primeira tarefa ou crie uma seção para organizar."
        action={{
          label: "Nova tarefa",
          onClick: () => openQuickAdd({ projectId: currentProject?.id ?? null }),
        }}
      />
    );
  }

  return (
    <>
      {items.map((item, i) => {
        if (item.kind === "separator") {
          return <div key={`sep-${i}`} className="mx-2 my-1 h-px bg-[var(--color-border)]/60" />;
        }
        if (item.kind === "task") {
          return (
            <TaskRow
              key={item.task.id}
              task={item.task}
              keyboardFocused={focusedTaskId === item.task.id}
              reorderRowProps={taskDrag.getProps(item.task.id, true)}
              reorderHolding={taskDrag.holdingId === item.task.id}
              reorderDragOver={
                taskDrag.overId === item.task.id &&
                taskDrag.overKind === "task" &&
                taskDrag.draggingId !== item.task.id
              }
              reorderDragging={taskDrag.draggingId === item.task.id}
              onReorderConsumeClick={taskDrag.consumeClick}
            />
          );
        }
        if (item.kind === "completedTask") {
          return (
            <TaskRow key={item.task.id} task={item.task} keyboardFocused={focusedTaskId === item.task.id} />
          );
        }
        if (item.kind === "sectionHeader") {
          const expanded = !collapsedSectionIds.has(item.section.id);
          return (
            <CollapsibleSectionHeader
              key={item.section.id}
              section={item.section}
              count={item.count}
              expanded={expanded}
              reorderRowProps={sectionDrag.getProps(item.section.id, true)}
              reorderHolding={sectionDrag.holdingId === item.section.id}
              reorderDragOver={
                (sectionDrag.overId === item.section.id && sectionDrag.draggingId !== item.section.id) ||
                (taskDrag.overId === item.section.id &&
                  taskDrag.overKind === "section" &&
                  taskDrag.draggingId !== null)
              }
              reorderDragging={sectionDrag.draggingId === item.section.id}
              onToggle={() => toggleSectionCollapsed(item.section.id)}
              onMenu={(anchor) => {
                setMenuAnchor(anchor);
                setMenuSection(item.section);
              }}
            />
          );
        }
        return (
          <button
            key="completed-header"
            type="button"
            onClick={toggleProjectCompletedExpanded}
            className="flex w-full items-center gap-2 px-2 pb-2 pt-4 text-left"
          >
            <svg
              className={`h-3.5 w-3.5 text-[var(--color-text-tertiary)] transition-transform ${projectCompletedExpanded ? "rotate-90" : ""}`}
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth={2}
            >
              <path d="m9 18 6-6-6-6" strokeLinecap="round" />
            </svg>
            <h2 className="text-[13px] font-semibold text-[var(--color-text-secondary)]">
              Concluídas
            </h2>
            <span className="text-xs tabular-nums text-[var(--color-text-tertiary)]">{item.count}</span>
          </button>
        );
      })}

      <AnchoredPopover
        open={Boolean(menuSection && menuAnchor)}
        onClose={() => {
          setMenuSection(null);
          setMenuAnchor(null);
        }}
        anchorRect={menuAnchor}
        width={220}
        placement="below"
        className="overflow-hidden p-1"
      >
        {menuSection && (
          <>
            <button
              type="button"
              className="block w-full rounded-[var(--radius-sm)] px-3 py-2 text-left text-sm text-[var(--color-text)] hover:bg-[var(--color-hover-overlay)]"
              onClick={() => {
                setDialog({ mode: "rename", section: menuSection });
                setMenuSection(null);
                setMenuAnchor(null);
              }}
            >
              Renomear
            </button>
            <button
              type="button"
              className="block w-full rounded-[var(--radius-sm)] px-3 py-2 text-left text-sm text-[var(--color-overdue)] hover:bg-[var(--color-overdue)]/10"
              onClick={() => {
                void deleteSection(menuSection.id);
                setMenuSection(null);
                setMenuAnchor(null);
              }}
            >
              Excluir seção
            </button>
          </>
        )}
      </AnchoredPopover>

      {dialog?.mode === "rename" && (
        <SectionNameDialog
          title="Renomear seção"
          initialValue={dialog.section.name}
          onClose={() => setDialog(null)}
          onSubmit={(name) => {
            void renameSection(dialog.section.id, name);
            setDialog(null);
          }}
        />
      )}
    </>
  );
}
