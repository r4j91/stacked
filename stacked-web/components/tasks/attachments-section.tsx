"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { AppIcon } from "@/components/ui/app-icon";
import { Attachment01Icon, Cancel01Icon, Add01Icon } from "@/lib/icons/nav-icons";
import { createClient } from "@/lib/supabase/client";
import { isSupabaseConfigured } from "@/lib/supabase/config";
import { AttachmentRepository } from "@/lib/repositories/attachment-repository";
import {
  ATTACHMENT_MAX_BYTES,
  formatAttachmentSize,
  isAllowedAttachmentMime,
  type TaskAttachment,
} from "@/lib/types/attachment";

type AttachmentsSectionProps = {
  taskId: string;
  subtaskId?: string | null;
};

export function AttachmentsSection({ taskId, subtaskId = null }: AttachmentsSectionProps) {
  const [items, setItems] = useState<TaskAttachment[]>([]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const reload = useCallback(async () => {
    if (!isSupabaseConfigured()) return;
    const repo = new AttachmentRepository(createClient());
    const list = subtaskId
      ? await repo.listForSubtask(subtaskId)
      : await repo.listForTask(taskId);
    setItems(list);
  }, [taskId, subtaskId]);

  useEffect(() => {
    void reload().catch((e) => setError(e instanceof Error ? e.message : "Erro ao carregar anexos"));
  }, [reload]);

  async function onPick(files: FileList | null) {
    if (!files?.length || !isSupabaseConfigured()) return;
    setBusy(true);
    setError(null);
    const repo = new AttachmentRepository(createClient());
    try {
      for (const file of Array.from(files)) {
        if (!isAllowedAttachmentMime(file.type)) {
          throw new Error(`"${file.name}" não é imagem nem PDF`);
        }
        if (file.size > ATTACHMENT_MAX_BYTES) {
          throw new Error(`"${file.name}" passa de 20 MB`);
        }
        await repo.upload({ taskId, subtaskId, file });
      }
      await reload();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Falha no upload");
    } finally {
      setBusy(false);
      if (inputRef.current) inputRef.current.value = "";
    }
  }

  async function openAttachment(item: TaskAttachment) {
    try {
      const url = await new AttachmentRepository(createClient()).createSignedUrl(item.storagePath);
      window.open(url, "_blank", "noopener,noreferrer");
    } catch (e) {
      setError(e instanceof Error ? e.message : "Não foi possível abrir");
    }
  }

  async function removeAttachment(item: TaskAttachment) {
    setBusy(true);
    setError(null);
    try {
      await new AttachmentRepository(createClient()).remove(item);
      setItems((prev) => prev.filter((a) => a.id !== item.id));
    } catch (e) {
      setError(e instanceof Error ? e.message : "Falha ao excluir");
    } finally {
      setBusy(false);
    }
  }

  return (
    <section className="mt-4">
      <div className="mb-2 flex items-center justify-between gap-2">
        <h3 className="flex items-center gap-2 text-xs font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)]">
          <AppIcon icon={Attachment01Icon} size={14} strokeWidth={1.75} />
          Anexos
        </h3>
        <button
          type="button"
          disabled={busy}
          onClick={() => inputRef.current?.click()}
          className="inline-flex items-center gap-1 rounded-[var(--radius-sm)] px-2 py-1 text-xs font-medium text-[var(--color-text-secondary)] hover:bg-[var(--color-hover-overlay)] disabled:opacity-50"
        >
          <AppIcon icon={Add01Icon} size={14} />
          Adicionar
        </button>
        <input
          ref={inputRef}
          type="file"
          accept="image/*,application/pdf"
          multiple
          className="hidden"
          onChange={(e) => void onPick(e.target.files)}
        />
      </div>

      {error && <p className="mb-2 text-xs text-[var(--color-overdue)]">{error}</p>}

      {items.length === 0 ? (
        <p className="text-sm text-[var(--color-text-tertiary)]">Nenhum anexo</p>
      ) : (
        <ul className="divide-y divide-[var(--color-border)] overflow-hidden rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)]/60">
          {items.map((item) => (
            <li key={item.id} className="flex items-center gap-2 px-3 py-2.5">
              <button
                type="button"
                onClick={() => void openAttachment(item)}
                className="min-w-0 flex-1 text-left"
              >
                <p className="truncate text-sm font-medium text-[var(--color-text)]">{item.fileName}</p>
                <p className="text-[11px] text-[var(--color-text-tertiary)]">
                  {item.mimeType.startsWith("image/") ? "Imagem" : "PDF"} ·{" "}
                  {formatAttachmentSize(item.sizeBytes)}
                </p>
              </button>
              <button
                type="button"
                disabled={busy}
                aria-label={`Excluir ${item.fileName}`}
                onClick={() => void removeAttachment(item)}
                className="flex h-8 w-8 shrink-0 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-tertiary)] hover:bg-[var(--color-hover-overlay)] hover:text-[var(--color-overdue)] disabled:opacity-50"
              >
                <AppIcon icon={Cancel01Icon} size={14} />
              </button>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}

/** Chip do Quick Add — arquivos pendentes até a tarefa ser criada. */
export function PendingAttachmentsChip({
  files,
  onAdd,
  onRemove,
}: {
  files: File[];
  onAdd: (files: File[]) => void;
  onRemove: (index: number) => void;
}) {
  const inputRef = useRef<HTMLInputElement>(null);
  const active = files.length > 0;

  return (
    <>
      <button
        type="button"
        onClick={() => inputRef.current?.click()}
        className={`inline-flex max-w-full items-center gap-1.5 rounded-full border px-2.5 py-1.5 text-xs font-medium ${
          active
            ? "border-[var(--color-border-strong)] text-[var(--color-text)]"
            : "border-[var(--color-border)] text-[var(--color-text-tertiary)]"
        }`}
      >
        <AppIcon icon={Attachment01Icon} size={14} strokeWidth={1.75} />
        <span className="truncate">{active ? `${files.length} anexo${files.length > 1 ? "s" : ""}` : "Anexo"}</span>
      </button>
      <input
        ref={inputRef}
        type="file"
        accept="image/*,application/pdf"
        multiple
        className="hidden"
        onChange={(e) => {
          const next = Array.from(e.target.files ?? []);
          if (next.length) onAdd(next);
          if (inputRef.current) inputRef.current.value = "";
        }}
      />
      {files.length > 0 && (
        <div className="flex w-full flex-wrap gap-1.5 pt-1">
          {files.map((file, i) => (
            <span
              key={`${file.name}-${i}`}
              className="inline-flex max-w-full items-center gap-1 rounded-md border border-[var(--color-border)] bg-[var(--color-surface-variant)] px-2 py-1 text-[11px] text-[var(--color-text-secondary)]"
            >
              <span className="truncate">{file.name}</span>
              <button type="button" aria-label="Remover" onClick={() => onRemove(i)}>
                <AppIcon icon={Cancel01Icon} size={12} />
              </button>
            </span>
          ))}
        </div>
      )}
    </>
  );
}
