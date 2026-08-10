"use client";

import { useCallback, useEffect, useState } from "react";
import {
  NoteRepository,
  noteDisplayTitle,
  type Note,
} from "@/lib/repositories/note-repository";
import { NOTE_COLOR_STYLE } from "@/lib/notes/note-colors";
import { NoteEditorDialog } from "@/components/notes/note-editor-dialog";
import { Note01Icon, ListViewIcon, GridIcon, Add01Icon } from "@/lib/icons/nav-icons";
import { AppIcon } from "@/components/ui/app-icon";

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
                const style = NOTE_COLOR_STYLE[note.color];
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
                      {note.pinned ? (
                        <span
                          className="h-2 w-2 rounded-full"
                          style={{ background: style.ink, opacity: 0.7 }}
                          title="Fixada"
                        />
                      ) : (
                        <span className="h-2 w-2 rounded-full bg-white/20" />
                      )}
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
                      style={{ background: NOTE_COLOR_STYLE[note.color].bg }}
                    />
                    <span className="min-w-0 flex-1">
                      <span className="flex items-center gap-1.5">
                        {note.pinned ? (
                          <span
                            className="h-1.5 w-1.5 shrink-0 rounded-full bg-[var(--color-accent)]"
                            title="Fixada"
                          />
                        ) : null}
                        <span className="block truncate font-semibold text-[var(--color-text)]">
                          {noteDisplayTitle(note)}
                        </span>
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
