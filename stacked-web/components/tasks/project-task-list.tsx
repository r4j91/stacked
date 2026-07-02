"use client";

import { useState } from "react";
import type { Section } from "@/lib/types/project";
import { TaskRow, TaskListSkeleton } from "@/components/tasks/task-list";
import { useWorkbench } from "@/components/shell/workbench-context";
import { computeProjectListItems } from "@/lib/utils/project-list-items";
import { SectionNameDialog } from "@/components/projects/section-name-dialog";

function CollapsibleSectionHeader({
  section,
  count,
  expanded,
  onToggle,
  onMenu,
}: {
  section: Section;
  count: number;
  expanded: boolean;
  onToggle: () => void;
  onMenu: () => void;
}) {
  return (
    <div className="flex items-center gap-2 px-2 pb-2 pt-4">
      <button
        type="button"
        onClick={onToggle}
        className="flex min-w-0 flex-1 items-center gap-2 text-left"
      >
        <svg
          className={`h-3.5 w-3.5 shrink-0 text-[var(--color-text-tertiary)] transition-transform ${expanded ? "rotate-90" : ""}`}
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth={2}
        >
          <path d="m9 18 6-6-6-6" strokeLinecap="round" />
        </svg>
        <h2 className="truncate text-[13px] font-semibold text-[var(--color-text-secondary)]">
          {section.name}
        </h2>
        {count > 0 && (
          <span className="text-xs tabular-nums text-[var(--color-text-tertiary)]">{count}</span>
        )}
      </button>
      <button
        type="button"
        onClick={onMenu}
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
    isShowCompleted,
  } = useWorkbench();

  const [dialog, setDialog] = useState<
    | { mode: "rename"; section: Section }
    | null
  >(null);
  const [menuSection, setMenuSection] = useState<Section | null>(null);

  if (loading) return <TaskListSkeleton />;

  const items = computeProjectListItems({
    pending: viewTasks.pending,
    completed: viewTasks.completed,
    sections,
    collapsedSectionIds,
    completedExpanded: projectCompletedExpanded,
    showCompleted: isShowCompleted("project"),
  });

  if (!viewTasks.pending.length && !viewTasks.completed.length && !sections.length) {
    return (
      <p className="px-4 py-12 text-center text-sm text-[var(--color-text-tertiary)]">
        Nenhuma tarefa neste projeto.
      </p>
    );
  }

  return (
    <>
      {items.map((item, i) => {
        if (item.kind === "separator") {
          return <div key={`sep-${i}`} className="mx-2 my-1 h-px bg-[var(--color-border)]/60" />;
        }
        if (item.kind === "task" || item.kind === "completedTask") {
          return <TaskRow key={item.task.id} task={item.task} />;
        }
        if (item.kind === "sectionHeader") {
          const expanded = !collapsedSectionIds.has(item.section.id);
          return (
            <CollapsibleSectionHeader
              key={item.section.id}
              section={item.section}
              count={item.count}
              expanded={expanded}
              onToggle={() => toggleSectionCollapsed(item.section.id)}
              onMenu={() => setMenuSection(item.section)}
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

      {menuSection && (
        <div
          className="fixed inset-0 z-50 flex items-end justify-center bg-black/40 p-4 sm:items-center"
          onClick={() => setMenuSection(null)}
          role="presentation"
        >
          <div
            className="w-full max-w-xs overflow-hidden rounded-[var(--radius-md)] bg-[var(--color-surface-variant)] shadow-xl"
            onClick={(e) => e.stopPropagation()}
          >
            <button
              type="button"
              className="block w-full px-4 py-3 text-left text-sm text-[var(--color-text)] hover:bg-[var(--color-hover-overlay)]"
              onClick={() => {
                setDialog({ mode: "rename", section: menuSection });
                setMenuSection(null);
              }}
            >
              Renomear
            </button>
            <button
              type="button"
              className="block w-full px-4 py-3 text-left text-sm text-[var(--color-overdue)] hover:bg-[var(--color-hover-overlay)]"
              onClick={() => {
                void deleteSection(menuSection.id);
                setMenuSection(null);
              }}
            >
              Excluir seção
            </button>
            <button
              type="button"
              className="block w-full border-t border-[var(--color-border)] px-4 py-3 text-left text-sm text-[var(--color-text-secondary)] hover:bg-[var(--color-hover-overlay)]"
              onClick={() => setMenuSection(null)}
            >
              Cancelar
            </button>
          </div>
        </div>
      )}

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
