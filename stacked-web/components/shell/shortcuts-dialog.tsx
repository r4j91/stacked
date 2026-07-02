"use client";

import { useWorkbench } from "@/components/shell/workbench-context";
import { AppIcon } from "@/components/ui/app-icon";
import { Cancel01Icon } from "@/lib/icons/nav-icons";

const SHORTCUTS = [
  { keys: ["Q"], description: "Nova tarefa" },
  { keys: ["⌘", "K"], description: "Buscar" },
  { keys: ["⌘", "B"], description: "Alternar barra lateral" },
  { keys: ["⌘", "1"], description: "Navegar" },
  { keys: ["⌘", "2"], description: "Inbox" },
  { keys: ["⌘", "3"], description: "Hoje" },
  { keys: ["⌘", "4"], description: "Em breve" },
  { keys: ["⌘", "5"], description: "Filtros" },
  { keys: ["?"], description: "Atalhos de teclado" },
  { keys: ["Esc"], description: "Fechar painel / seleção" },
];

export function ShortcutsDialog() {
  const { shortcutsOpen, closeShortcuts } = useWorkbench();

  if (!shortcutsOpen) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
      onClick={closeShortcuts}
      role="presentation"
    >
      <div
        className="w-full max-w-md rounded-[var(--radius-md)] bg-[var(--color-surface)] p-4 shadow-xl"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-labelledby="shortcuts-title"
      >
        <div className="mb-4 flex items-center justify-between">
          <h2 id="shortcuts-title" className="text-base font-bold">
            Atalhos de teclado
          </h2>
          <button
            type="button"
            onClick={closeShortcuts}
            className="flex h-8 w-8 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-tertiary)] hover:bg-[var(--color-surface-variant)]"
            aria-label="Fechar"
          >
            <AppIcon icon={Cancel01Icon} size={18} />
          </button>
        </div>
        <ul className="space-y-2">
          {SHORTCUTS.map((s) => (
            <li key={s.description} className="flex items-center justify-between gap-4 text-sm">
              <span className="text-[var(--color-text-secondary)]">{s.description}</span>
              <span className="flex shrink-0 gap-1">
                {s.keys.map((k) => (
                  <kbd
                    key={k}
                    className="rounded bg-[var(--color-surface-variant)] px-1.5 py-0.5 text-[11px] font-semibold text-[var(--color-text-tertiary)]"
                  >
                    {k}
                  </kbd>
                ))}
              </span>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}
