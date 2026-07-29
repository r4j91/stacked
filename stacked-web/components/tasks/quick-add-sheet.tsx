"use client";

import { FormEvent, useEffect, useRef, useState } from "react";
import { useWorkbench } from "@/components/shell/workbench-context";
import { AppIcon } from "@/components/ui/app-icon";
import { ProjectIcon } from "@/components/ui/project-icon";
import { TagChip } from "@/components/ui/tag-chip";
import { InstallmentGeneratorSheet } from "@/components/tasks/installment-generator-sheet";
import { useFocusTrap } from "@/lib/hooks/use-focus-trap";
import {
  Cancel01Icon,
  Calendar03Icon,
  Flag01Icon,
  Folder01Icon,
  Tag01Icon,
  Target01Icon,
} from "@/lib/icons/nav-icons";
import { Money01Icon } from "@hugeicons/core-free-icons";
import {
  DatePicker,
  PriorityPicker,
  ProjectPicker,
  LabelsPicker,
} from "@/components/tasks/meta-picker-sheet";
import type { Priority } from "@/lib/types/task";
import { priorityColor, priorityLabel } from "@/lib/utils/priority";
import { formatDayLabel, parseDueDate, deadlineChipColor } from "@/lib/utils/date";
import { PendingAttachmentsChip } from "@/components/tasks/attachments-section";
import { AttachmentRepository } from "@/lib/repositories/attachment-repository";
import { createClient } from "@/lib/supabase/client";
import { isSupabaseConfigured } from "@/lib/supabase/config";
import {
  ATTACHMENT_MAX_BYTES,
  isAllowedAttachmentMime,
} from "@/lib/types/attachment";
import type { Home01Icon } from "@hugeicons/core-free-icons";

type QuickAddSheetProps = {
  open: boolean;
  onClose: () => void;
  initialProjectId?: string | null;
  initialSectionId?: string | null;
};

