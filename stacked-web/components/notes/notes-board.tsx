"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import {
  NoteRepository,
  noteDisplayTitle,
  type Note,
  type NoteColor,
} from "@/lib/repositories/note-repository";
import { Note01Icon, ListViewIcon, GridIcon, Add01Icon } from "@/lib/icons/nav-icons";
import { AppIcon } from "@/components/ui/app-icon";

const COLOR_STYLE: Record<NoteColor, { bg: string; ink: string; rot: string }> = {
  mint: { bg: "#1F3A36", ink: "#C8F0EA", rot: "-1.2deg" },
  ash: { bg: "#2A2E36", ink: "#E4E8EE", rot: "1deg" },
  amber: { bg: "#3A2E1A", ink: "#F5E0B8", rot: "0.8deg" },
  violet: { bg: "#2C2438", ink: "#E4D4F8", rot: "-0.6deg" },
  rose: { bg: "#3A2226", ink: "#F5C8CE", rot: "1.4deg" },
};

type Mode = "mural" | "list";

export function NotesBoard() {
  const [notes, setNotes] = useState<Note[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [mode, setMode] = useState<Mode>("mural");
  const [editing, setEditing] = useState<Note | null | "new">(null);

  const load = useCallback(async () => {
    try {
      setError(null);
      const list = await NoteRepository.list();
      setNotes(list);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Erro ao carregar notas");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  return (
    <main
      id="workbench-main-content"
      data-workbench-main
      tabIndex={-1}
      className="flex min-w-0 flex-1 flex-col overflow-hidden bg-[var(--color-bg)] outline-none"
    >
      <div className="mx-auto flex h-full w-full max-w-[var(--content-max-width)] min-w-0 flex-col px-4 lg:px-6">
        <header className="shrink-0 border-b border-[var(--color-border)] pb-4 pt-5">
          <div className="flex items-start justify-between gap-3">
            <div>
              <h1 className="type-screen-title">Notas</h1>
              <p className="mt-1 text-[13px] text-[var(--color-text-secondary)]">
                Rápidas, soltas — não são tarefas
              </p>
            </div>
            <div className="flex items-center gap-1.5">
              <button
                type="button"
                onClick={() => setMode((m) => (m === "mural" ? "list" : "mural"))}
                className="btn-secondary inline-flex h-9 w-9 items-center justify-center rounded-full"
                aria-label={mode === "mural" ? "Ver lista" : "Ver mural"}
              >
                <AppIcon icon={mode === "mural" ? ListViewIcon : GridIcon} size={16} />
              </button>
              <button
                type="button"
                onClick={() => setEditing("new")}
                className="btn-secondary inline-flex h-9 w-9 items-center justify-center rounded-full text-[var(--color-accent)]"
                aria-label="Nova nota"
              >
                <AppIcon icon={Add01Icon} size={16} />
              </button>
            </div>
          </div>
        </header>

        <div className="scroll-hidden min-h-0 flex-1 overflow-y-auto pb-24 pt-4">
          {loading ? (
            <p className="px-1 text-sm text-[var(--color-text-tertiary)]">Carregando…</p>
          ) : error ? (
            <div className="px-1">
              <p className="text-sm text-[var(--color-overdue)]">{error}</p>
              <button type="button" className="mt-2 text-sm text-[var(--color-accent)]" onClick={() => void load()}>
                Tentar de novo
              </button>
            </div>
          ) : notes.length === 0 ? (
            <div className="flex flex-col items-center justify-center gap-3 py-20 text-center">
              <AppIcon icon={Note01Icon} size={28} className="text-[var(--color-accent)]" />
              <p className="font-semibold text-[var(--color-text)]">Nenhuma nota ainda</p>
              <p className="max-w-xs text-sm text-[var(--color-text-tertiary)]">
                Capture ideias soltas. Depois você pode virar tarefa.
              </p>
              <button
                type="button"
                onClick={() => setEditing("new")}
                className="mt-2 rounded-[var(--radius-md)] bg-[var(--color-accent)] px-4 py-2 text-sm font-semibold text-[var(--color-on-accent)]"
              >
                Nova nota
              </button>
            </div>
          ) : mode === "mural" ? (
            <div className="grid grid-cols-2 gap-2.5 sm:grid-cols-3">
              {notes.map((note) => {
                const style = COLOR_STYLE[note.color];
                return (
                  <button
                    key={note.id}
                    type="button"
                    onClick={() => setEditing(note)}
                    className="min-h-[120px] rounded-[14px] p-3 text-left shadow-[0_8px_20px_rgba(0,0,0,.28)]"
                    style={{
                      background: style.bg,
                      color: style.ink,
                      transform: `rotate(${style.rot})`,
                    }}
                  >
                    <div className="mb-2 flex justify-end">
                      <span className="h-2 w-2 rounded-full bg-white/20" />
                    </div>
                    <p className="line-clamp-5 text-[13.5px] font-semibold leading-snug">
                      {noteDisplayTitle(note)}
                    </p>
                  </button>
                );
              })}
            </div>
          ) : (
            <ul className="flex flex-col gap-2">
              {notes.map((note) => (
                <li key={note.id}>
                  <button
                    type="button"
                    onClick={() => setEditing(note)}
                    className="flex w-full items-start gap-3 rounded-[var(--radius-md)] bg-[var(--color-surface)] px-3.5 py-3 text-left"
                  >
                    <span
                      className="mt-1 h-8 w-1 shrink-0 rounded-full"
                      style={{ background: COLOR_STYLE[note.color].bg }}
                    />
                    <span className="min-w-0 flex-1">
                      <span className="block truncate font-semibold text-[var(--color-text)]">
                        {noteDisplayTitle(note)}
                      </span>
                      {note.body.trim() ? (
                        <span className="mt-0.5 line-clamp-2 block text-[12.5px] text-[var(--color-text-tertiary)]">
                          {note.body}
                        </span>
                      ) : null}
                    </span>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>
      </div>

      {editing !== null && (
        <NoteEditorDialog
          note={editing === "new" ? null : editing}
          onClose={() => setEditing(null)}
          onChanged={async () => {
            setEditing(null);
            await load();
          }}
        />
      )}
    </main>
  );
}

function NoteEditorDialog({
  note,
  onClose,
  onChanged,
}: {
  note: Note | null;
  onClose: () => void;
  onChanged: () => Promise<void>;
}) {
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
          className="mb-3 w-full bg-transparent text-[22px] font-bold text-[var(--color-text)] outline-none placeholder:text-[var(--color-text-tertiary)]"
        />
        <textarea
          value={body}
          onChange={(e) => setBody(e.target.value)}
          placeholder="Escreva aqui…"
          rows={8}
          className="mb-4 w-full resize-none bg-transparent text-[16px] text-[var(--color-text)] outline-none placeholder:text-[var(--color-text-tertiary)]"
        />
        <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)]">Cor</p>
        <div className="mb-4 flex gap-2">
          {(Object.keys(COLOR_STYLE) as NoteColor[]).map((c) => (
            <button
              key={c}
              type="button"
              onClick={() => setColor(c)}
              className="h-8 w-8 rounded-full border-2"
              style={{
                background: COLOR_STYLE[c].bg,
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
