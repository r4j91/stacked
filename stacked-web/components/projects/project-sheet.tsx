"use client";

import { FormEvent, useEffect, useRef, useState } from "react";
import { useWorkbench } from "@/components/shell/workbench-context";
import { AppIcon } from "@/components/ui/app-icon";
import { ProjectIcon } from "@/components/ui/project-icon";
import { Cancel01Icon, Delete01Icon } from "@/lib/icons/nav-icons";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { useFocusTrap } from "@/lib/hooks/use-focus-trap";
import {
  DEFAULT_PROJECT_ICON,
  PROJECT_ICON_KEYS,
  type ProjectIconKey,
} from "@/lib/icons/project-icons";
import type { Project } from "@/lib/types/project";

import { ColorPalettePicker } from "@/components/ui/color-palette-picker";
import { DEFAULT_PALETTE_HEX } from "@/lib/theme/palette-colors";

type ProjectSheetProps = {
  open: boolean;
  mode: "create" | "edit";
  project?: Project | null;
  onClose: () => void;
};

export function ProjectSheet({ open, mode, project, onClose }: ProjectSheetProps) {
  const { createProject, updateProject, deleteProject } = useWorkbench();
  const [name, setName] = useState("");
  const [color, setColor] = useState<string>(DEFAULT_PALETTE_HEX);
  const [icon, setIcon] = useState<ProjectIconKey>(DEFAULT_PROJECT_ICON);
  const [submitting, setSubmitting] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const sheetRef = useRef<HTMLFormElement>(null);

  useEffect(() => {
    if (open) {
      setName(project?.name ?? "");
      setColor(project?.color ?? DEFAULT_PALETTE_HEX);
      setIcon((project?.icon as ProjectIconKey) ?? DEFAULT_PROJECT_ICON);
      setConfirmDelete(false);
    }
  }, [open, project]);

  useFocusTrap(open && !confirmDelete, sheetRef);

  if (!open) return null;

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    const trimmed = name.trim();
    if (!trimmed || submitting) return;
    setSubmitting(true);
    try {
      if (mode === "create") {
        await createProject(trimmed, color, icon);
      } else if (project) {
        await updateProject(project.id, { name: trimmed, color, icon });
      }
      onClose();
    } finally {
      setSubmitting(false);
    }
  }

  if (confirmDelete && project) {
    return (
      <ConfirmDialog
        title="Excluir projeto"
        message={`Excluir "${project.name}" e todas as tarefas vinculadas?`}
        confirmLabel="Excluir projeto"
        destructive
        onCancel={() => setConfirmDelete(false)}
        onConfirm={() => {
          void deleteProject(project.id);
          setConfirmDelete(false);
          onClose();
        }}
      />
    );
  }

  return (
    <div
      className="fixed inset-0 z-[var(--z-panel)] flex items-end justify-center bg-black/40 sm:items-center sm:p-4"
      onClick={onClose}
      role="presentation"
    >
      <form
        ref={sheetRef}
        className="w-full max-w-md rounded-t-[var(--radius-lg)] bg-[var(--color-surface)] p-4 shadow-xl sm:rounded-[var(--radius-lg)]"
        onClick={(e) => e.stopPropagation()}
        onSubmit={(e) => void handleSubmit(e)}
        role="dialog"
        aria-modal="true"
        aria-labelledby="project-sheet-title"
      >
        <div className="mb-3 flex items-center justify-between">
          <h2 id="project-sheet-title" className="text-base font-bold">
            {mode === "create" ? "Novo projeto" : "Editar projeto"}
          </h2>
          <button
            type="button"
            onClick={onClose}
            className="flex h-8 w-8 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-tertiary)] hover:bg-[var(--color-surface-variant)]"
            aria-label="Fechar"
          >
            <AppIcon icon={Cancel01Icon} size={18} />
          </button>
        </div>

        <label className="mb-3 block text-xs font-medium text-[var(--color-text-tertiary)]">
          Nome
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Nome do projeto"
            className="input-focus mt-1 w-full rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-[var(--color-surface-variant)] px-3 py-2.5 text-[15px] font-semibold outline-none"
            autoFocus
          />
        </label>

        <p className="mb-2 text-xs font-medium text-[var(--color-text-tertiary)]">Ícone</p>
        <div className="mb-4 grid grid-cols-8 gap-1.5">
          {PROJECT_ICON_KEYS.map((key) => (
            <button
              key={key}
              type="button"
              onClick={() => setIcon(key)}
              className={`flex h-9 w-9 items-center justify-center rounded-[var(--radius-sm)] border transition-colors ${
                icon === key
                  ? "border-[var(--color-border-strong)] bg-[var(--color-surface-variant)]"
                  : "border-transparent hover:bg-[var(--color-hover-overlay)]"
              }`}
              aria-label={`Ícone ${key}`}
              title={key}
            >
              <ProjectIcon iconKey={key} color="var(--color-text-secondary)" size={18} />
            </button>
          ))}
        </div>

        <p className="mb-2 text-xs font-medium text-[var(--color-text-tertiary)]">Cor</p>
        <div className="mb-4">
          <ColorPalettePicker value={color} onChange={setColor} />
        </div>

        <div className="flex items-center justify-between gap-2">
          {mode === "edit" && project && (
            <button
              type="button"
              onClick={() => setConfirmDelete(true)}
              className="inline-flex items-center gap-1.5 rounded-[var(--radius-sm)] px-3 py-1.5 text-sm text-[var(--color-overdue)] hover:bg-[var(--color-overdue)]/10"
            >
              <AppIcon icon={Delete01Icon} size={16} />
              Excluir
            </button>
          )}
          <div className="ml-auto flex gap-2">
            <button
              type="button"
              onClick={onClose}
              className="rounded-[var(--radius-sm)] px-3 py-1.5 text-sm text-[var(--color-text-secondary)] hover:bg-[var(--color-surface-variant)]"
            >
              Cancelar
            </button>
            <button
              type="submit"
              disabled={submitting || !name.trim()}
              className="btn-primary rounded-[var(--radius-sm)] px-4 py-1.5 text-sm font-semibold disabled:opacity-60"
            >
              {mode === "create" ? "Criar projeto" : "Salvar alterações"}
            </button>
          </div>
        </div>
      </form>
    </div>
  );
}
