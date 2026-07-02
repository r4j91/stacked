"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { useWorkbench } from "./workbench-context";
import type { Task } from "@/lib/types/task";
import type { TaskFilterKind } from "@/lib/types/task";
import { navItems } from "@/lib/theme/tokens";
import { AppIcon } from "@/components/ui/app-icon";
import {
  Search01Icon,
  Add01Icon,
  Folder01Icon,
  FilterHorizontalIcon,
  TaskDone01Icon,
  Home01Icon,
  InboxIcon,
  Calendar03Icon,
  Sun01Icon,
} from "@/lib/icons/nav-icons";

type PaletteItem = {
  id: string;
  group: string;
  label: string;
  icon: React.ComponentProps<typeof AppIcon>["icon"];
  action: () => void;
};

const NAV_ICON_MAP: Record<string, typeof Home01Icon> = {
  home: Home01Icon,
  inbox: InboxIcon,
  today: Sun01Icon,
  upcoming: Calendar03Icon,
  filters: FilterHorizontalIcon,
  done: TaskDone01Icon,
};

function matchesQuery(task: Task, q: string): boolean {
  const hay = [task.title, task.preview, task.notes, task.project, task.tag]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();
  return hay.includes(q);
}

function HighlightMatch({ text, query }: { text: string; query: string }) {
  const q = query.trim();
  if (!q) return text;
  const lower = text.toLowerCase();
  const idx = lower.indexOf(q.toLowerCase());
  if (idx === -1) return text;
  return (
    <>
      {text.slice(0, idx)}
      <mark className="rounded bg-[var(--color-selected-bg)] px-0.5 text-[var(--color-selected-fg)]">
        {text.slice(idx, idx + q.length)}
      </mark>
      {text.slice(idx + q.length)}
    </>
  );
}

