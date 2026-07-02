"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { TaskRow, TaskListSkeleton } from "@/components/tasks/task-list";
import { useWorkbench } from "@/components/shell/workbench-context";
import type { TaskFilterKind } from "@/lib/types/task";
import type { ProjectWithStats } from "@/lib/repositories/project-repository";
import { createClient } from "@/lib/supabase/client";
import { isSupabaseConfigured } from "@/lib/supabase/config";
import { TaskRepository } from "@/lib/repositories/task-repository";
import { ProjectRepository } from "@/lib/repositories/project-repository";
import { mockFilterCounts, mockFilteredTasks, mockProjectsAsSidebar } from "@/lib/data/mock-tasks";

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
  const kind = isFilterKind(kindParam) ? kindParam : null;
  const { usingMock } = useWorkbench();

  const [loading, setLoading] = useState(true);
  const [counts, setCounts] = useState(mockFilterCounts());
  const [projects, setProjects] = useState<ProjectWithStats[]>([]);
  const [filterTasks, setFilterTasks] = useState<import("@/lib/types/task").Task[]>([]);

  const loadDashboard = useCallback(async () => {
    setLoading(true);
    if (!isSupabaseConfigured() || usingMock) {
      setCounts(mockFilterCounts());
      setProjects(
        mockProjectsAsSidebar().map((p) => ({
          id: p.id,
          name: p.name,
          color: p.color,
          pendingCount: p.count,
          totalCount: p.count,
        })),
      );
      setLoading(false);
      return;
    }
    try {
      const client = createClient();
      const [c, p] = await Promise.all([
        new TaskRepository(client).fetchFilterDashboardCounts(),
        new ProjectRepository(client).fetchProjectsWithTaskStats(),
      ]);
      setCounts(c);
      setProjects(p);
    } finally {
      setLoading(false);
    }
  }, [usingMock]);

  const loadFilter = useCallback(async () => {
    if (!kind) return;
    setLoading(true);
    if (!isSupabaseConfigured() || usingMock) {
      setFilterTasks(mockFilteredTasks(kind));
      setLoading(false);
      return;
    }
    try {
      const tasks = await new TaskRepository(createClient()).fetchFilteredTasks(kind);
      setFilterTasks(tasks);
    } finally {
      setLoading(false);
    }
  }, [kind, usingMock]);

  useEffect(() => {
    if (kind) void loadFilter();
    else void loadDashboard();
  }, [kind, loadDashboard, loadFilter]);

  if (loading) return <TaskListSkeleton />;

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
            {filterTasks.length}
          </span>
        </div>
        {filterTasks.map((t) => (
          <TaskRow key={t.id} task={t} />
        ))}
        {!filterTasks.length && (
          <p className="px-4 py-8 text-center text-sm text-[var(--color-text-tertiary)]">
            Nenhuma tarefa neste filtro.
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

      {projects.length > 0 && (
        <section className="mt-6">
          <h2 className="px-2 pb-2 text-[13px] font-semibold text-[var(--color-text-secondary)]">
            Projetos
          </h2>
          {projects.map((p) => (
            <Link
              key={p.id}
              href={`/projects/${p.id}`}
              className="mb-0.5 flex items-center gap-2.5 rounded-[var(--radius-sm)] px-2.5 py-2.5 text-[var(--color-text-secondary)] hover:bg-[var(--color-surface)] hover:text-[var(--color-text)]"
            >
              <span className="h-2 w-2 shrink-0 rounded-full" style={{ background: p.color }} />
              <span className="flex-1 truncate font-medium">{p.name}</span>
              <span className="text-xs tabular-nums text-[var(--color-text-tertiary)]">
                {p.pendingCount}/{p.totalCount}
              </span>
            </Link>
          ))}
        </section>
      )}
    </>
  );
}
