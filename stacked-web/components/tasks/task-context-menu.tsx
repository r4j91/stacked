"use client";

import { useEffect, useLayoutEffect, useRef, useState, type MouseEvent } from "react";
import type { Section } from "@/lib/types/project";
import type { Task, Priority } from "@/lib/types/task";
import { useWorkbench } from "@/components/shell/workbench-context";
import { AppIcon } from "@/components/ui/app-icon";
import { ProjectIcon } from "@/components/ui/project-icon";
import {
  Edit01Icon,
  Tick01Icon,
  Clock01Icon,
  Copy01Icon,
  Delete01Icon,
  Flag01Icon,
  Folder01Icon,
  ArrowRight01Icon,
  Tag01Icon,
  InboxIcon,
} from "@/lib/icons/nav-icons";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { ClientPortal } from "@/components/ui/client-portal";

type TaskContextMenuProps = {
  task: Task;
  x: number;
  y: number;
  onClose: () => void;
};

type Submenu = "priority" | "project" | "labels";

type SectionFlyout = {
  projectId: string;
  projectName: string;
  top: number;
  sections: Section[];
};

export function TaskContextMenu({ task, x, y, onClose }: TaskContextMenuProps) {
  const {
    projects,
    selectTask,
    toggleTaskDone,
    deferTask,
    duplicateTask,
    deleteTask,
    updateTaskPriority,
    updateTaskProjectAndSection,
    updateTaskLabels,
    getProjectSections,
    labels,
  } = useWorkbench();
  const menuRef = useRef<HTMLDivElement>(null);
  const flyoutRef = useRef<HTMLDivElement>(null);
  const sectionFlyoutRef = useRef<HTMLDivElement>(null);
  const [submenu, setSubmenu] = useState<Submenu | null>(null);
  const [sectionFlyout, setSectionFlyout] = useState<SectionFlyout | null>(null);
  const [flyoutTop, setFlyoutTop] = useState(0);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [position, setPosition] = useState({ top: y, left: x });
  const [loadingProjectId, setLoadingProjectId] = useState<string | null>(null);

  useLayoutEffect(() => {
    const el = menuRef.current;
    if (!el) return;

    function place() {
      const menu = menuRef.current;
      if (!menu) return;
      const rect = menu.getBoundingClientRect();
      const flyoutW = submenu ? flyoutRef.current?.getBoundingClientRect().width ?? 200 : 0;
      const sectionW = sectionFlyout
        ? sectionFlyoutRef.current?.getBoundingClientRect().width ?? 200
        : 0;
      const pad = 12;
      const gap = 4;
      const vh = window.innerHeight;
      const vw = window.innerWidth;
      const totalW = rect.width + (flyoutW || 0) + (sectionW || 0) + (flyoutW || sectionW ? 16 : 0);

      let top = y;
      let left = x;

      // Prefere abrir abaixo do cursor; se não couber, abre para cima (ancorado no cursor).
      const spaceBelow = vh - pad - y;
      const spaceAbove = y - pad;
      if (rect.height + gap > spaceBelow && spaceAbove > spaceBelow) {
        top = y - rect.height;
      } else if (top + rect.height > vh - pad) {
        top = vh - rect.height - pad;
      }
      top = Math.min(Math.max(pad, top), Math.max(pad, vh - rect.height - pad));

      if (left + totalW > vw - pad) {
        left = Math.max(pad, vw - totalW - pad);
      }
      left = Math.min(Math.max(pad, left), Math.max(pad, vw - rect.width - pad));

      setPosition((prev) => (prev.top === top && prev.left === left ? prev : { top, left }));
    }

    place();
    const ro = new ResizeObserver(place);
    ro.observe(el);
    window.addEventListener("resize", place);
    return () => {
      ro.disconnect();
      window.removeEventListener("resize", place);
    };
  }, [x, y, submenu, sectionFlyout, confirmDelete]);

  useEffect(() => {
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape") {
        if (sectionFlyout) {
          e.preventDefault();
          setSectionFlyout(null);
          return;
        }
        if (submenu) {
          e.preventDefault();
          setSubmenu(null);
          return;
        }
        onClose();
        return;
      }

      const root = sectionFlyoutRef.current ?? flyoutRef.current ?? menuRef.current;
      if (!root) return;
      const items = [...root.querySelectorAll<HTMLButtonElement>('[role="menuitem"]:not([disabled])')];
      if (!items.length) return;

      const active = document.activeElement as HTMLElement | null;
      const idx = items.findIndex((el) => el === active);

      if (e.key === "ArrowDown") {
        e.preventDefault();
        const next = items[(idx + 1 + items.length) % items.length];
        next?.focus();
      } else if (e.key === "ArrowUp") {
        e.preventDefault();
        const next = items[(idx - 1 + items.length) % items.length];
        next?.focus();
      } else if (e.key === "ArrowLeft") {
        if (sectionFlyout) {
          e.preventDefault();
          setSectionFlyout(null);
        } else if (submenu) {
          e.preventDefault();
          setSubmenu(null);
        }
      } else if (e.key === "ArrowRight" && !submenu && menuRef.current?.contains(active)) {
        const chevronItem = items.find((el) => el === active && el.querySelector('[data-submenu]'));
        if (chevronItem) {
          e.preventDefault();
          chevronItem.click();
        }
      }
    }
    function onPointerDown(e: PointerEvent) {
      const target = e.target as Node;
      if (menuRef.current?.contains(target)) return;
      if (flyoutRef.current?.contains(target)) return;
      if (sectionFlyoutRef.current?.contains(target)) return;
      onClose();
    }
    window.addEventListener("keydown", onKey);
    const timer = window.setTimeout(() => {
      window.addEventListener("pointerdown", onPointerDown);
    }, 0);
    return () => {
      window.clearTimeout(timer);
      window.removeEventListener("keydown", onKey);
      window.removeEventListener("pointerdown", onPointerDown);
    };
  }, [onClose, submenu, sectionFlyout]);

  useEffect(() => {
    if (confirmDelete) return;
    const first = menuRef.current?.querySelector<HTMLButtonElement>('[role="menuitem"]');
    first?.focus();
  }, [confirmDelete, x, y]);

  function run(action: () => void | Promise<void>) {
    void action();
    onClose();
  }

  function openSubmenu(next: Submenu, anchor: HTMLElement) {
    const menuRect = menuRef.current?.getBoundingClientRect();
    const itemRect = anchor.getBoundingClientRect();
    if (!menuRect) return;
    setSectionFlyout(null);
    setFlyoutTop(itemRect.top - menuRect.top);
    setSubmenu((current) => (current === next ? null : next));
  }

  async function handleProjectSelect(
    projectId: string | null,
    anchor: HTMLElement,
    projectName?: string,
    projectIcon?: string | null,
  ) {
    if (!projectId) {
      run(() => updateTaskProjectAndSection(task.id, null, null));
      return;
    }

    setLoadingProjectId(projectId);
    try {
      const list = await getProjectSections(projectId);
      if (list.length === 0) {
        run(() => updateTaskProjectAndSection(task.id, projectId, null));
        return;
      }

      const flyoutRect = flyoutRef.current?.getBoundingClientRect();
      const itemRect = anchor.getBoundingClientRect();
      setSectionFlyout({
        projectId,
        projectName: projectName ?? projects.find((p) => p.id === projectId)?.name ?? "Projeto",
        top: itemRect.top - (flyoutRect?.top ?? itemRect.top),
        sections: list,
      });
    } finally {
      setLoadingProjectId(null);
    }
  }

  if (confirmDelete) {
    return (
      <ClientPortal>
        <ConfirmDialog
          title="Excluir tarefa"
          message={`Tem certeza que deseja excluir "${task.title}"?`}
          confirmLabel="Excluir"
          destructive
          onCancel={() => {
            setConfirmDelete(false);
            onClose();
          }}
          onConfirm={() => {
            void deleteTask(task.id);
            setConfirmDelete(false);
            onClose();
          }}
        />
      </ClientPortal>
    );
  }

  return (
    <ClientPortal>
      <div
        ref={menuRef}
        className="fixed z-[var(--z-menu)] flex items-start"
        style={{ top: position.top, left: position.left }}
        onContextMenu={(e: MouseEvent) => e.preventDefault()}
      >
      <div
        className="min-w-[220px] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] py-1 shadow-lg"
        role="menu"
      >
        <MenuItem icon={Edit01Icon} label="Editar" onClick={() => run(() => selectTask(task.id))} />
        <MenuItem icon={Tick01Icon} label="Concluir" onClick={() => run(() => toggleTaskDone(task.id))} />
        <MenuItem icon={Clock01Icon} label="Adiar" onClick={() => run(() => deferTask(task.id))} />
        <MenuItem icon={Copy01Icon} label="Duplicar" onClick={() => run(() => duplicateTask(task.id))} />

        <div className="my-1 h-px bg-[var(--color-border)]" />

        <MenuItem
          icon={Flag01Icon}
          label={`Prioridade${task.priority ? `: ${task.priority}` : ""}`}
          chevron
          active={submenu === "priority"}
          onClick={(e) => openSubmenu("priority", e.currentTarget)}
        />
        <MenuItem
          icon={Folder01Icon}
          label={`Mover para${task.project ? `: ${task.project}` : ""}`}
          chevron
          active={submenu === "project"}
          onClick={(e) => openSubmenu("project", e.currentTarget)}
        />
        <MenuItem
          icon={Tag01Icon}
          label={`Etiquetas${task.labelIds?.length ? ` (${task.labelIds.length})` : ""}`}
          chevron
          active={submenu === "labels"}
          onClick={(e) => openSubmenu("labels", e.currentTarget)}
        />

        <div className="my-1 h-px bg-[var(--color-border)]" />

        <MenuItem icon={Delete01Icon} label="Excluir" destructive onClick={() => setConfirmDelete(true)} />
      </div>

      {submenu && (
        <div
          ref={flyoutRef}
          className="ml-1.5 min-w-[200px] max-h-[min(60vh,320px)] overflow-y-auto scroll-thin rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] py-1 shadow-lg"
          style={{ marginTop: flyoutTop }}
          role="menu"
        >
          {submenu === "priority" && (
            <>
              {(["P1", "P2", "P3"] as Priority[]).map((p) => (
                <FlyoutItem
                  key={p}
                  label={p}
                  icon={Flag01Icon}
                  iconColor={p === "P1" ? "var(--color-p1)" : p === "P2" ? "var(--color-p2)" : "var(--color-p3)"}
                  active={task.priority === p}
                  onClick={() => run(() => updateTaskPriority(task.id, p))}
                />
              ))}
              <FlyoutItem
                label="Nenhuma"
                muted
                active={!task.priority}
                onClick={() => run(() => updateTaskPriority(task.id, null))}
              />
            </>
          )}

          {submenu === "project" && (
            <>
              <FlyoutItem
                label="Inbox"
                icon={InboxIcon}
                active={!task.projectId}
                onClick={(e) => void handleProjectSelect(null, e.currentTarget)}
              />
              {projects.map((p) => (
                <FlyoutItem
                  key={p.id}
                  label={p.name}
                  projectIcon={p.icon}
                  chevron
                  active={
                    sectionFlyout?.projectId === p.id ||
                    (task.projectId === p.id && !sectionFlyout)
                  }
                  loading={loadingProjectId === p.id}
                  onClick={(e) => void handleProjectSelect(p.id, e.currentTarget, p.name, p.icon)}
                />
              ))}
            </>
          )}

          {submenu === "labels" && (
            <>
              {labels.length === 0 && (
                <p className="px-3 py-2 text-xs text-[var(--color-text-secondary)]">Nenhuma etiqueta.</p>
              )}
              {labels.map((l) => {
                const selected = task.labelIds?.includes(l.id) ?? false;
                return (
                  <FlyoutItem
                    key={l.id}
                    label={l.name}
                    labelColor={l.color}
                    active={selected}
                    onClick={() => {
                      const current = new Set(task.labelIds ?? []);
                      if (current.has(l.id)) current.delete(l.id);
                      else current.add(l.id);
                      run(() => updateTaskLabels(task.id, [...current]));
                    }}
                  />
                );
              })}
              {task.labelIds?.length ? (
                <FlyoutItem label="Limpar etiquetas" muted onClick={() => run(() => updateTaskLabels(task.id, []))} />
              ) : null}
            </>
          )}
        </div>
      )}

      {sectionFlyout && (
        <div
          ref={sectionFlyoutRef}
          className="ml-1.5 min-w-[200px] max-h-[min(60vh,320px)] overflow-y-auto scroll-thin rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] py-1 shadow-lg"
          style={{ marginTop: sectionFlyout.top }}
          role="menu"
        >
          <p className="truncate px-3 py-1.5 text-[11px] font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)]">
            {sectionFlyout.projectName}
          </p>
          <FlyoutItem
            label="Sem seção"
            active={task.projectId === sectionFlyout.projectId && !task.sectionId}
            onClick={() =>
              run(() => updateTaskProjectAndSection(task.id, sectionFlyout.projectId, null))
            }
          />
          {sectionFlyout.sections.map((s) => (
            <FlyoutItem
              key={s.id}
              label={s.name}
              active={task.sectionId === s.id}
              onClick={() =>
                run(() => updateTaskProjectAndSection(task.id, sectionFlyout.projectId, s.id))
              }
            />
          ))}
        </div>
      )}
      </div>
    </ClientPortal>
  );
}