export function CommandPalette() {
  const router = useRouter();
  const {
    paletteOpen,
    closePalette,
    closeInspector,
    searchTasks,
    filterCounts,
    projects,
    openTaskInspector,
    openQuickAdd,
  } = useWorkbench();

  const [query, setQuery] = useState("");
  const [focusIndex, setFocusIndex] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);

  const go = useCallback(
    (path: string) => {
      closePalette();
      closeInspector();
      router.push(path);
    },
    [closePalette, closeInspector, router],
  );

  const items = useMemo(() => {
    const q = query.trim().toLowerCase();
    const list: PaletteItem[] = [];

    if (!q || "nova tarefa".includes(q) || "criar".includes(q)) {
      list.push({
        id: "action-new",
        group: "Ações",
        label: "Nova tarefa",
        icon: Add01Icon,
        action: () => {
          closePalette();
          openQuickAdd();
        },
      });
    }

    for (const nav of navItems) {
      const href = nav.href;
      const label = nav.label;
      if (!q || label.toLowerCase().includes(q) || href.includes(q)) {
        list.push({
          id: `nav-${nav.id}`,
          group: "Ir para",
          label,
          icon: NAV_ICON_MAP[nav.id] ?? Home01Icon,
          action: () => go(href),
        });
      }
    }

    for (const p of projects) {
      const label = `Projeto › ${p.name}`;
      if (!q || label.toLowerCase().includes(q) || p.name.toLowerCase().includes(q)) {
        list.push({
          id: `proj-${p.id}`,
          group: "Ir para",
          label,
          icon: Folder01Icon,
          action: () => go(`/projects/${p.id}`),
        });
      }
    }

    const filters: { kind: TaskFilterKind; label: string; count: number }[] = [
      { kind: "overdue", label: "Atrasadas", count: filterCounts.overdue },
      { kind: "today", label: "Hoje", count: filterCounts.today },
      { kind: "week", label: "Próximos 7 dias", count: filterCounts.week },
      { kind: "completedToday", label: "Concluídas hoje", count: filterCounts.completedToday },
    ];
    for (const f of filters) {
      const label = `${f.label} (${f.count})`;
      if (!q || label.toLowerCase().includes(q) || f.label.toLowerCase().includes(q)) {
        list.push({
          id: `filter-${f.kind}`,
          group: "Filtrar",
          label,
          icon: FilterHorizontalIcon,
          action: () => go(`/filters?kind=${f.kind}`),
        });
      }
    }

    for (const task of searchTasks) {
      if (!q || matchesQuery(task, q)) {
        list.push({
          id: `task-${task.id}`,
          group: "Tarefas",
          label: task.title,
          icon: TaskDone01Icon,
          action: () => {
            openTaskInspector(task);
            closePalette();
          },
        });
      }
    }

    return list.slice(0, 16);
  }, [query, projects, filterCounts, searchTasks, go, openTaskInspector, closePalette, openQuickAdd]);

  useEffect(() => {
    if (paletteOpen) {
      setQuery("");
      setFocusIndex(0);
      requestAnimationFrame(() => inputRef.current?.focus());
    }
  }, [paletteOpen]);

  useEffect(() => {
    setFocusIndex(0);
  }, [query]);

  useEffect(() => {
    if (!paletteOpen) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        e.preventDefault();
        e.stopPropagation();
        closePalette();
        return;
      }
      if (e.key === "ArrowDown") {
        e.preventDefault();
        setFocusIndex((i) => Math.min(i + 1, Math.max(0, items.length - 1)));
      }
      if (e.key === "ArrowUp") {
        e.preventDefault();
        setFocusIndex((i) => Math.max(i - 1, 0));
      }
      if (e.key === "Enter" && items[focusIndex]) {
        e.preventDefault();
        items[focusIndex].action();
      }
    };
    window.addEventListener("keydown", onKey, true);
    return () => window.removeEventListener("keydown", onKey, true);
  }, [paletteOpen, items, focusIndex, closePalette]);

  if (!paletteOpen) return null;

  return (
    <>
      <div
        className="fixed inset-0 z-[var(--z-command)] bg-black/50"
        onClick={closePalette}
        aria-hidden
      />
      <div
        className="fixed left-1/2 top-[12%] z-[calc(var(--z-command)+1)] w-[calc(100%-2rem)] max-w-[560px] -translate-x-1/2 overflow-hidden rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)]"
        role="dialog"
        aria-label="Busca rápida"
      >
        <div className="flex items-center gap-3 border-b border-[var(--color-border)] px-4 py-3">
          <AppIcon icon={Search01Icon} size={16} className="text-[var(--color-text-tertiary)]" />
          <input
            ref={inputRef}
            type="search"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Buscar tarefas, projetos, ações…"
            className="flex-1 bg-transparent text-sm outline-none placeholder:text-[var(--color-placeholder)]"
            autoComplete="off"
          />
        </div>
        <div className="hidden gap-3 border-b border-[var(--color-border)] px-4 py-2 text-[11px] text-[var(--color-text-secondary)] sm:flex">
          <span>↑↓ navegar</span>
          <span>↵ selecionar</span>
          <span>esc fechar</span>
        </div>
        <div className="max-h-[min(320px,50vh)] overflow-y-auto p-1.5">
          {!items.length ? (
            <p className="px-3 py-6 text-center text-sm text-[var(--color-text-secondary)]">
              Nenhum resultado.
            </p>
          ) : (
            items.map((item, idx) => (
              <button
                key={item.id}
                type="button"
                onClick={() => item.action()}
                onMouseEnter={() => setFocusIndex(idx)}
                className={`flex w-full items-center gap-3 rounded-[var(--radius-sm)] px-3 py-2.5 text-left transition-colors ${
                  idx === focusIndex ? "bg-[var(--color-surface-variant)]" : "hover:bg-[var(--color-surface-variant)]/60"
                }`}
              >
                <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-[var(--radius-sm)] bg-[var(--color-surface-variant)] text-[var(--color-text-tertiary)]">
                  <AppIcon icon={item.icon} size={18} />
                </span>
                <span className="min-w-0 flex-1">
                  <span className="block text-[11px] font-medium text-[var(--color-text-secondary)]">
                    {item.group}
                  </span>
                  <span className="block truncate text-sm font-medium">
                    <HighlightMatch text={item.label} query={query} />
                  </span>
                </span>
              </button>
            ))
          )}
        </div>
      </div>
    </>
  );
}
