"use client";

import { FormEvent, useState } from "react";
import { useWorkbench } from "@/components/shell/workbench-context";
import { AnchoredPopover } from "@/components/ui/anchored-popover";
import { AppIcon } from "@/components/ui/app-icon";
import { Cancel01Icon, Delete01Icon, Edit01Icon } from "@/lib/icons/nav-icons";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { ColorPalettePicker } from "@/components/ui/color-palette-picker";
import { DEFAULT_PALETTE_HEX } from "@/lib/theme/palette-colors";
import type { Label } from "@/lib/types/label";

export function LabelsManager() {
  const { labelsOpen, labelsAnchor, closeLabels, labels, createLabel, updateLabel, deleteLabel } = useWorkbench();
  const [editing, setEditing] = useState<Label | null>(null);
  const [deleting, setDeleting] = useState<Label | null>(null);
  const [name, setName] = useState("");
  const [color, setColor] = useState<string>(DEFAULT_PALETTE_HEX);

  function resetForm() {
    setEditing(null);
    setName("");
    setColor(DEFAULT_PALETTE_HEX);
  }

  function handleClose() {
    resetForm();
    closeLabels();
  }

  function startEdit(label: Label) {
    setEditing(label);
    setName(label.name);
    setColor(label.color);
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    const trimmed = name.trim();
    if (!trimmed) return;
    if (editing) {
      await updateLabel(editing.id, { name: trimmed, color });
    } else {
      await createLabel(trimmed, color);
    }
    resetForm();
  }

  return (
    <>
      <AnchoredPopover
        open={labelsOpen}
        onClose={handleClose}
        anchorRect={labelsAnchor}
        width={340}
        preferSide="right"
        verticalAlign="start"
        className="flex max-h-[min(70vh,520px)] flex-col p-0"
      >
        <div className="flex shrink-0 items-center justify-between border-b border-[var(--color-border)] px-4 py-3">
          <h2 className="text-base font-bold">Etiquetas</h2>
          <button
            type="button"
            onClick={handleClose}
            className="flex h-8 w-8 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-tertiary)] hover:bg-[var(--color-surface-variant)]"
            aria-label="Fechar"
          >
            <AppIcon icon={Cancel01Icon} size={18} />
          </button>
        </div>

        <form onSubmit={(e) => void handleSubmit(e)} className="shrink-0 border-b border-[var(--color-border)] p-4">
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Nome da etiqueta"
            className="input-focus mb-3 w-full rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-[var(--color-surface-variant)] px-3 py-2 text-sm outline-none"
          />
          <div className="mb-3">
            <ColorPalettePicker value={color} onChange={setColor} swatchSize="sm" />
          </div>
          <button type="submit" className="btn-primary w-full rounded-[var(--radius-sm)] py-2 text-sm">
            {editing ? "Salvar" : "Criar etiqueta"}
          </button>
          {editing && (
            <button
              type="button"
              onClick={resetForm}
              className="mt-2 w-full text-sm text-[var(--color-text-tertiary)] hover:text-[var(--color-text-secondary)]"
            >
              Cancelar edição
            </button>
          )}
        </form>

        <ul className="min-h-0 flex-1 overflow-y-auto scroll-thin p-2">
          {labels.length === 0 && (
            <li className="px-3 py-6 text-center text-sm text-[var(--color-text-tertiary)]">Nenhuma etiqueta criada.</li>
          )}
          {labels.map((label) => (
            <li
              key={label.id}
              className="mb-0.5 flex items-center gap-2 rounded-[var(--radius-sm)] px-2 py-2 hover:bg-[var(--color-surface-variant)]"
            >
              <span className="h-3 w-3 shrink-0 rounded-full" style={{ background: label.color }} />
              <span className="flex-1 truncate text-sm font-medium">{label.name}</span>
              <button
                type="button"
                onClick={() => startEdit(label)}
                className="flex h-8 w-8 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-tertiary)] hover:bg-[var(--color-hover-overlay)]"
                aria-label={`Editar ${label.name}`}
              >
                <AppIcon icon={Edit01Icon} size={16} />
              </button>
              <button
                type="button"
                onClick={() => setDeleting(label)}
                className="flex h-8 w-8 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-overdue)] hover:bg-[var(--color-hover-overlay)]"
                aria-label={`Excluir ${label.name}`}
              >
                <AppIcon icon={Delete01Icon} size={16} />
              </button>
            </li>
          ))}
        </ul>
      </AnchoredPopover>

      {deleting && (
        <ConfirmDialog
          title="Excluir etiqueta"
          message={`Excluir "${deleting.name}"? As tarefas não perderão o vínculo até atualizar.`}
          confirmLabel="Excluir"
          destructive
          onCancel={() => setDeleting(null)}
          onConfirm={() => {
            void deleteLabel(deleting.id);
            setDeleting(null);
          }}
        />
      )}
    </>
  );
}
