"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { TaskRow, TaskListSkeleton } from "@/components/tasks/task-list";
import { SavedFilterBuilder } from "@/components/filters/saved-filter-builder";
import { FilterSubtaskRow } from "@/components/filters/filter-subtask-row";
import { ViewOptionsMenu } from "@/components/shell/view-options-menu";
import { ListSectionHeader } from "@/components/tasks/list-section-header";
import { useWorkbench } from "@/components/shell/workbench-context";
import { AppIcon } from "@/components/ui/app-icon";
import type { TaskFilterKind } from "@/lib/types/task";
import type { SavedFilter, SavedFilterWithCount } from "@/lib/types/saved-filter";
import type { Task } from "@/lib/types/task";
import type { FilterResultItem } from "@/lib/types/filter-result";
import { filterResultCountLabel, filterResultId } from "@/lib/types/filter-result";
import type { ProjectWithStats } from "@/lib/repositories/project-repository";
import { createClient } from "@/lib/supabase/client";
import { isSupabaseConfigured } from "@/lib/supabase/config";
import { TaskRepository } from "@/lib/repositories/task-repository";
import { ProjectRepository } from "@/lib/repositories/project-repository";
import { SavedFilterRepository } from "@/lib/repositories/saved-filter-repository";
import {
  mockFilterCounts,
  mockFilteredTasks,
  mockCreateSavedFilter,
  mockDeleteSavedFilter,
  mockPendingAndCompletedMatchingCriteria,
  mockProjectsAsSidebar,
  mockSavedFilterById,
  mockSavedFiltersWithCounts,
  mockUpdateSavedFilter,
  MOCK_LABELS,
} from "@/lib/data/mock-tasks";
import { criteriaSummary } from "@/lib/utils/filter-criteria";
import { ProjectIcon } from "@/components/ui/project-icon";
import { Add01Icon, ArrowRight01Icon, FilterHorizontalIcon } from "@/lib/icons/nav-icons";

const FILTER_LABELS: Record<TaskFilterKind, { title: string; color: string }> = {
  overdue: { title: "Atrasadas", color: "var(--color-overdue)" },
  today: { title: "Hoje", color: "var(--color-text)" },
  week: { title: "Próximos 7 dias", color: "var(--color-p3)" },
  completedToday: { title: "Concluídas hoje", color: "var(--color-done)" },
};

function isFilterKind(v: string | null): v is TaskFilterKind {
  return v === "overdue" || v === "today" || v === "week" || v === "completedToday";
}

