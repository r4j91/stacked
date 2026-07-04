"use client";

import { useState } from "react";
import { usePathname } from "next/navigation";
import { canvasTitles } from "@/lib/theme/tokens";
import { TaskList } from "@/components/tasks/task-list";
import { UpcomingCanvas } from "@/components/upcoming/upcoming-canvas";
import { FiltersCanvas } from "@/components/filters/filters-canvas";
import { ProjectTaskList } from "@/components/tasks/project-task-list";
import { SectionNameDialog } from "@/components/projects/section-name-dialog";
import { useWorkbench } from "@/components/shell/workbench-context";
import { formatTodaySubtitle } from "@/lib/utils/date";
import { ViewOptionsMenu } from "@/components/shell/view-options-menu";

export function CanvasArea() {
  const pathname = usePathname();
  const meta = canvasTitles[pathname] ?? canvasTitles["/today"];
  const { view, currentProject, todayStats, usingMock, createSection, loading, error, openPalette, openProjectEdit, isShowCompleted, toggleShowCompleted } =
    useWorkbench();
  const [showNewSection, setShowNewSection] = useState(false);

  const showCompleted = isShowCompleted();

  const subtitle =
    view === "project"
      ? currentProject
        ? `${currentProject.pendingCount} pendente${currentProject.pendingCount === 1 ? "" : "s"}`
        : undefined
      : pathname === "/today"
        ? formatTodaySubtitle()
        : meta.subtitle;

  const title = view === "project" ? (currentProject?.name ?? "Projeto") : meta.title;

  return (
    <main
      id="workbench-main-content"
      data-workbench-main
      tabIndex={-1}
      className="flex min-w-0 flex-1 flex-col overflow-hidden bg-[var(--color-bg)] outline-none"
    >
      <div className="mx-auto flex h-full w-full max-w-[var(--content-max-width)] min-w-0 flex-col px-4 lg:px-6">
        <header className="shrink-0 border-b border-[var(--color-border)] pb-4 pt-5">
          <div className="flex flex-wrap items-start justify-between gap-x-4 gap-y-3">
            <div className="min-w-0 flex-1 basis-[12rem]">
              <h1 className="type-screen-title truncate">{title}</h1>
              {subtitle && (
                <p className="mt-1 truncate text-[13px] text-[var(--color-text-secondary)]">{subtitle}</p>
              )}
            </div>
            <div className="flex max-w-full shrink-0 flex-wrap items-center justify-end gap-1.5 xl:gap-2">
              {(view === "today" || view === "inbox" || view === "project") && (
                <ViewOptionsMenu
                  showCompleted={showCompleted}
                  onToggleCompleted={() => toggleShowCompleted()}
                  extraItems={
                    view === "project" && currentProject
                      ? [{ label: "Editar projeto", onClick: () => openProjectEdit(currentProject.id) }]
                      : undefined
                  }
                />
              )}
              {view === "project" && (
                <button
                  type="button"
                  onClick={() => setShowNewSection(true)}
                  className="btn-secondary inline-flex items-center gap-1.5 rounded-[var(--radius-sm)] px-2.5 py-1.5 text-xs xl:px-3 xl:text-[13px]"
                >
                  Nova seção
                </button>
              )}
              <button
                type="button"
                onClick={openPalette}
                className="btn-secondary inline-flex shrink-0 items-center gap-1.5 rounded-[var(--radius-sm)] px-2.5 py-1.5 text-xs xl:px-3 xl:text-[13px]"
                title="Buscar (⌘K)"
                aria-label="Buscar (⌘K)"
              >
                Buscar
                <kbd className="ml-1 hidden rounded bg-[var(--color-surface)] px-1.5 py-0.5 text-[11px] font-medium text-[var(--color-text-secondary)] xl:inline">
                  ⌘K
                </kbd>
              </button>
            </div>
          </div>
          {view === "today" && (
            <div className="mt-4 flex flex-wrap items-center gap-1.5">
              <StatChip count={todayStats.overdue} label="atrasadas" dot="overdue" />
              <StatChip count={todayStats.today} label="para hoje" />
              <StatChip count={todayStats.completed} label="concluídas" muted />
              {usingMock && (
                <span className="rounded bg-[var(--color-surface-variant)] px-1.5 py-0.5 text-[10px] font-medium text-[var(--color-text-secondary)]">
                  mock
                </span>
              )}
            </div>
          )}
        </header>
        <div
          data-workbench-scroll
          className="scroll-hidden min-h-0 flex-1 overflow-y-auto pb-8 pt-1"
        >
          {view === "project" && !loading && !currentProject ? (
            <p className="px-4 py-12 text-center text-sm text-[var(--color-text-tertiary)]">
              {error ? "Não foi possível carregar este projeto." : "Projeto não encontrado."}
            </p>
          ) : view === "project" ? (
            <ProjectTaskList />
          ) : view === "upcoming" ? (
            <UpcomingCanvas />
          ) : view === "filters" ? (
            <FiltersCanvas />
          ) : (
            <TaskList />
          )}
        </div>
      </div>

      {showNewSection && (
        <SectionNameDialog
          title="Nova seção"
          submitLabel="Criar"
          onClose={() => setShowNewSection(false)}
          onSubmit={(name) => {
            void createSection(name);
            setShowNewSection(false);
          }}
        />
      )}
    </main>
  );
}

function StatChip({
  count,
  label,
  dot,
  muted,
}: {
  count: number;
  label: string;
  dot?: "overdue";
  muted?: boolean;
}) {
  return (
    <span className="inline-flex items-center gap-1.5 rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-[var(--color-surface)] px-2.5 py-1 text-xs text-[var(--color-text-secondary)]">
      <span
        className={`h-1.5 w-1.5 rounded-full ${
          dot === "overdue"
            ? "bg-[var(--color-overdue)]"
            : muted
              ? "bg-[var(--color-text-tertiary)]"
              : "bg-[var(--color-text-secondary)]"
        }`}
      />
      <strong
        className={`font-semibold tabular-nums ${dot === "overdue" ? "text-[var(--color-overdue)]" : "text-[var(--color-text)]"}`}
      >
        {count}
      </strong>
      {label}
    </span>
  );
}
