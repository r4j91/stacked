"use client";

import { useMemo, useState } from "react";
import {
  NoteRepository,
  type Note,
  type NoteColor,
} from "@/lib/repositories/note-repository";
import { NOTE_COLOR_STYLE, NOTE_COLORS } from "@/lib/notes/note-colors";

type NoteEditorDialogProps = {
  note: Note | null;
  onClose: () => void;
  onChanged: () => void | Promise<void>;
};

export function NoteEditorDialog({ note, onClose, onChanged }: NoteEditorDialogProps) {
  const [title, setTitle] = useState(note?.title ?? "");
  const [body, setBody] = useState(note?.body ?? "");
  const [color, setColor] = useState<NoteColor>(note?.color ?? "mint");
  const [pinned, setPinned] = useState(note?.pinned ?? false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const canSave = useMemo(() => {
    return Boolean(title.trim() || body.trim()) && !saving;
  }, [title, body, saving]);

  async function save() {
    if (!canSave) return;
    setSaving(true);
    setError(null);
    try {
      if (note) {
        await NoteRepository.update(note.id, { title, body, color, pinned });
      } else {
        await NoteRepository.create({ title, body, color, pinned });
      }
      await onChanged();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Erro ao salvar");
    } finally {
      setSaving(false);
    }
  }

  async function convert() {
    if (!note) return;
    setSaving(true);
    setError(null);
    try {
      await NoteRepository.update(note.id, { title, body, color, pinned });
      await NoteRepository.convertToTask({ ...note, title, body, color, pinned });
      await onChanged();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Erro ao converter");
    } finally {
      setSaving(false);
    }
  }

  async function remove() {
    if (!note) return;
    setSaving(true);
    try {
      await NoteRepository.remove(note.id);
      await onChanged();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Erro ao excluir");
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/50 p-3 sm:items-center">
      <div className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-[var(--radius-lg)] bg-[var(--color-bg)] p-4 shadow-xl">
        <div className="mb-3 flex items-center justify-between">
          <button type="button" className="text-sm text-[var(--color-text-secondary)]" onClick={onClose}>
            Fechar
          </button>
          <button
            type="button"
            disabled={!canSave}
            onClick={() => void save()}
            className="text-sm font-semibold text-[var(--color-accent)] disabled:opacity-40"
          >
            Pronto
          </button>
        </div>
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Título (opcional)"
          autoFocus
          className="mb-3 w-full bg-transparent text-[22px] font-bold text-[var(--color-text)] outline-none placeholder:text-[var(--color-text-tertiary)]"
        />
        <textarea
          value={body}
          onChange={(e) => setBody(e.target.value)}
          placeholder="Escreva aqui…"
          rows={8}
          className="mb-4 w-full resize-none bg-transparent text-[16px] text-[var(--color-text)] outline-none placeholder:text-[var(--color-text-tertiary)]"
        />
        <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)]">
          Cor
        </p>
        <div className="mb-4 flex gap-2">
          {NOTE_COLORS.map((c) => (
            <button
              key={c}
              type="button"
              onClick={() => setColor(c)}
              className="h-8 w-8 rounded-full border-2"
              style={{
                background: NOTE_COLOR_STYLE[c].bg,
                borderColor: color === c ? "var(--color-accent)" : "transparent",
              }}
              aria-label={c}
            />
          ))}
        </div>
        <label className="mb-4 flex items-center gap-2 text-sm text-[var(--color-text)]">
          <input type="checkbox" checked={pinned} onChange={(e) => setPinned(e.target.checked)} />
          Fixar no topo
        </label>
        {error && <p className="mb-3 text-sm text-[var(--color-overdue)]">{error}</p>}
        {note && (
          <div className="flex flex-col gap-2">
            <button
              type="button"
              disabled={saving}
              onClick={() => void convert()}
              className="rounded-[var(--radius-md)] bg-[var(--color-accent)]/12 px-3 py-2.5 text-sm font-semibold text-[var(--color-accent)]"
            >
              Virar tarefa
            </button>
            <button
              type="button"
              disabled={saving}
              onClick={() => void remove()}
              className="rounded-[var(--radius-md)] px-3 py-2.5 text-sm font-semibold text-[var(--color-overdue)]"
            >
              Excluir nota
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
