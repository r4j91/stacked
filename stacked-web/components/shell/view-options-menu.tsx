"use client";

import { useState } from "react";
import { AppIcon } from "@/components/ui/app-icon";
import { ViewIcon, ViewOffIcon } from "@/lib/icons/nav-icons";
import { AnchoredPopover, anchorFromElement } from "@/components/ui/anchored-popover";

type ViewOptionsMenuProps = {
  showCompleted: boolean;
  onToggleCompleted: () => void;
  extraItems?: { label: string; onClick: () => void }[];
};

export function ViewOptionsMenu({ showCompleted, onToggleCompleted, extraItems }: ViewOptionsMenuProps) {
  const [open, setOpen] = useState(false);
  const [anchor, setAnchor] = useState<ReturnType<typeof anchorFromElement> | null>(null);

  function close() {
    setOpen(false);
    setAnchor(null);
  }

  return (
    <>
      <button
        type="button"
        onClick={(e) => {
          setAnchor(anchorFromElement(e.currentTarget));
          setOpen(true);
        }}
        className="btn-secondary inline-flex items-center gap-1.5 rounded-[var(--radius-sm)] px-3 py-1.5 text-[13px]"
        aria-expanded={open}
        aria-haspopup="menu"
      >
        Opções
      </button>
      <AnchoredPopover open={open} onClose={close} anchorRect={anchor} width={240} placement="below" className="p-1">
        <div role="menu">
          {extraItems?.map((item) => (
            <button
              key={item.label}
              type="button"
              role="menuitem"
              onClick={() => {
                item.onClick();
                close();
              }}
              className="flex w-full items-center gap-2.5 rounded-[var(--radius-sm)] px-3 py-2.5 text-left text-[13px] text-[var(--color-text)] hover:bg-[var(--color-hover-overlay)]"
            >
              {item.label}
            </button>
          ))}
          <button
            type="button"
            role="menuitem"
            onClick={() => {
              onToggleCompleted();
              close();
            }}
            className="flex w-full items-center gap-2.5 rounded-[var(--radius-sm)] px-3 py-2.5 text-left text-[13px] text-[var(--color-text)] hover:bg-[var(--color-hover-overlay)]"
          >
            <AppIcon icon={showCompleted ? ViewOffIcon : ViewIcon} size={16} className="text-[var(--color-text-secondary)]" />
            {showCompleted ? "Ocultar concluídas" : "Mostrar concluídas"}
          </button>
        </div>
      </AnchoredPopover>
    </>
  );
}