export function QuickAddSheet({
  open,
  onClose,
  initialProjectId,
  initialSectionId,
}: QuickAddSheetProps) {
  const { createTask, projects, labels, refreshTasks } = useWorkbench();
  const titleRef = useRef<HTMLInputElement>(null);
  const sheetRef = useRef<HTMLFormElement>(null);
  const [description, setDescription] = useState("");
  const [priority, setPriority] = useState<Priority | null>(null);
  const [dueDate, setDueDate] = useState<string | null>(null);
  const [deadline, setDeadline] = useState<string | null>(null);
  const [pendingFiles, setPendingFiles] = useState<File[]>([]);
  const [projectId, setProjectId] = useState<string | null>(initialProjectId ?? null);
  const [labelIds, setLabelIds] = useState<string[]>([]);
  const [dateOpen, setDateOpen] = useState(false);
  const [deadlineOpen, setDeadlineOpen] = useState(false);
  const [priorityOpen, setPriorityOpen] = useState(false);
  const [projectOpen, setProjectOpen] = useState(false);
  const [labelsOpen, setLabelsOpen] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [installmentOpen, setInstallmentOpen] = useState(false);
  const [installmentTaskId, setInstallmentTaskId] = useState<string | null>(null);
  const [installmentTitle, setInstallmentTitle] = useState("");

  useEffect(() => {
    if (open) {
      setDescription("");
      setPriority(null);
      setDueDate(null);
      setDeadline(null);
      setProjectId(initialProjectId ?? null);
      setLabelIds([]);
      setTimeout(() => titleRef.current?.focus(), 50);
    }
  }, [open, initialProjectId]);

  useFocusTrap(open, sheetRef);

  if (!open) return null;

  const project = projects.find((p) => p.id === projectId);
  const dueLabel = dueDate ? formatDayLabel(parseDueDate(dueDate)!) : null;
  const deadlineLabel = deadline ? formatDayLabel(parseDueDate(deadline)!) : null;
  const deadlineActiveColor = deadline
    ? deadlineChipColor(parseDueDate(deadline), false)
    : undefined;
  const selectedLabels = labels.filter((l) => labelIds.includes(l.id));

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    const title = titleRef.current?.value.trim() ?? "";
    if (!title || submitting) return;
    setSubmitting(true);
    try {
      const taskId = await createTask({
        title,
        description: description.trim() || undefined,
        priority: priority ?? undefined,
        projectId,
        sectionId: initialSectionId ?? null,
        dueDate,
        deadline,
        labelIds: labelIds.length ? labelIds : undefined,
      });
      if (taskId && pendingFiles.length && isSupabaseConfigured()) {
        const repo = new AttachmentRepository(createClient());
        for (const file of pendingFiles) {
          await repo.upload({ taskId, file });
        }
      }
      setPendingFiles([]);
      onClose();
    } finally {
      setSubmitting(false);
    }
  }

  async function openInstallmentGenerator() {
    const title = titleRef.current?.value.trim() ?? "";
    if (!title || submitting) return;
    setSubmitting(true);
    try {
      const taskId = await createTask({
        title,
        description: description.trim() || undefined,
        priority: priority ?? undefined,
        projectId,
        sectionId: initialSectionId ?? null,
        dueDate,
        labelIds: labelIds.length ? labelIds : undefined,
      });
      if (!taskId) return;
      setInstallmentTaskId(taskId);
      setInstallmentTitle(title);
      setInstallmentOpen(true);
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
          ref={sheetRef}
          className="overlay-enter w-full max-w-md rounded-t-[var(--radius-lg)] border border-[var(--color-border)] bg-[var(--color-surface)] p-4 sm:rounded-[var(--radius-lg)]"
          onClick={(e) => e.stopPropagation()}
          onSubmit={(e) => void handleSubmit(e)}
          role="dialog"
          aria-modal="true"
          aria-labelledby="quick-add-title"
        >
          <div className="mb-3 flex items-center justify-between">
            <h2 id="quick-add-title" className="text-base font-bold">Nova tarefa</h2>
            <button
              type="button"
              onClick={onClose}
              className="flex h-8 w-8 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-secondary)] hover:bg-[var(--color-hover-overlay)]"
              aria-label="Fechar"
            >
              <AppIcon icon={Cancel01Icon} size={18} />
            </button>
          </div>

          <label className="mb-3 block text-xs font-medium text-[var(--color-text-secondary)]">
            Título
            <input
              ref={titleRef}
              type="text"
              placeholder="O que precisa ser feito?"
              className="mt-1 w-full rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-[var(--color-surface-variant)] px-3 py-2.5 text-[15px] font-semibold outline-none placeholder:text-[var(--color-placeholder)] focus:border-[var(--color-border-strong)]"
            />
          </label>

          <label className="mb-3 block text-xs font-medium text-[var(--color-text-secondary)]">
            Descrição (opcional)
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Detalhes da tarefa, não da subtarefa"
              rows={3}
              className="mt-1 w-full resize-none rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-[var(--color-surface-variant)] px-3 py-2 text-sm outline-none placeholder:text-[var(--color-placeholder)] focus:border-[var(--color-border-strong)]"
            />
          </label>

          <div className="mb-4 flex flex-wrap gap-2">
            <MetaChip
              icon={Calendar03Icon}
              label={dueLabel ?? "Data"}
              active={Boolean(dueDate)}
              activeColor={dueDate ? "var(--color-text)" : undefined}
              onClick={() => setDateOpen(true)}
            />
            <MetaChip
              icon={Target01Icon}
              label={deadlineLabel ?? "Prazo"}
              active={Boolean(deadline)}
              activeColor={deadlineActiveColor}
              onClick={() => setDeadlineOpen(true)}
            />
            <MetaChip
              icon={Flag01Icon}
              label={priority ? priorityLabel(priority) : "Prioridade"}
              active={Boolean(priority)}
              activeColor={priority ? priorityColor(priority) : undefined}
              onClick={() => setPriorityOpen(true)}
            />
            <MetaChip
              icon={Folder01Icon}
              label={project?.name ?? "Projeto"}
              active={Boolean(projectId)}
              activeColor={project?.color}
              projectIcon={project?.icon}
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
              active={labelIds.length > 0}
              activeColor={selectedLabels[0]?.color}
              onClick={() => setLabelsOpen(true)}
            />
            <MetaChip
              icon={Money01Icon}
              label="Parcelas"
              active={false}
              onClick={() => void openInstallmentGenerator()}
            />
            <PendingAttachmentsChip
              files={pendingFiles}
              onAdd={(files) => {
                const accepted = files.filter(
                  (f) => isAllowedAttachmentMime(f.type) && f.size <= ATTACHMENT_MAX_BYTES,
                );
                if (accepted.length) setPendingFiles((prev) => [...prev, ...accepted]);
              }}
              onRemove={(index) => setPendingFiles((prev) => prev.filter((_, i) => i !== index))}
            />
          </div>

          {selectedLabels.length > 1 && (
            <div className="mb-4 flex flex-wrap gap-1.5">
              {selectedLabels.map((l) => (
                <TagChip key={l.id} label={l.name} color={l.color} />
              ))}
            </div>
          )}

          <div className="flex justify-end gap-2">
            <button
              type="button"
              onClick={onClose}
              className="rounded-[var(--radius-sm)] px-3 py-1.5 text-sm text-[var(--color-text-secondary)] hover:bg-[var(--color-hover-overlay)]"
            >
              Cancelar
            </button>
            <button type="submit" disabled={submitting} className="btn-primary rounded-[var(--radius-sm)] px-4 py-1.5 text-sm">
              Adicionar
            </button>
          </div>
        </form>
      </div>

      <DatePicker open={dateOpen} onClose={() => setDateOpen(false)} value={dueDate} onChange={setDueDate} />
      <DatePicker open={deadlineOpen} onClose={() => setDeadlineOpen(false)} value={deadline} onChange={setDeadline} />
      <PriorityPicker open={priorityOpen} onClose={() => setPriorityOpen(false)} value={priority} onChange={setPriority} />
      <ProjectPicker
        open={projectOpen}
        onClose={() => setProjectOpen(false)}
        projects={projects}
        value={projectId}
        onChange={setProjectId}
      />
      <LabelsPicker open={labelsOpen} onClose={() => setLabelsOpen(false)} labels={labels} value={labelIds} onChange={setLabelIds} />
      {installmentTaskId && (
        <InstallmentGeneratorSheet
          open={installmentOpen}
          onClose={() => setInstallmentOpen(false)}
          taskId={installmentTaskId}
          taskTitle={installmentTitle}
          onGenerated={() => {
            void refreshTasks();
            onClose();
          }}
        />
      )}
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
  icon: typeof Calendar03Icon;
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
      ) : active && icon === Folder01Icon ? (
        <ProjectIcon iconKey={null} color={color} size={14} />
      ) : (
        <span style={{ color }}>
          <AppIcon icon={icon as typeof Home01Icon} size={14} strokeWidth={1.75} />
        </span>
      )}
      <span className="truncate" style={active && activeColor ? { color: activeColor } : undefined}>
        {label}
      </span>
    </button>
  );
}
