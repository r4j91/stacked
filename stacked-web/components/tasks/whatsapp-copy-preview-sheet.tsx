"use client";

import { useEffect, useState } from "react";
import { AppIcon } from "@/components/ui/app-icon";
import { ClientPortal } from "@/components/ui/client-portal";
import { Cancel01Icon } from "@/lib/icons/nav-icons";

type WhatsAppCopyPreviewSheetProps = {
  open: boolean;
  onClose: () => void;
  taskTitle: string;
  message: string;
};

function sheetTitle(taskTitle: string): string {
  const trimmed = taskTitle.trim();
  if (trimmed.length <= 18) return `Mensagem · ${trimmed}`;
  return `Mensagem · ${trimmed.slice(0, 18)}…`;
}

export function WhatsAppCopyPreviewSheet({
  open,
  onClose,
  taskTitle,
  message,
}: WhatsAppCopyPreviewSheetProps) {
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    if (open) setCopied(false);
  }, [open, message]);

  if (!open) return null;

  async function copyMessage() {
    try {
      await navigator.clipboard.writeText(message);
      setCopied(true);
    } catch {
      setCopied(false);
    }
  }

  return (
    <ClientPortal>
      <div
        className="fixed inset-0 z-[var(--z-panel)] flex items-end justify-center bg-black/40 sm:items-center sm:p-4"
        onClick={onClose}
        role="presentation"
      >
      <div
        className="flex max-h-[min(90vh,640px)] w-full max-w-lg flex-col overflow-hidden rounded-t-[var(--radius-lg)] border border-[var(--color-border)] bg-[var(--color-surface)] shadow-xl sm:rounded-[var(--radius-lg)]"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-label={sheetTitle(taskTitle)}
      >
        <header className="flex shrink-0 items-center justify-between gap-3 border-b border-[var(--color-border)] px-4 py-3">
          <h2 className="min-w-0 truncate text-sm font-semibold text-[var(--color-text)]">
            {sheetTitle(taskTitle)}
          </h2>
          <button
            type="button"
            onClick={onClose}
            className="flex h-8 w-8 shrink-0 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-tertiary)] hover:bg-[var(--color-hover-overlay)]"
            aria-label="Fechar"
          >
            <AppIcon icon={Cancel01Icon} size={18} />
          </button>
        </header>

        <div className="scroll-thin flex-1 overflow-y-auto p-4">
          <pre className="whitespace-pre-wrap break-words rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-variant)] p-4 font-sans text-sm leading-relaxed text-[var(--color-text)]">
            {message}
          </pre>
        </div>

        <footer className="shrink-0 border-t border-[var(--color-border)] p-4">
          <button
            type="button"
            onClick={() => void copyMessage()}
            className="btn-primary w-full rounded-[var(--radius-md)] px-4 py-2.5 text-sm font-semibold"
          >
            {copied ? "Copiado!" : "Copiar mensagem"}
          </button>
        </footer>
      </div>
    </div>
    </ClientPortal>
  );
}
