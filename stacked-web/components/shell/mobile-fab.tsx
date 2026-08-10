"use client";

import { useEffect, useRef, useState } from "react";
import { useWorkbench } from "@/components/shell/workbench-context";
import { AppIcon } from "@/components/ui/app-icon";
import {
  Add01Icon,
  Cancel01Icon,
  Folder01Icon,
  Note01Icon,
  Search01Icon,
} from "@/lib/icons/nav-icons";

type FabAction = {
  id: string;
  label: string;
  icon: typeof Add01Icon;
  onClick: () => void;
};

export function MobileFab() {
  const { openQuickAdd, openNoteCreate, openProjectCreate, openPalette } = useWorkbench();
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const onPointer = (e: PointerEvent) => {
      if (rootRef.current && !rootRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    };
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };
    window.addEventListener("pointerdown", onPointer);
    window.addEventListener("keydown", onKey);
    return () => {
      window.removeEventListener("pointerdown", onPointer);
      window.removeEventListener("keydown", onKey);
    };
  }, [open]);

  const actions: FabAction[] = [
    {
      id: "search",
      label: "Buscar",
      icon: Search01Icon,
      onClick: () => openPalette(),
    },
    {
      id: "note",
      label: "Nova nota",
      icon: Note01Icon,
      onClick: () => openNoteCreate(),
    },
    {
      id: "project",
      label: "Novo projeto",
      icon: Folder01Icon,
      onClick: () => openProjectCreate(),
    },
    {
      id: "task",
      label: "Nova tarefa",
      icon: Add01Icon,
      onClick: () => openQuickAdd(),
    },
  ];

  function run(action: FabAction) {
    setOpen(false);
    action.onClick();
  }

  return (
    <div
      ref={rootRef}
      className="fixed right-[14px] z-[calc(var(--z-backdrop)+1)] flex flex-col items-end gap-3 lg:hidden"
      style={{ bottom: "var(--mobile-fab-bottom)" }}
    >
      {open && (
        <div className="flex flex-col items-end gap-3">
          {actions.map((action) => (
            <button
              key={action.id}
              type="button"
              onClick={() => run(action)}
              className="flex items-center gap-2.5"
            >
              <span className="rounded-full bg-[var(--color-surface)] px-3 py-1.5 text-[13px] font-semibold text-[var(--color-text)] shadow-[0_8px_24px_rgba(0,0,0,.28)]">
                {action.label}
              </span>
              <span className="flex h-11 w-11 items-center justify-center rounded-full border border-[var(--color-border)] bg-[var(--color-surface)] text-[var(--color-accent)] shadow-[0_8px_24px_rgba(0,0,0,.28)]">
                <AppIcon icon={action.icon} size={18} />
              </span>
            </button>
          ))}
        </div>
      )}

      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="flex h-14 w-14 items-center justify-center rounded-full border border-[color-mix(in_srgb,var(--color-btn-primary-fg)_12%,transparent)] bg-[var(--color-btn-primary-bg)] text-[var(--color-btn-primary-fg)] transition-transform duration-150 ease-out active:scale-95"
        aria-label={open ? "Fechar menu de ações" : "Criar novo"}
        aria-expanded={open}
      >
        <AppIcon icon={open ? Cancel01Icon : Add01Icon} size={24} strokeWidth={2} />
      </button>
    </div>
  );
}
