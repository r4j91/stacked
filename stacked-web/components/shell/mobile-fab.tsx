"use client";

import { useWorkbench } from "@/components/shell/workbench-context";
import { AppIcon } from "@/components/ui/app-icon";
import { Add01Icon } from "@/lib/icons/nav-icons";

export function MobileFab() {
  const { openQuickAdd } = useWorkbench();

  return (
    <button
      type="button"
      onClick={() => openQuickAdd()}
      className="fixed right-[14px] z-[calc(var(--z-backdrop)+1)] flex h-14 w-14 items-center justify-center rounded-full border border-[color-mix(in_srgb,var(--color-btn-primary-fg)_12%,transparent)] bg-[var(--color-btn-primary-bg)] text-[var(--color-btn-primary-fg)] transition-transform duration-150 ease-out active:scale-95 lg:hidden"
      style={{ bottom: "var(--mobile-fab-bottom)" }}
      aria-label="Nova tarefa"
    >
      <AppIcon icon={Add01Icon} size={24} strokeWidth={2} />
    </button>
  );
}
