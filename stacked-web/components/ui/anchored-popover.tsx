"use client";

import { useLayoutEffect, useRef, useState, type ReactNode } from "react";
import { createPortal } from "react-dom";

export type AnchorRect = {
  top: number;
  left: number;
  right: number;
  bottom: number;
  width: number;
  height: number;
};

type AnchoredPopoverProps = {
  open: boolean;
  onClose: () => void;
  anchorRect?: AnchorRect | null;
  children: ReactNode;
  className?: string;
  width?: number;
  preferSide?: "left" | "right";
  /** Alinha verticalmente ao fim do anchor (útil para botões no rodapé) */
  verticalAlign?: "start" | "end" | "auto";
  /** Posicionamento relativo ao anchor */
  placement?: "side" | "below";
};

function clamp(value: number, min: number, max: number) {
  return Math.min(Math.max(value, min), max);
}

export function AnchoredPopover({
  open,
  onClose,
  anchorRect,
  children,
  className = "",
  width = 280,
  preferSide = "left",
  verticalAlign = "auto",
  placement = "side",
}: AnchoredPopoverProps) {
  const popoverRef = useRef<HTMLDivElement>(null);
  const [pos, setPos] = useState<{ top: number; left: number } | null>(null);

  useLayoutEffect(() => {
    if (!open || !anchorRect) {
      setPos(null);
      return;
    }

    function compute() {
      const pad = 12;
      const gap = 6;
      const popoverHeight = popoverRef.current?.offsetHeight ?? 240;

      let left: number;
      let top: number;

      if (placement === "below") {
        left = anchorRect!.left;
        top = anchorRect!.bottom + gap;
        if (left + width > window.innerWidth - pad) {
          left = Math.max(pad, anchorRect!.right - width);
        }
        if (top + popoverHeight > window.innerHeight - pad) {
          top = Math.max(pad, anchorRect!.top - popoverHeight - gap);
        }
      } else {
        left = preferSide === "left" ? anchorRect!.left - width - gap : anchorRect!.right + gap;
        if (left < pad) left = anchorRect!.right + gap;
        if (left + width > window.innerWidth - pad) {
          left = clamp(anchorRect!.left - width - gap, pad, window.innerWidth - width - pad);
        }

        top = anchorRect!.top;
        const overflowBottom = top + popoverHeight > window.innerHeight - pad;
        const alignEnd =
          verticalAlign === "end" || (verticalAlign === "auto" && overflowBottom);

        if (alignEnd) {
          top = anchorRect!.bottom - popoverHeight;
        }
      }

      top = clamp(top, pad, window.innerHeight - popoverHeight - pad);
      setPos({ top, left });
    }

    compute();
    const ro = popoverRef.current ? new ResizeObserver(compute) : null;
    if (popoverRef.current && ro) ro.observe(popoverRef.current);
    return () => ro?.disconnect();
  }, [open, anchorRect, width, preferSide, verticalAlign, placement]);

  useLayoutEffect(() => {
    if (!open) return;
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape") onClose();
    }
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, onClose]);

  if (!open || typeof document === "undefined") return null;

  return createPortal(
    <>
      <div className="fixed inset-0 z-[var(--z-popover)]" onClick={onClose} aria-hidden />
      <div
        ref={popoverRef}
        className={`fixed z-[calc(var(--z-popover)+1)] max-h-[min(70vh,420px)] overflow-y-auto scroll-thin rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] p-4 shadow-xl ${className}`}
        style={{
          width,
          top: pos?.top ?? Math.max(12, anchorRect?.top ?? 80),
          left: pos?.left ?? Math.max(12, (anchorRect?.left ?? 200) - width - 8),
        }}
        role="dialog"
        aria-modal="true"
        onClick={(e) => e.stopPropagation()}
      >
        {children}
      </div>
    </>,
    document.body,
  );
}

export function anchorFromElement(el: HTMLElement): AnchorRect {
  const r = el.getBoundingClientRect();
  return { top: r.top, left: r.left, right: r.right, bottom: r.bottom, width: r.width, height: r.height };
}
