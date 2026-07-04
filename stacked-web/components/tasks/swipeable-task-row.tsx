"use client";

import { useCallback, useRef, useState, type ReactNode, type PointerEvent } from "react";
import { AppIcon } from "@/components/ui/app-icon";
import { Tick01Icon, Clock01Icon, Delete01Icon } from "@/lib/icons/nav-icons";

const SWIPE_THRESHOLD = 72;
const ACTION_WIDTH = 48;

type SwipeableTaskRowProps = {
  children: ReactNode;
  onComplete: () => void;
  onDefer: () => void;
  onDelete: () => void;
  disabled?: boolean;
  /** Libera scale/sombra do reorder sem clipar nas laterais */
  allowOverflow?: boolean;
  /** Desativa hit-test enquanto arrasta (pointer passa para alvos abaixo) */
  dragGhost?: boolean;
  /** Espaço reservado à direita (ex.: botão expandir subtarefas) */
  reserveRight?: number;
};

export function SwipeableTaskRow({
  children,
  onComplete,
  onDefer,
  onDelete,
  disabled,
  allowOverflow = false,
  dragGhost = false,
  reserveRight = 0,
}: SwipeableTaskRowProps) {
  const [offsetX, setOffsetX] = useState(0);
  const [dragging, setDragging] = useState(false);
  const startX = useRef(0);
  const startY = useRef(0);
  const locked = useRef<"x" | "y" | null>(null);
  const isTouch = useRef(false);
  const offsetRef = useRef(0);

  const reset = useCallback(() => {
    setOffsetX(0);
    offsetRef.current = 0;
    setDragging(false);
    locked.current = null;
  }, []);

  function onPointerDown(e: PointerEvent<HTMLDivElement>) {
    if (disabled || e.button !== 0) return;
    isTouch.current = e.pointerType === "touch";
    if (!isTouch.current) return;
    startX.current = e.clientX;
    startY.current = e.clientY;
    locked.current = null;
    setDragging(true);
    (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
  }

  function onPointerMove(e: PointerEvent<HTMLDivElement>) {
    if (!dragging || !isTouch.current) return;
    const dx = e.clientX - startX.current;
    const dy = e.clientY - startY.current;
    if (!locked.current) {
      if (Math.abs(dx) > 8 || Math.abs(dy) > 8) {
        locked.current = Math.abs(dx) > Math.abs(dy) ? "x" : "y";
      }
      return;
    }
    if (locked.current === "y") return;
    const next = Math.max(-ACTION_WIDTH * 2, Math.min(ACTION_WIDTH, dx));
    offsetRef.current = next;
    setOffsetX(next);
  }

  function onPointerUp() {
    if (!dragging) return;
    const offset = offsetRef.current;
    if (offset >= SWIPE_THRESHOLD) {
      onComplete();
    } else if (offset <= -SWIPE_THRESHOLD) {
      if (Math.abs(offset) >= ACTION_WIDTH + SWIPE_THRESHOLD / 2) {
        onDelete();
      } else {
        onDefer();
      }
    }
    reset();
  }

  const revealRight = Math.min(ACTION_WIDTH, Math.max(0, offsetX));
  const revealLeft = Math.min(ACTION_WIDTH * 2, Math.max(0, -offsetX));

  return (
    <div
      className={`scroll-list-item group relative mb-0.5 rounded-[var(--radius-md)] ${
        allowOverflow ? "overflow-visible" : "overflow-hidden lg:overflow-visible"
      } ${dragGhost ? "pointer-events-none" : ""}`}
      data-reorder-dragging={dragGhost ? "" : undefined}
    >
      <div
        className="absolute top-0 z-10 hidden h-full items-center gap-0.5 pr-1 opacity-0 transition-opacity group-hover:opacity-100 lg:flex"
        style={{ right: reserveRight }}
        aria-hidden={false}
      >
        <ActionButton tone="done" label="Concluir" onClick={onComplete}>
          <AppIcon icon={Tick01Icon} size={15} />
        </ActionButton>
        <ActionButton tone="neutral" label="Adiar" onClick={onDefer}>
          <AppIcon icon={Clock01Icon} size={15} />
        </ActionButton>
        <ActionButton tone="danger" label="Excluir" onClick={onDelete}>
          <AppIcon icon={Delete01Icon} size={15} />
        </ActionButton>
      </div>

      <div className="absolute left-0 top-0 flex h-full lg:hidden" style={{ width: revealRight }} aria-hidden>
        <SwipeAction tone="done" width={revealRight} onClick={onComplete}>
          <AppIcon icon={Tick01Icon} size={16} />
        </SwipeAction>
      </div>

      <div className="absolute right-0 top-0 flex h-full lg:hidden" style={{ width: revealLeft }} aria-hidden>
        <SwipeAction tone="neutral" width={Math.min(ACTION_WIDTH, revealLeft)} onClick={onDefer}>
          <AppIcon icon={Clock01Icon} size={16} />
        </SwipeAction>
        <SwipeAction tone="danger" width={Math.max(0, revealLeft - ACTION_WIDTH)} onClick={onDelete}>
          <AppIcon icon={Delete01Icon} size={16} />
        </SwipeAction>
      </div>

      <div
        className={`relative bg-[var(--color-bg)]${
          !dragging && offsetX === 0 ? "" : " transition-transform duration-150 ease-out"
        }`}
        style={{ transform: `translateX(${offsetX}px)` }}
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerCancel={reset}
      >
        {children}
      </div>
    </div>
  );
}

type ActionTone = "done" | "neutral" | "danger";

const toneStyles: Record<ActionTone, string> = {
  done: "text-[var(--color-done)] hover:bg-[color-mix(in_srgb,var(--color-done)_12%,transparent)]",
  neutral: "text-[var(--color-text-secondary)] hover:bg-[var(--color-hover-overlay)]",
  danger: "text-[var(--color-overdue)] hover:bg-[color-mix(in_srgb,var(--color-overdue)_10%,transparent)]",
};

const swipeToneBg: Record<ActionTone, string> = {
  done: "color-mix(in srgb, var(--color-done) 14%, var(--color-surface))",
  neutral: "color-mix(in srgb, var(--color-text-secondary) 10%, var(--color-surface))",
  danger: "color-mix(in srgb, var(--color-overdue) 12%, var(--color-surface))",
};

function ActionButton({
  children,
  label,
  tone,
  onClick,
}: {
  children: ReactNode;
  label: string;
  tone: ActionTone;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      title={label}
      aria-label={label}
      onClick={(e) => {
        e.stopPropagation();
        onClick();
      }}
      className={`flex h-7 w-7 items-center justify-center rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-[var(--color-surface)] transition-colors ${toneStyles[tone]}`}
    >
      {children}
    </button>
  );
}

function SwipeAction({
  children,
  tone,
  width,
  onClick,
}: {
  children: ReactNode;
  tone: ActionTone;
  width: number;
  onClick: () => void;
}) {
  if (width < 8) return null;
  return (
    <button
      type="button"
      onClick={(e) => {
        e.stopPropagation();
        onClick();
      }}
      className={`flex h-full items-center justify-center ${toneStyles[tone]}`}
      style={{ width, background: swipeToneBg[tone] }}
    >
      {children}
    </button>
  );
}
