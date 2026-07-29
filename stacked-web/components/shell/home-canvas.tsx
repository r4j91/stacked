"use client";

import Link from "next/link";
import { useCallback, useState } from "react";
import { useWorkbench } from "@/components/shell/workbench-context";
import { HomeDayRail } from "@/components/shell/home-day-rail";
import { AppIcon } from "@/components/ui/app-icon";
import { ProjectIcon } from "@/components/ui/project-icon";
import { ReorderDragHandle } from "@/components/tasks/reorder-drag-handle";
import { applyLabelReorder, useLabelListReorder } from "@/lib/hooks/use-label-list-reorder";
import {
  Home01Icon,
  InboxIcon,
  Calendar03Icon,
  TaskDone01Icon,
  Sun01Icon,
  ArrowRight01Icon,
  Notification01Icon,
} from "@/lib/icons/nav-icons";

export function HomeCanvas() {
  const { navCounts, filterCounts, projects, prefetchProject, reorderProjects } = useWorkbench();
  const [organizing, setOrganizing] = useState(false);

  const handleReorder = useCallback(
    (draggedId: string, targetId: string, position: "before" | "after") => {
      const next = applyLabelReorder(
        projects.map((p) => p.id),
        draggedId,
        targetId,
        position,
      );
      void reorderProjects(next);
    },
    [projects, reorderProjects],
  );

  const projectDrag = useLabelListReorder(handleReorder);

  return (
    <main
      id="workbench-main-content"
      data-workbench-main
      tabIndex={-1}
      className="flex min-w-0 flex-1 flex-col overflow-hidden bg-[var(--color-bg)] outline-none"
    >
      <div className="mx-auto flex h-full w-full max-w-[var(--content-max-width)] min-w-0 flex-col px-4 lg:px-6">
        <HomeDayRail />

        <div className="scroll-hidden min-h-0 flex-1 overflow-y-auto pb-4 pt-4 lg:pb-8">
          {filterCounts.overdue > 0 && (
            <Link
              href="/filters?kind=overdue"
              className="mb-4 flex items-center gap-3 rounded-[var(--radius-md)] border border-[var(--color-overdue)]/30 bg-[var(--color-overdue)]/10 px-4 py-3 text-sm hover:bg-[var(--color-overdue)]/15"
            >
              <AppIcon icon={Notification01Icon} size={20} className="text-[var(--color-overdue)]" />
              <span className="flex-1 font-medium text-[var(--color-overdue)]">
                {filterCounts.overdue} tarefa{filterCounts.overdue === 1 ? "" : "s"} atrasada
                {filterCounts.overdue === 1 ? "" : "s"}
              </span>
              <AppIcon icon={ArrowRight01Icon} size={16} className="text-[var(--color-overdue)]" />
            </Link>
          )}

          <section className="mb-6">
            <h2 className="mb-2 px-1 text-xs font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)]">
              Acesso rápido
            </h2>
            <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
              <QuickLink
                href="/inbox"
                icon={InboxIcon}
                label="Inbox"
                count={navCounts.inbox}
              />
              <QuickLink
                href="/today"
                icon={Sun01Icon}
                label="Hoje"
                count={navCounts.today}
              />
              <QuickLink
                href="/upcoming"
                icon={Calendar03Icon}
                label="Em breve"
                count={filterCounts.week}
              />
              <QuickLink
                href="/done"
                icon={TaskDone01Icon}
                label="Concluídas"
              />
            </div>
          </section>

          <section>
            <div className="mb-2 flex items-center gap-2 px-1">
              <h2 className="flex-1 text-xs font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)]">
                Projetos
              </h2>
              {projects.length >= 2 && (
                <button
                  type="button"
                  onClick={() => setOrganizing((v) => !v)}
                  className="text-xs font-semibold text-[var(--color-accent)] hover:opacity-80"
                >
                  {organizing ? "Concluir" : "Editar"}
                </button>
              )}
            </div>
            {projects.length === 0 ? (
              <p className="px-1 py-4 text-sm text-[var(--color-text-tertiary)]">
                Nenhum projeto ainda.
              </p>
            ) : (
              <ul className="flex flex-col gap-0.5">
                {projects.map((p) => {
                  const isDropTarget = projectDrag.overId === p.id;
                  const isDragging = projectDrag.draggingId === p.id;
                  const rowClass = `flex items-center gap-2.5 rounded-[var(--radius-sm)] px-2.5 py-2.5 text-[var(--color-text-secondary)] ${
                    organizing
                      ? "hover:bg-[var(--color-surface)]"
                      : "hover:bg-[var(--color-surface)] hover:text-[var(--color-text)]"
                  } ${
                    isDropTarget
                      ? projectDrag.overPosition === "after"
                        ? "border-b-2 border-[var(--color-accent)]"
                        : "border-t-2 border-[var(--color-accent)]"
                      : ""
                  } ${isDragging ? "opacity-40" : ""}`;

                  if (organizing) {
                    return (
                      <li
                        key={p.id}
                        data-reorder-item
                        {...projectDrag.getDropProps(p.id)}
                        className={`group/reorder-row ${rowClass}`}
                      >
                        <ReorderDragHandle
                          dragProps={projectDrag.getHandleProps(p.id)}
                          label={`Reordenar ${p.name}`}
                          alwaysVisible
                        />
                        <ProjectIcon iconKey={p.icon} color={p.color} size={20} />
                        <span className="flex-1 truncate font-medium text-[var(--color-text)]">
                          {p.name}
                        </span>
                        {p.pendingCount > 0 && (
                          <span className="text-xs tabular-nums text-[var(--color-text-tertiary)]">
                            {p.pendingCount}
                          </span>
                        )}
                      </li>
                    );
                  }

                  return (
                    <li key={p.id}>
                      <Link
                        href={`/projects/${p.id}`}
                        onMouseEnter={() => prefetchProject(p.id)}
                        onFocus={() => prefetchProject(p.id)}
                        onPointerEnter={() => prefetchProject(p.id)}
                        onTouchStart={() => prefetchProject(p.id)}
                        className={rowClass}
                      >
                        <ProjectIcon iconKey={p.icon} color={p.color} size={20} />
                        <span className="flex-1 truncate font-medium">{p.name}</span>
                        {p.pendingCount > 0 && (
                          <span className="text-xs tabular-nums text-[var(--color-text-tertiary)]">
                            {p.pendingCount}
                          </span>
                        )}
                        <AppIcon icon={ArrowRight01Icon} size={14} className="opacity-40" />
                      </Link>
                    </li>
                  );
                })}
              </ul>
            )}
          </section>
        </div>
      </div>
    </main>
  );
}

function QuickLink({
  href,
  icon,
  label,
  count,
}: {
  href: string;
  icon: typeof Home01Icon;
  label: string;
  count?: number;
}) {
  return (
    <Link
      href={href}
      className="flex items-center gap-3 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] px-4 py-3 hover:bg-[var(--color-surface-variant)]"
    >
      <AppIcon icon={icon} size={20} className="text-[var(--color-text-secondary)]" />
      <span className="flex-1 font-semibold">{label}</span>
      {!!count && count > 0 && (
        <span className="rounded-full bg-[var(--color-surface-variant)] px-2 py-0.5 text-xs font-semibold tabular-nums">
          {count}
        </span>
      )}
    </Link>
  );
}
