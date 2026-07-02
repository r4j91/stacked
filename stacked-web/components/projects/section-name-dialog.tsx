"use client";

import { FormEvent, useEffect, useRef } from "react";
import { useFocusTrap } from "@/lib/hooks/use-focus-trap";

type SectionNameDialogProps = {
  title: string;
  initialValue?: string;
  submitLabel?: string;
  onClose: () => void;
  onSubmit: (name: string) => void;
};

export function SectionNameDialog({
  title,
  initialValue = "",
  submitLabel = "Salvar",
  onClose,
  onSubmit,
}: SectionNameDialogProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const dialogRef = useRef<HTMLFormElement>(null);
  useFocusTrap(true, dialogRef);

  useEffect(() => {
    inputRef.current?.focus();
    inputRef.current?.select();
  }, []);

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    const name = inputRef.current?.value.trim() ?? "";
    if (!name) return;
    onSubmit(name);
  }

  return (
    <div
      className="fixed inset-0 z-[var(--z-panel)] flex items-center justify-center bg-black/40 p-4"
      onClick={onClose}
      role="presentation"
    >
      <form
        ref={dialogRef}
        className="w-full max-w-sm rounded-[var(--radius-md)] bg-[var(--color-surface)] p-4 shadow-xl"
        onClick={(e) => e.stopPropagation()}
        onSubmit={handleSubmit}
      >
        <h2 className="mb-3 text-base font-bold">{title}</h2>
        <input
          ref={inputRef}
          type="text"
          defaultValue={initialValue}
          className="input-focus mb-4 w-full rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-[var(--color-surface-variant)] px-3 py-2 text-sm outline-none"
          placeholder="Nome da seção"
        />
        <div className="flex justify-end gap-2">
          <button
            type="button"
            onClick={onClose}
            className="rounded-[var(--radius-sm)] px-3 py-1.5 text-sm text-[var(--color-text-secondary)] hover:bg-[var(--color-surface-variant)]"
          >
            Cancelar
          </button>
          <button
            type="submit"
            className="btn-primary rounded-[var(--radius-sm)] px-3 py-1.5 text-sm"
          >
            {submitLabel}
          </button>
        </div>
      </form>
    </div>
  );
}