function MenuItem({
  icon,
  label,
  onClick,
  chevron,
  active,
  destructive,
}: {
  icon: typeof Edit01Icon;
  label: string;
  onClick: (e: MouseEvent<HTMLButtonElement>) => void;
  chevron?: boolean;
  active?: boolean;
  destructive?: boolean;
}) {
  return (
    <button
      type="button"
      role="menuitem"
      onClick={onClick}
      className={`flex w-full min-h-10 items-center gap-2.5 px-3 py-2 text-left text-sm hover:bg-[var(--color-hover-overlay)] ${
        active ? "bg-[var(--color-hover-overlay)]" : ""
      } ${destructive ? "text-[var(--color-overdue)]" : "text-[var(--color-text)]"}`}
    >
      <AppIcon icon={icon} size={16} className="shrink-0 text-[var(--color-text-secondary)]" />
      <span className="flex-1 truncate">{label}</span>
      {chevron && (
        <span data-submenu="">
          <AppIcon icon={ArrowRight01Icon} size={14} className="shrink-0 text-[var(--color-text-tertiary)]" />
        </span>
      )}
    </button>
  );
}

function FlyoutItem({
  label,
  onClick,
  active,
  muted,
  dot,
  labelColor,
  icon,
  iconColor,
  projectIcon,
  chevron,
  loading,
}: {
  label: string;
  onClick: (e: MouseEvent<HTMLButtonElement>) => void;
  active?: boolean;
  muted?: boolean;
  dot?: string;
  labelColor?: string;
  icon?: typeof Flag01Icon;
  iconColor?: string;
  projectIcon?: string | null;
  chevron?: boolean;
  loading?: boolean;
}) {
  return (
    <button
      type="button"
      role="menuitem"
      onClick={onClick}
      disabled={loading}
      className={`flex w-full min-h-9 items-center gap-2 px-3 py-1.5 text-left text-sm hover:bg-[var(--color-hover-overlay)] disabled:opacity-60 ${
        active ? "bg-[var(--color-hover-overlay)] font-medium" : ""
      } ${muted ? "text-[var(--color-text-tertiary)]" : "text-[var(--color-text)]"}`}
    >
      {projectIcon ? (
        <ProjectIcon iconKey={projectIcon} color="var(--color-text-secondary)" size={16} />
      ) : labelColor ? (
        <span style={{ color: labelColor }}>
          <AppIcon icon={Tag01Icon} size={14} strokeWidth={1.75} />
        </span>
      ) : icon ? (
        <span style={{ color: iconColor ?? "var(--color-text-secondary)" }}>
          <AppIcon icon={icon} size={14} strokeWidth={1.75} />
        </span>
      ) : (
        dot && (
          <span className="h-2 w-2 shrink-0 rounded-full" style={{ background: dot }} />
        )
      )}
      <span className="flex-1 truncate" style={labelColor && active ? { color: labelColor } : undefined}>
        {label}
      </span>
      {loading ? (
        <span className="text-[11px] text-[var(--color-text-tertiary)]">…</span>
      ) : chevron ? (
        <AppIcon icon={ArrowRight01Icon} size={14} className="shrink-0 text-[var(--color-text-tertiary)]" />
      ) : null}
    </button>
  );
}

export function useTaskContextMenu() {
  const [state, setState] = useState<{ task: Task; x: number; y: number } | null>(null);
  const longPressTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const touchMoved = useRef(false);

  function open(task: Task, x: number, y: number) {
    setState({ task, x, y });
  }

  function close() {
    setState(null);
  }

  function onContextMenu(task: Task, e: React.MouseEvent) {
    e.preventDefault();
    e.stopPropagation();
    open(task, e.clientX, e.clientY);
  }

  function onTouchStart(task: Task, e: React.TouchEvent) {
    touchMoved.current = false;
    const touch = e.touches[0];
    longPressTimer.current = setTimeout(() => {
      if (!touchMoved.current) {
        open(task, touch.clientX, touch.clientY);
      }
    }, 500);
  }

  function onTouchMove() {
    touchMoved.current = true;
    if (longPressTimer.current) clearTimeout(longPressTimer.current);
  }

  function onTouchEnd() {
    if (longPressTimer.current) clearTimeout(longPressTimer.current);
  }

  const menu = state ? (
    <TaskContextMenu task={state.task} x={state.x} y={state.y} onClose={close} />
  ) : null;

  return { menu, onContextMenu, onTouchStart, onTouchMove, onTouchEnd, close };
}
