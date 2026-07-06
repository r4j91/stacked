"use client";

import { FormEvent, useEffect, useState } from "react";
import { AppIcon } from "@/components/ui/app-icon";
import { ColorPalettePicker } from "@/components/ui/color-palette-picker";
import { ProjectIcon } from "@/components/ui/project-icon";
import { TagChip } from "@/components/ui/tag-chip";
import { Cancel01Icon, FilterHorizontalIcon, Flag01Icon, Folder01Icon, Tag01Icon } from "@/lib/icons/nav-icons";
import { LabelsPicker, PriorityPicker, ProjectPicker } from "@/components/tasks/meta-picker-sheet";
import type { Label } from "@/lib/types/label";
import type { Project } from "@/lib/types/project";
import type { Priority } from "@/lib/types/task";
import {
  EMPTY_FILTER_CRITERIA,
  type FilterCriteria,
  type FilterDateScope,
  type FilterPriorityCriteria,
  type SavedFilter,
} from "@/lib/types/saved-filter";
import { DEFAULT_PALETTE_HEX } from "@/lib/theme/palette-colors";
import { priorityColor, priorityLabel } from "@/lib/utils/priority";
import { dateScopeLabel } from "@/lib/utils/filter-criteria";

type SavedFilterBuilderProps = {
  open: boolean;
  onClose: () => void;
  labels: Label[];
  projects: Project[];
  initial?: SavedFilter | null;
  onSave: (input: { name: string; color: string | null; criteria: FilterCriteria }) => Promise<void>;
};

function criteriaToPriority(c: FilterPriorityCriteria): Priority | null {
  if (c === "high") return "P1";
  if (c === "medium") return "P2";
  if (c === "low") return "P3";
  return null;
}

function priorityToCriteria(p: Priority | null): FilterPriorityCriteria | null {
  if (!p) return null;
  if (p === "P1") return "high";
  if (p === "P2") return "medium";
  return "low";
}

