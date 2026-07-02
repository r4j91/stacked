"use client";

import { useRef } from "react";
import { useWorkbench } from "@/components/shell/workbench-context";
import { AppIcon } from "@/components/ui/app-icon";
import { Cancel01Icon } from "@/lib/icons/nav-icons";
import { useFocusTrap } from "@/lib/hooks/use-focus-trap";
import { AnchoredPopover } from "@/components/ui/anchored-popover";
import { ShortcutsContent } from "@/components/settings/shortcuts-content";

export function ShortcutsDialog() {
  const { shortcutsOpen, shortcutsAnchor, closeShortcuts } = useWorkbench();
  const dialogRef = useRef<HTMLDivElement>(null);
  useFocusTrap(shortcutsOpen && !shortcutsAnchor, dialogRef);

  if (!shortcutsOpen) return null;

  if (shortcutsAnchor) {
    return (
      <AnchoredPopover
        open={shortcutsOpen}
        onClose={closeShortcuts}
        anchorRect={shortcutsAnchor}
        width={340}
        preferSide="right"
        className="max-h-[min(85vh,560px)] p-0"
      >
        <ShortcutsPanel onClose={closeShortcuts} />
      </AnchoredPopover>
    );
  }

  return (
    <div
      className="fixed inset-0 z-[var(--z-panel)] flex items-center justify-center bg-black/40 p-4"
      onClick={closeShortcuts}
      role="presentation"
    >
      <div
        ref={dialogRef}
        className="w-full max-w-md rounded-[var(--radius-md)] bg-[var(--color-surface)] p-4 shadow-xl"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-labelledby="shortcuts-title"
      >
        <ShortcutsPanel onClose={closeShortcuts} />
      </div>
    </div>
  );
}

function ShortcutsPanel({ onClose }: { onClose: () => void }) {
  return (
    <>
      <div className="flex items-center justify-between border-b border-[var(--color-border)] px-4 py-3">
        <h2 id="shortcuts-title" className="text-base font-bold">
          Atalhos de teclado
        </h2>
        <button
          type="button"
          onClick={onClose}
          className="flex h-8 w-8 items-center justify-center rounded-full text-[var(--color-text-tertiary)] hover:bg-[var(--color-surface-variant)]"
          aria-label="Fechar"
        >
          <AppIcon icon={Cancel01Icon} size={16} />
        </button>
      </div>
      <div className="scroll-thin overflow-y-auto px-4 py-3">
        <ShortcutsContent />
      </div>
    </>
  );
}
