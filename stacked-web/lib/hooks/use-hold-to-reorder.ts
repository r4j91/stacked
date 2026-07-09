"use client";

import { useCallback, useEffect, useRef, useState } from "react";

const HOLD_MS = 380;
const MOVE_CANCEL_PX = 10;
const HANDLE_DRAG_START_PX = 5;

export type ReorderDropKind = "task" | "section";

export type ReorderDropTarget = {
  id: string;
  kind: ReorderDropKind;
};

type DragVariant = "hold" | "handle";

function isInteractiveTarget(target: EventTarget | null) {
  return Boolean(
    (target as HTMLElement | null)?.closest("button, a, input, textarea, [data-no-reorder]"),
  );
}

function findTaskDropTarget(clientX: number, clientY: number, selfId: string): ReorderDropTarget | null {
  const elements = document.elementsFromPoint(clientX, clientY);

  for (const node of elements) {
    if (!(node instanceof HTMLElement)) continue;
    if (node.closest("[data-reorder-dragging]")) continue;

    const sectionHost = node.closest<HTMLElement>("[data-task-drop-section]");
    const sectionId = sectionHost?.dataset.taskDropSection;
    if (sectionId) return { id: sectionId, kind: "section" };

    const taskHost = node.closest<HTMLElement>("[data-reorder-task-id]");
    const taskId = taskHost?.dataset.reorderTaskId;
    if (taskId && taskId !== selfId) return { id: taskId, kind: "task" };
  }

  return null;
}

function findSectionDropTarget(clientX: number, clientY: number, selfId: string): ReorderDropTarget | null {
  const el = document.elementFromPoint(clientX, clientY);
  const host = el?.closest<HTMLElement>("[data-reorder-section-id]");
  const id = host?.dataset.reorderSectionId;
  if (!id || id === selfId) return null;
  return { id, kind: "section" };
}

export function useHoldToReorder(
  onReorder: (draggedId: string, targetId: string, targetKind: ReorderDropKind) => void,
  mode: "task" | "section" = "task",
) {
  const [draggingId, setDraggingId] = useState<string | null>(null);
  const [overTarget, setOverTarget] = useState<ReorderDropTarget | null>(null);
  const holdTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const pendingId = useRef<string | null>(null);
  const pendingVariant = useRef<DragVariant | null>(null);
  const startPos = useRef({ x: 0, y: 0 });
  const suppressClickRef = useRef(false);
  const onReorderRef = useRef(onReorder);
  onReorderRef.current = onReorder;

  const itemAttr = mode === "task" ? "data-reorder-task-id" : "data-reorder-section-id";
  const findTarget = mode === "task" ? findTaskDropTarget : findSectionDropTarget;

  const clearHoldTimer = useCallback(() => {
    if (holdTimer.current) {
      clearTimeout(holdTimer.current);
      holdTimer.current = null;
    }
  }, []);

  const cancelPending = useCallback(() => {
    clearHoldTimer();
    pendingId.current = null;
    pendingVariant.current = null;
  }, [clearHoldTimer]);

  const beginDrag = useCallback(
    (id: string) => {
      clearHoldTimer();
      pendingId.current = null;
      pendingVariant.current = null;
      setDraggingId(id);
      setOverTarget(null);
      document.body.style.cursor = "grabbing";
      document.body.style.userSelect = "none";
    },
    [clearHoldTimer],
  );

  const getDropProps = useCallback(
    (id: string) => ({
      [itemAttr]: id,
    }),
    [itemAttr],
  );

  const getHoldProps = useCallback(
    (id: string, enabled = true) => ({
      onPointerDown: (e: React.PointerEvent) => {
        if (!enabled || e.button !== 0 || isInteractiveTarget(e.target)) return;
        pendingId.current = id;
        pendingVariant.current = "hold";
        startPos.current = { x: e.clientX, y: e.clientY };
        clearHoldTimer();
        holdTimer.current = setTimeout(() => beginDrag(id), HOLD_MS);
      },
      onPointerMove: (e: React.PointerEvent) => {
        if (pendingId.current !== id || pendingVariant.current !== "hold" || !holdTimer.current) return;
        const dx = Math.abs(e.clientX - startPos.current.x);
        const dy = Math.abs(e.clientY - startPos.current.y);
        if (dx > MOVE_CANCEL_PX || dy > MOVE_CANCEL_PX) cancelPending();
      },
      onPointerUp: () => cancelPending(),
      onPointerCancel: () => cancelPending(),
    }),
    [beginDrag, cancelPending, clearHoldTimer],
  );

  const getHandleProps = useCallback(
    (id: string, enabled = true) => ({
      onPointerDown: (e: React.PointerEvent) => {
        if (!enabled || e.button !== 0) return;
        e.stopPropagation();
        pendingId.current = id;
        pendingVariant.current = "handle";
        startPos.current = { x: e.clientX, y: e.clientY };
      },
      onPointerMove: (e: React.PointerEvent) => {
        if (pendingId.current !== id || pendingVariant.current !== "handle") return;
        const dx = Math.abs(e.clientX - startPos.current.x);
        const dy = Math.abs(e.clientY - startPos.current.y);
        if (dx > HANDLE_DRAG_START_PX || dy > HANDLE_DRAG_START_PX) {
          e.stopPropagation();
          beginDrag(id);
        }
      },
      onPointerUp: () => cancelPending(),
      onPointerCancel: () => cancelPending(),
    }),
    [beginDrag, cancelPending],
  );

  const consumeClick = useCallback(() => {
    if (!suppressClickRef.current) return false;
    suppressClickRef.current = false;
    return true;
  }, []);

  useEffect(() => {
    if (!draggingId) return;
    const activeId = draggingId;

    function onMove(e: PointerEvent) {
      setOverTarget(findTarget(e.clientX, e.clientY, activeId));
    }

    function onUp(e: PointerEvent) {
      const target = findTarget(e.clientX, e.clientY, activeId);
      if (target) {
        suppressClickRef.current = true;
        onReorderRef.current(activeId, target.id, target.kind);
      }
      setDraggingId(null);
      setOverTarget(null);
      document.body.style.cursor = "";
      document.body.style.userSelect = "";
    }

    window.addEventListener("pointermove", onMove);
    window.addEventListener("pointerup", onUp);
    window.addEventListener("pointercancel", onUp);
    return () => {
      window.removeEventListener("pointermove", onMove);
      window.removeEventListener("pointerup", onUp);
      window.removeEventListener("pointercancel", onUp);
    };
  }, [draggingId, findTarget]);

  return {
    getDropProps,
    getHoldProps,
    getHandleProps,
    draggingId,
    overId: overTarget?.id ?? null,
    overKind: overTarget?.kind ?? null,
    consumeClick,
  };
}