export function SavedFilterBuilder({
  open,
  onClose,
  labels,
  projects,
  initial,
  onSave,
}: SavedFilterBuilderProps) {
  const [name, setName] = useState("");
  const [color, setColor] = useState<string>(DEFAULT_PALETTE_HEX);
  const [criteria, setCriteria] = useState<FilterCriteria>(EMPTY_FILTER_CRITERIA);
  const [labelsOpen, setLabelsOpen] = useState(false);
  const [priorityOpen, setPriorityOpen] = useState(false);
  const [projectOpen, setProjectOpen] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!open) return;
    setName(initial?.name ?? "");
    setColor(initial?.color ?? DEFAULT_PALETTE_HEX);
    setCriteria(initial?.criteria ?? { ...EMPTY_FILTER_CRITERIA });
  }, [open, initial]);

  if (!open) return null;

  const selectedLabels = labels.filter((l) => criteria.labelIds.includes(l.id));
  const selectedProject = projects.find((p) => p.id === criteria.projectId);
  const singlePriority = criteria.priorities.length === 1 ? criteria.priorities[0]! : null;
  const priorityForPicker =
    singlePriority && singlePriority !== "none" ? criteriaToPriority(singlePriority) : null;

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    const trimmed = name.trim();
    if (!trimmed || submitting) return;
    setSubmitting(true);
    try {
      await onSave({ name: trimmed, color, criteria });
      onClose();
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <>
      <div
        className="fixed inset-0 z-[var(--z-panel)] flex items-end justify-center bg-black/40 sm:items-center sm:p-4"
        onClick={onClose}
        role="presentation"
      >
        <form
          className="flex max-h-[90vh] w-full max-w-md flex-col overflow-hidden rounded-t-[var(--radius-lg)] bg-[var(--color-surface)] shadow-lg sm:rounded-[var(--radius-lg)]"
          onClick={(e) => e.stopPropagation()}
          onSubmit={(e) => void handleSubmit(e)}
          role="dialog"
          aria-modal="true"
          aria-labelledby="saved-filter-builder-title"
        >
          <div className="flex shrink-0 items-center justify-between border-b border-[var(--color-border)] px-4 py-3">
            <h2 id="saved-filter-builder-title" className="text-base font-bold">
              {initial ? "Editar filtro" : "Novo filtro"}
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

          <div className="min-h-0 flex-1 overflow-y-auto scroll-thin p-4">
            <label className="mb-4 block text-xs font-medium text-[var(--color-text-secondary)]">
              Nome
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Trabalho urgente"
                className="mt-1 w-full rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-[var(--color-surface-variant)] px-3 py-2.5 text-[15px] font-medium outline-none focus:border-[var(--color-border-strong)]"
              />
            </label>

            <div className="mb-4 flex flex-wrap gap-2">
              <MetaChip
                icon={Folder01Icon}
                label={selectedProject?.name ?? "Projeto"}
                active={Boolean(criteria.projectId)}
                activeColor={selectedProject?.color}
                projectIcon={selectedProject?.icon}
                onClick={() => setProjectOpen(true)}
              />
              <MetaChip
                icon={Tag01Icon}
                label={
                  selectedLabels.length === 1
                    ? selectedLabels[0]!.name
                    : selectedLabels.length > 1
                      ? `${selectedLabels.length} etiquetas`
                      : "Etiquetas"
                }
                active={criteria.labelIds.length > 0}
                activeColor={selectedLabels[0]?.color}
                onClick={() => setLabelsOpen(true)}
              />
              <MetaChip
                icon={Flag01Icon}
                label={
                  criteria.priorities.length === 1
                    ? singlePriority === "none"
                      ? "Sem prioridade"
                      : priorityLabel(priorityForPicker)
                    : criteria.priorities.length > 1
                      ? `${criteria.priorities.length} prioridades`
                      : "Prioridade"
                }
                active={criteria.priorities.length > 0}
                activeColor={
                  singlePriority && singlePriority !== "none" && priorityForPicker
                    ? priorityColor(priorityForPicker)
                    : undefined
                }
                onClick={() => setPriorityOpen(true)}
              />
              <span
                className="inline-flex items-center gap-1.5 rounded-full border border-[var(--color-border-strong)] bg-[var(--color-surface-variant)] px-3 py-1.5 text-xs font-medium text-[var(--color-text-secondary)]"
                aria-hidden
              >
                <AppIcon icon={FilterHorizontalIcon} size={14} strokeWidth={1.75} />
                <span className="h-3.5 w-3.5 rounded-full border border-white/20" style={{ background: color }} />
                Cor
              </span>
            </div>

            <div className="mb-4">
              <ColorPalettePicker value={color} onChange={setColor} swatchSize="sm" />
            </div>

            {selectedLabels.length > 1 && (
              <div className="mb-4 flex flex-wrap gap-1.5">
                {selectedLabels.map((l) => (
                  <TagChip key={l.id} label={l.name} color={l.color} />
                ))}
              </div>
            )}

            <fieldset className="space-y-1">
              <legend className="mb-2 text-[11px] font-bold uppercase tracking-wide text-[var(--color-text-tertiary)]">
                Data
              </legend>
              {(["any", "overdue", "today", "week", "no_date"] as FilterDateScope[]).map((scope) => (
                <label
                  key={scope}
                  className={`flex cursor-pointer items-center gap-2.5 rounded-[var(--radius-sm)] px-3 py-2.5 text-sm ${
                    criteria.dateScope === scope
                      ? "bg-[var(--color-surface-variant)] text-[var(--color-text)]"
                      : "text-[var(--color-text-secondary)] hover:bg-[var(--color-hover-overlay)]"
                  }`}
                >
                  <input
                    type="radio"
                    name="dateScope"
                    checked={criteria.dateScope === scope}
                    onChange={() => setCriteria((c) => ({ ...c, dateScope: scope }))}
                    className="sr-only"
                  />
                  <span
                    className={`flex h-[18px] w-[18px] items-center justify-center rounded-full border-2 ${
                      criteria.dateScope === scope
                        ? "border-[var(--color-accent)]"
                        : "border-[var(--color-text-tertiary)]"
                    }`}
                  >
                    {criteria.dateScope === scope && (
                      <span className="h-2 w-2 rounded-full bg-[var(--color-accent)]" />
                    )}
                  </span>
                  {dateScopeLabel(scope)}
                </label>
              ))}
            </fieldset>
          </div>

          <div className="flex shrink-0 justify-end gap-2 border-t border-[var(--color-border)] p-4">
            <button
              type="button"
              onClick={onClose}
              className="rounded-[var(--radius-sm)] px-3 py-1.5 text-sm text-[var(--color-text-secondary)] hover:bg-[var(--color-hover-overlay)]"
            >
              Cancelar
            </button>
            <button
              type="submit"
              disabled={submitting || !name.trim()}
              className="btn-primary rounded-[var(--radius-sm)] px-4 py-1.5 text-sm"
            >
              Salvar
            </button>
          </div>
        </form>
      </div>

      <LabelsPicker
        open={labelsOpen}
        onClose={() => setLabelsOpen(false)}
        labels={labels}
        value={criteria.labelIds}
        onChange={(ids) => setCriteria((c) => ({ ...c, labelIds: ids }))}
      />
      <PriorityPicker
        open={priorityOpen}
        onClose={() => setPriorityOpen(false)}
        value={priorityForPicker}
        onChange={(p) =>
          setCriteria((c) => ({
            ...c,
            priorities: p ? [priorityToCriteria(p)!] : [],
          }))
        }
      />
      <ProjectPicker
        open={projectOpen}
        onClose={() => setProjectOpen(false)}
        projects={projects}
        value={criteria.projectId}
        onChange={(id) => setCriteria((c) => ({ ...c, projectId: id }))}
      />
    </>
  );
}

function MetaChip({
  icon,
  label,
  active,
  activeColor,
  projectIcon,
  onClick,
}: {
  icon: typeof Folder01Icon;
  label: string;
  active?: boolean;
  activeColor?: string;
  projectIcon?: string | null;
  onClick: () => void;
}) {
  const color = active && activeColor ? activeColor : "var(--color-text-secondary)";
  return (
    <button
      type="button"
      onClick={onClick}
      className={`inline-flex max-w-full items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-medium transition-colors ${
        active
          ? "border-[var(--color-border-strong)] bg-[var(--color-surface-variant)] text-[var(--color-text)]"
          : "border-[var(--color-border)] text-[var(--color-text-secondary)] hover:border-[var(--color-border-strong)] hover:text-[var(--color-text)]"
      }`}
    >
      {projectIcon && active ? (
        <ProjectIcon iconKey={projectIcon} color={color} size={14} />
      ) : (
        <span style={{ color }}>
          <AppIcon icon={icon} size={14} strokeWidth={1.75} />
        </span>
      )}
      <span className="truncate" style={active && activeColor ? { color: activeColor } : undefined}>
        {label}
      </span>
    </button>
  );
}
