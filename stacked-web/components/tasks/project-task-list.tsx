"use client";

import { useMemo, useState } from "react";
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
import { ListSectionHeader } from "@/components/tasks/list-section-header";

function CollapsibleSectionHeader({
  section,
  count,
  expanded,
  onToggle,
  onMenu,
  reorderDropProps,
  reorderHoldProps,
  reorderHandleProps,
  reorderDragOver,
  reorderDropPosition,
  reorderDragging,
}: {
  section: Section;
  count: number;
  expanded: boolean;
  onToggle: () => void;
  onMenu: (anchor: AnchorRect) => void;
  reorderDropProps?: Record<string, unknown>;
  reorderHoldProps?: Record<string, unknown>;
  reorderHandleProps?: Record<string, unknown>;
  reorderDragOver?: boolean;
  reorderDropPosition?: "before" | "after" | null;
  reorderDragging?: boolean;
}) {
  return (
    <ListSectionHeader
      title={section.name}
      count={count}
      expanded={expanded}
      onToggle={onToggle}
      onMenu={onMenu}
      dropSectionId={section.id}
      reorderDropProps={reorderDropProps}
      reorderHoldProps={reorderHoldProps}
      reorderHandleProps={reorderHandleProps}
      reorderDragOver={reorderDragOver}
      reorderDropPosition={reorderDropPosition}
      reorderDragging={reorderDragging}
    />
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

  const taskDrag = useHoldToReorder((from, to, kind, position) => {
    void reorderProjectTasks(from, to, kind, position);
  }, "task");
  const sectionDrag = useHoldToReorder((from, to, _kind, position) => {
    void reorderSections(from, to, position);
  }, "section");

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
    <div className="reorder-enabled-list project-task-list">
      {items.map((item, i) => {
        if (item.kind === "separator") {
          return <div key={`sep-${i}`} className="mx-2 my-1 h-px bg-[var(--color-border)]/60" />;
        }
        if (item.kind === "task") {
          const taskId = item.task.id;
          const isDropTarget =
            taskDrag.overId === taskId && taskDrag.overKind === "task" && taskDrag.draggingId !== taskId;
          return (
            <TaskRow
              key={taskId}
              task={item.task}
              keyboardFocused={focusedTaskId === taskId}
              reorderDropProps={taskDrag.getDropProps(taskId)}
              reorderHandleProps={taskDrag.getHandleProps(taskId, true)}
              reorderDragOver={isDropTarget}
              reorderDropPosition={isDropTarget ? taskDrag.overPosition : null}
              reorderDragging={taskDrag.draggingId === taskId}
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
          const sectionId = item.section.id;
          const isSectionDropTarget =
            (sectionDrag.overId === sectionId && sectionDrag.draggingId !== sectionId) ||
            (taskDrag.overId === sectionId && taskDrag.overKind === "section" && taskDrag.draggingId !== null);
          const dropPosition = taskDrag.overId === sectionId ? taskDrag.overPosition : sectionDrag.overPosition;
          return (
            <CollapsibleSectionHeader
              key={sectionId}
              section={item.section}
              count={item.count}
              expanded={expanded}
              reorderDropProps={sectionDrag.getDropProps(sectionId)}
              reorderHandleProps={sectionDrag.getHandleProps(sectionId, true)}
              reorderDragOver={isSectionDropTarget}
              reorderDropPosition={isSectionDropTarget ? dropPosition : null}
              reorderDragging={sectionDrag.draggingId === sectionId}
              onToggle={() => toggleSectionCollapsed(sectionId)}
              onMenu={(anchor) => {
                setMenuAnchor(anchor);
                setMenuSection(item.section);
              }}
            />
          );
        }
        return (
          <ListSectionHeader
            key="completed-header"
            title="Concluídas"
            count={item.count}
            expanded={projectCompletedExpanded}
            onToggle={toggleProjectCompletedExpanded}
          />
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
    </div>
  );
}
