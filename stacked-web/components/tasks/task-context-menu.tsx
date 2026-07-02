"use client";

import { useEffect, useLayoutEffect, useRef, useState, type MouseEvent } from "react";
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

type TaskContextMenuProps = {
  task: Task;
  x: number;
  y: number;
  onClose: () => void;
};

type Submenu = "priority" | "project" | "labels";

export function TaskContextMenu({ task, x, y, onClose }: TaskContextMenuProps) {
  const {
    projects,
    selectTask,
    toggleTaskDone,
    deferTask,
    duplicateTask,
    deleteTask,
    updateTaskPriority,
    updateTaskProject,
    updateTaskLabels,
    labels,
  } = useWorkbench();
  const menuRef = useRef<HTMLDivElement>(null);
  const flyoutRef = useRef<HTMLDivElement>(null);
  const [submenu, setSubmenu] = useState<Submenu | null>(null);
  const [flyoutTop, setFlyoutTop] = useState(0);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [position, setPosition] = useState({ top: y, left: x });

  useLayoutEffect(() => {
    const el = menuRef.current;
    if (!el) return;
    const rect = el.getBoundingClientRect();
    const flyoutW = submenu ? flyoutRef.current?.getBoundingClientRect().width ?? 200 : 0;
    const pad = 12;
    let top = y;
    let left = x;
    if (top + rect.height > window.innerHeight - pad) {
      top = Math.max(pad, window.innerHeight - rect.height - pad);
    }
    if (left + rect.width + flyoutW + 8 > window.innerWidth - pad) {
      left = Math.max(pad, window.innerWidth - rect.width - flyoutW - 8);
    }
    setPosition({ top, left });
  }, [x, y, submenu, confirmDelete]);

  useEffect(() => {
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape") onClose();
    }
    function onPointerDown(e: PointerEvent) {
      const target = e.target as Node;
      if (menuRef.current?.contains(target)) return;
      if (flyoutRef.current?.contains(target)) return;
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
  }, [onClose]);

  function run(action: () => void | Promise<void>) {
    void action();
    onClose();
  }

  function openSubmenu(next: Submenu, anchor: HTMLElement) {
    const menuRect = menuRef.current?.getBoundingClientRect();
    const itemRect = anchor.getBoundingClientRect();
    if (!menuRect) return;
    setFlyoutTop(itemRect.top - menuRect.top);
    setSubmenu((current) => (current === next ? null : next));
  }

  if (confirmDelete) {
    return (
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
    );
  }

  return (
    <div
      ref={menuRef}
      className="fixed z-[60] flex items-start"
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
                onClick={() => run(() => updateTaskProject(task.id, null))}
              />
              {projects.map((p) => (
                <FlyoutItem
                  key={p.id}
                  label={p.name}
                  projectIcon={p.icon}
                  projectColor={p.color}
                  active={task.projectId === p.id}
                  onClick={() => run(() => updateTaskProject(task.id, p.id))}
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
    </div>
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
        <AppIcon icon={ArrowRight01Icon} size={14} className="shrink-0 text-[var(--color-text-tertiary)]" />
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
  projectColor,
}: {
  label: string;
  onClick: () => void;
  active?: boolean;
  muted?: boolean;
  dot?: string;
  labelColor?: string;
  icon?: typeof Flag01Icon;
  iconColor?: string;
  projectIcon?: string | null;
  projectColor?: string;
}) {
  return (
    <button
      type="button"
      role="menuitem"
      onClick={onClick}
      className={`flex w-full min-h-9 items-center gap-2 px-3 py-1.5 text-left text-sm hover:bg-[var(--color-hover-overlay)] ${
        active ? "bg-[var(--color-hover-overlay)] font-medium" : ""
      } ${muted ? "text-[var(--color-text-tertiary)]" : "text-[var(--color-text)]"}`}
    >
      {projectIcon && projectColor ? (
        <ProjectIcon iconKey={projectIcon} color={projectColor} size={16} />
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
      <span className="truncate" style={labelColor && active ? { color: labelColor } : undefined}>
        {label}
      </span>
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