export function FiltersCanvas() {
  const router = useRouter();
  const params = useSearchParams();
  const kindParam = params.get("kind");
  const savedParam = params.get("saved");
  const kind = isFilterKind(kindParam) ? kindParam : null;
  const {
    usingMock,
    labels,
    projects: workbenchProjects,
    isShowCompleted,
    toggleShowCompleted,
    refreshTasks,
  } = useWorkbench();

  const showCompleted = isShowCompleted("filters");

  const [loading, setLoading] = useState(true);
  const [counts, setCounts] = useState(mockFilterCounts());
  const [projects, setProjects] = useState<ProjectWithStats[]>([]);
  const [savedFilters, setSavedFilters] = useState<SavedFilterWithCount[]>([]);
  const [activeSavedFilter, setActiveSavedFilter] = useState<SavedFilter | null>(null);
  const [filterResults, setFilterResults] = useState<FilterResultItem[]>([]);
  const [completedFilterResults, setCompletedFilterResults] = useState<FilterResultItem[]>([]);
  const [presetFilterResults, setPresetFilterResults] = useState<FilterResultItem[]>([]);
  const [builderOpen, setBuilderOpen] = useState(false);
  const [editingFilter, setEditingFilter] = useState<SavedFilter | null>(null);

  const pickerLabels = labels.length ? labels : MOCK_LABELS;
  const pickerProjects = useMemo(
    () =>
      workbenchProjects.length
        ? workbenchProjects
        : mockProjectsAsSidebar().map((p) => ({
            id: p.id,
            name: p.name,
            color: p.color,
            icon: p.icon,
            pendingCount: p.count,
            totalCount: p.count,
          })),
    [workbenchProjects],
  );

  const loadDashboard = useCallback(async () => {
    setLoading(true);
    if (!isSupabaseConfigured() || usingMock) {
      setCounts(mockFilterCounts());
      setProjects(
        mockProjectsAsSidebar().map((p) => ({
          id: p.id,
          name: p.name,
          color: p.color,
          icon: p.icon,
          pendingCount: p.count,
          totalCount: p.count,
        })),
      );
      setSavedFilters(mockSavedFiltersWithCounts());
      setLoading(false);
      return;
    }
    try {
      const client = createClient();
      const [c, p, s] = await Promise.all([
        new TaskRepository(client).fetchFilterDashboardCounts(),
        new ProjectRepository(client).fetchProjectsWithTaskStats(),
        new SavedFilterRepository(client).fetchSavedFiltersWithCounts(),
      ]);
      setCounts(c);
      setProjects(p);
      setSavedFilters(s);
    } finally {
      setLoading(false);
    }
  }, [usingMock]);

  const loadPresetFilter = useCallback(async () => {
    if (!kind) return;
    setLoading(true);
    if (!isSupabaseConfigured() || usingMock) {
      setPresetFilterResults(
        mockFilteredTasks(kind).map((task) => ({ kind: "task" as const, task })),
      );
      setLoading(false);
      return;
    }
    try {
      const results = await new TaskRepository(createClient()).fetchPresetFilterResults(kind);
      setPresetFilterResults(results);
    } finally {
      setLoading(false);
    }
  }, [kind, usingMock]);

  const loadSavedFilter = useCallback(async () => {
    if (!savedParam) return;
    setLoading(true);
    if (!isSupabaseConfigured() || usingMock) {
      const filter = mockSavedFilterById(savedParam);
      if (!filter) {
        setActiveSavedFilter(null);
        setFilterResults([]);
        setCompletedFilterResults([]);
        setLoading(false);
        return;
      }
      setActiveSavedFilter(filter);
      const { pending, completed } = mockPendingAndCompletedMatchingCriteria(filter.criteria);
      setFilterResults(pending);
      setCompletedFilterResults(completed);
      setLoading(false);
      return;
    }
    try {
      const client = createClient();
      const filterRepo = new SavedFilterRepository(client);
      const filter = await filterRepo.fetchSavedFilterById(savedParam);
      if (!filter) {
        setActiveSavedFilter(null);
        setFilterResults([]);
        setCompletedFilterResults([]);
        return;
      }
      setActiveSavedFilter(filter);
      const { pending, completed } = await new TaskRepository(
        client,
      ).fetchPendingAndCompletedMatchingCriteria(filter.criteria);
      setFilterResults(pending);
      setCompletedFilterResults(completed);
    } finally {
      setLoading(false);
    }
  }, [savedParam, usingMock]);

  useEffect(() => {
    if (savedParam) void loadSavedFilter();
    else if (kind) void loadPresetFilter();
    else void loadDashboard();
  }, [savedParam, kind, loadDashboard, loadPresetFilter, loadSavedFilter]);

  async function handleCreateFilter(input: {
    name: string;
    color: string | null;
    criteria: SavedFilter["criteria"];
  }) {
    if (!isSupabaseConfigured() || usingMock) {
      mockCreateSavedFilter(input);
      await loadDashboard();
      return;
    }
    await new SavedFilterRepository(createClient()).createSavedFilter(input);
    await loadDashboard();
    await refreshTasks();
  }

  async function handleUpdateFilter(input: {
    name: string;
    color: string | null;
    criteria: SavedFilter["criteria"];
  }) {
    if (!editingFilter) return;
    if (!isSupabaseConfigured() || usingMock) {
      mockUpdateSavedFilter(editingFilter.id, input);
      await loadDashboard();
      if (savedParam === editingFilter.id) await loadSavedFilter();
      return;
    }
    await new SavedFilterRepository(createClient()).updateSavedFilter(editingFilter.id, input);
    await loadDashboard();
    if (savedParam === editingFilter.id) await loadSavedFilter();
    await refreshTasks();
  }

  async function handleDeleteFilter() {
    if (!activeSavedFilter) return;
    if (!isSupabaseConfigured() || usingMock) {
      mockDeleteSavedFilter(activeSavedFilter.id);
      router.push("/filters");
      await loadDashboard();
      return;
    }
    await new SavedFilterRepository(createClient()).deleteSavedFilter(activeSavedFilter.id);
    router.push("/filters");
    await loadDashboard();
    await refreshTasks();
  }

  if (loading) return <TaskListSkeleton />;

  if (savedParam && activeSavedFilter) {
    const tint = activeSavedFilter.color ?? "var(--color-accent)";
    return (
      <>
        <div className="mb-4 flex items-center gap-2 px-1">
          <button
            type="button"
            onClick={() => router.push("/filters")}
            className="flex h-9 w-9 shrink-0 items-center justify-center rounded-[var(--radius-sm)] bg-[var(--color-surface-variant)] text-[var(--color-text-secondary)] hover:text-[var(--color-text)]"
            aria-label="Voltar para filtros"
          >
            ‹
          </button>
          <div className="min-w-0 flex-1">
            <h2 className="truncate text-lg font-bold" style={{ color: tint }}>
              {activeSavedFilter.name}
            </h2>
            <p className="text-sm text-[var(--color-text-secondary)]">
              {filterResultCountLabel(filterResults.length)}
            </p>
          </div>
          <ViewOptionsMenu
            showCompleted={showCompleted}
            onToggleCompleted={() => toggleShowCompleted("filters")}
            extraItems={[
              {
                label: "Editar filtro",
                onClick: () => {
                  setEditingFilter(activeSavedFilter);
                  setBuilderOpen(true);
                },
              },
              {
                label: "Excluir filtro",
                onClick: () => void handleDeleteFilter(),
              },
            ]}
          />
        </div>

        <div className="filter-result-list">
          {filterResults.map((item) =>
            item.kind === "task" ? (
              <TaskRow key={filterResultId(item)} task={item.task} embedded />
            ) : (
              <FilterSubtaskRow
                key={filterResultId(item)}
                subtask={item.subtask}
                parent={item.parent}
                subtaskIndex={item.subtaskIndex}
              />
            ),
          )}

          {showCompleted && completedFilterResults.length > 0 && (
            <>
              <ListSectionHeader title="Concluídas" count={completedFilterResults.length} />
              {completedFilterResults.map((item) =>
                item.kind === "task" ? (
                  <TaskRow key={filterResultId(item)} task={item.task} embedded />
                ) : (
                  <FilterSubtaskRow
                    key={filterResultId(item)}
                    subtask={item.subtask}
                    parent={item.parent}
                    subtaskIndex={item.subtaskIndex}
                  />
                ),
              )}
            </>
          )}
        </div>

        {!filterResults.length && (!showCompleted || !completedFilterResults.length) && (
          <p className="px-4 py-8 text-center text-sm text-[var(--color-text-tertiary)]">
            Nenhum item neste filtro.
          </p>
        )}

        <SavedFilterBuilder
          open={builderOpen}
          onClose={() => {
            setBuilderOpen(false);
            setEditingFilter(null);
          }}
          labels={pickerLabels}
          projects={pickerProjects}
          initial={editingFilter}
          onSave={editingFilter ? handleUpdateFilter : handleCreateFilter}
        />
      </>
    );
  }

  if (kind) {
    const meta = FILTER_LABELS[kind];
    return (
      <>
        <button
          type="button"
          onClick={() => router.push("/filters")}
          className="mb-3 flex items-center gap-1 px-2 text-sm text-[var(--color-text-secondary)] hover:text-[var(--color-text)]"
        >
          ‹ Filtros
        </button>
        <div className="mb-4 flex items-center gap-2 px-2">
          <span className="h-2 w-2 rounded-full" style={{ background: meta.color }} />
          <h2 className="text-lg font-bold">{meta.title}</h2>
          <span className="text-sm tabular-nums text-[var(--color-text-tertiary)]">
            {presetFilterResults.length}
          </span>
        </div>
        <div className="filter-result-list">
          {presetFilterResults.map((item) =>
            item.kind === "task" ? (
              <TaskRow key={filterResultId(item)} task={item.task} embedded />
            ) : (
              <FilterSubtaskRow
                key={filterResultId(item)}
                subtask={item.subtask}
                parent={item.parent}
                subtaskIndex={item.subtaskIndex}
              />
            ),
          )}
        </div>
        {!presetFilterResults.length && (
          <p className="px-4 py-8 text-center text-sm text-[var(--color-text-tertiary)]">
            Nenhum item neste filtro.
          </p>
        )}
      </>
    );
  }

  const cards: { kind: TaskFilterKind; count: number }[] = [
    { kind: "overdue", count: counts.overdue },
    { kind: "today", count: counts.today },
    { kind: "week", count: counts.week },
    { kind: "completedToday", count: counts.completedToday },
  ];

  return (
    <>
      <div className="grid grid-cols-2 gap-2 px-1">
        {cards.map(({ kind: k, count }) => {
          const meta = FILTER_LABELS[k];
          return (
            <button
              key={k}
              type="button"
              onClick={() => router.push(`/filters?kind=${k}`)}
              className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] p-4 text-left transition-colors hover:bg-[var(--color-surface-variant)]"
            >
              <span className="mb-2 inline-block h-2 w-2 rounded-full" style={{ background: meta.color }} />
              <p className="text-2xl font-extrabold tabular-nums">{count}</p>
              <p className="mt-0.5 text-xs text-[var(--color-text-secondary)]">{meta.title}</p>
            </button>
          );
        })}
      </div>

      <section className="mt-6">
        <div className="flex items-center justify-between px-1 pb-2">
          <h2 className="text-xs font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)]">
            Meus filtros
          </h2>
          <button
            type="button"
            onClick={() => {
              setEditingFilter(null);
              setBuilderOpen(true);
            }}
            className="flex h-7 w-7 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-accent)] hover:bg-[var(--color-surface-variant)]"
            aria-label="Novo filtro"
          >
            <AppIcon icon={Add01Icon} size={16} />
          </button>
        </div>

        {savedFilters.length === 0 ? (
          <p className="px-1 pb-3 text-xs text-[var(--color-text-tertiary)]">
            Crie filtros para ver tarefas por etiqueta ou prioridade.
          </p>
        ) : (
          savedFilters.map((item) => (
            <button
              key={item.id}
              type="button"
              onClick={() => router.push(`/filters?saved=${item.id}`)}
              className="mb-0.5 flex w-full items-center gap-3 rounded-[var(--radius-sm)] px-2.5 py-3 text-left hover:bg-[var(--color-surface)]"
            >
              <span
                className="flex h-7 w-7 shrink-0 items-center justify-center"
                style={{ color: item.color ?? "var(--color-accent)" }}
              >
                <AppIcon icon={FilterHorizontalIcon} size={22} strokeWidth={1.75} />
              </span>
              <span className="min-w-0 flex-1">
                <span className="block truncate text-[15px] font-semibold text-[var(--color-text)]">
                  {item.name}
                </span>
                <span className="block truncate text-xs text-[var(--color-text-tertiary)]">
                  {criteriaSummary(item.criteria, pickerLabels, pickerProjects)}
                </span>
              </span>
              <span className="shrink-0 text-xs tabular-nums text-[var(--color-text-tertiary)]">
                {item.pendingCount}
              </span>
              <AppIcon
                icon={ArrowRight01Icon}
                size={14}
                className="shrink-0 text-[var(--color-text-tertiary)]/70"
              />
            </button>
          ))
        )}
      </section>

      {projects.length > 0 && (
        <section className="mt-6">
          <h2 className="px-1 pb-2 text-xs font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)]">
            Projetos
          </h2>
          {projects.map((p) => (
            <Link
              key={p.id}
              href={`/projects/${p.id}`}
              className="mb-0.5 flex items-center gap-2.5 rounded-[var(--radius-sm)] px-2.5 py-2.5 text-[var(--color-text-secondary)] hover:bg-[var(--color-surface)] hover:text-[var(--color-text)]"
            >
              <ProjectIcon iconKey={p.icon} color={p.color} size={18} />
              <span className="flex-1 truncate font-medium">{p.name}</span>
              <span className="text-xs tabular-nums text-[var(--color-text-tertiary)]">
                {p.pendingCount}/{p.totalCount}
              </span>
            </Link>
          ))}
        </section>
      )}

      <SavedFilterBuilder
        open={builderOpen}
        onClose={() => {
          setBuilderOpen(false);
          setEditingFilter(null);
        }}
        labels={pickerLabels}
        projects={pickerProjects}
        initial={editingFilter}
        onSave={editingFilter ? handleUpdateFilter : handleCreateFilter}
      />
    </>
  );
}
