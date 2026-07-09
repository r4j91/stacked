"use client";

import { useCallback, useEffect, useRef, useState } from "react";

const HOLD_MS = 380;
const MOVE_CANCEL_PX = 10;
const HANDLE_DRAG_START_PX = 5;

export type ReorderDropKind = "task" | "section";
export type ReorderDropPosition = "before" | "after";

export type ReorderDropTarget = {
  id: string;
  kind: ReorderDropKind;
  position: ReorderDropPosition;
};

type DragVariant = "hold" | "handle";

function isInteractiveTarget(target: EventTarget | null) {
  return Boolean(
    (target as HTMLElement | null)?.closest("button, a, input, textarea, [data-no-reorder]"),
  );
}

function dropPositionForRect(clientY: number, rect: DOMRect): ReorderDropPosition {
  return clientY > rect.top + rect.height / 2 ? "after" : "before";
}

function findTaskDropTarget(clientX: number, clientY: number, selfId: string): ReorderDropTarget | null {
  const elements = document.elementsFromPoint(clientX, clientY);

  for (const node of elements) {
    if (!(node instanceof HTMLElement)) continue;
    if (node.closest("[data-reorder-source]")) continue;
    if (node.closest(".reorder-ghost")) continue;

    const sectionHost = node.closest<HTMLElement>("[data-task-drop-section]");
    const sectionId = sectionHost?.dataset.taskDropSection;
    if (sectionId) {
      const rect = sectionHost.getBoundingClientRect();
      return { id: sectionId, kind: "section", position: dropPositionForRect(clientY, rect) };
    }

    const taskHost = node.closest<HTMLElement>("[data-reorder-task-id]");
    const taskId = taskHost?.dataset.reorderTaskId;
    if (taskId && taskId !== selfId) {
      const rect = taskHost.getBoundingClientRect();
      return { id: taskId, kind: "task", position: dropPositionForRect(clientY, rect) };
    }
  }

  const taskRows = [...document.querySelectorAll<HTMLElement>("[data-reorder-task-id]")].filter(
    (el) => el.dataset.reorderTaskId !== selfId,
  );
  if (!taskRows.length) return null;

  let nearest: { el: HTMLElement; id: string; dist: number } | null = null;
  for (const el of taskRows) {
    const id = el.dataset.reorderTaskId;
    if (!id) continue;
    const rect = el.getBoundingClientRect();
    const dist =
      clientY < rect.top
        ? rect.top - clientY
        : clientY > rect.bottom
          ? clientY - rect.bottom
          : 0;
    if (!nearest || dist < nearest.dist) {
      nearest = { el, id, dist };
    }
  }

  if (!nearest || nearest.dist > 48) return null;

  const rect = nearest.el.getBoundingClientRect();
  const position: ReorderDropPosition =
    clientY > rect.bottom - 4 ? "after" : clientY < rect.top + 4 ? "before" : dropPositionForRect(clientY, rect);
  return { id: nearest.id, kind: "task", position };
}

function findSectionDropTarget(clientX: number, clientY: number, selfId: string): ReorderDropTarget | null {
  const elements = document.elementsFromPoint(clientX, clientY);

  for (const node of elements) {
    if (!(node instanceof HTMLElement)) continue;
    if (node.closest("[data-reorder-source]")) continue;
    if (node.closest(".reorder-ghost")) continue;

    const host = node.closest<HTMLElement>("[data-reorder-section-id]");
    const id = host?.dataset.reorderSectionId;
    if (id && id !== selfId) {
      const rect = host.getBoundingClientRect();
      return { id, kind: "section", position: dropPositionForRect(clientY, rect) };
    }
  }

  const sectionRows = [...document.querySelectorAll<HTMLElement>("[data-reorder-section-id]")].filter(
    (el) => el.dataset.reorderSectionId !== selfId,
  );
  if (!sectionRows.length) return null;

  let nearest: { el: HTMLElement; id: string; dist: number } | null = null;
  for (const el of sectionRows) {
    const id = el.dataset.reorderSectionId;
    if (!id) continue;
    const rect = el.getBoundingClientRect();
    const dist =
      clientY < rect.top
        ? rect.top - clientY
        : clientY > rect.bottom
          ? clientY - rect.bottom
          : 0;
    if (!nearest || dist < nearest.dist) {
      nearest = { el, id, dist };
    }
  }

  if (!nearest || nearest.dist > 56) return null;

  const rect = nearest.el.getBoundingClientRect();
  return { id: nearest.id, kind: "section", position: dropPositionForRect(clientY, rect) };
}

function resolveReorderItem(el: EventTarget | null) {
  return (el as HTMLElement | null)?.closest<HTMLElement>("[data-reorder-item]");
}

function mountGhost(source: HTMLElement, pointerX: number, pointerY: number) {
  const rect = source.getBoundingClientRect();
  const clone = source.cloneNode(true) as HTMLElement;
  clone.classList.add("reorder-ghost");
  clone.setAttribute("aria-hidden", "true");
  clone.querySelectorAll("button").forEach((btn) => btn.setAttribute("tabindex", "-1"));

  const offsetX = pointerX - rect.left;
  const offsetY = pointerY - rect.top;

  clone.style.width = `${rect.width}px`;
  clone.style.left = `${rect.left}px`;
  clone.style.top = `${rect.top}px`;
  clone.style.setProperty("--reorder-offset-x", `${offsetX}px`);
  clone.style.setProperty("--reorder-offset-y", `${offsetY}px`);

  document.body.appendChild(clone);
  source.dataset.reorderSource = "";
  source.classList.add("reorder-source-placeholder");

  return { clone, offsetX, offsetY };
}

function moveGhost(clone: HTMLElement, pointerX: number, pointerY: number, offsetX: number, offsetY: number) {
  clone.style.left = `${pointerX - offsetX}px`;
  clone.style.top = `${pointerY - offsetY}px`;
}

function unmountGhost(clone: HTMLElement | null, source: HTMLElement | null) {
  clone?.remove();
  if (source) {
    delete source.dataset.reorderSource;
    source.classList.remove("reorder-source-placeholder");
  }
}

export function useHoldToReorder(
  onReorder: (
    draggedId: string,
    targetId: string,
    targetKind: ReorderDropKind,
    position: ReorderDropPosition,
  ) => void,
  mode: "task" | "section" = "task",
) {
  const [draggingId, setDraggingId] = useState<string | null>(null);
  const [overTarget, setOverTarget] = useState<ReorderDropTarget | null>(null);
  const holdTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const pendingId = useRef<string | null>(null);
  const pendingVariant = useRef<DragVariant | null>(null);
  const startPos = useRef({ x: 0, y: 0 });
  const suppressClickRef = useRef(false);
  const ghostRef = useRef<HTMLElement | null>(null);
  const sourceRef = useRef<HTMLElement | null>(null);
  const ghostOffset = useRef({ x: 0, y: 0 });
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
    (id: string, sourceEl: HTMLElement | null, pointerX: number, pointerY: number) => {
      clearHoldTimer();
      pendingId.current = null;
      pendingVariant.current = null;
      if (!sourceEl) return;

      const ghost = mountGhost(sourceEl, pointerX, pointerY);
      ghostRef.current = ghost.clone;
      sourceRef.current = sourceEl;
      ghostOffset.current = { x: ghost.offsetX, y: ghost.offsetY };

      setDraggingId(id);
      setOverTarget(null);
      document.body.style.cursor = "grabbing";
      document.body.style.userSelect = "none";
    },
    [clearHoldTimer],
  );

  const endDrag = useCallback(() => {
    unmountGhost(ghostRef.current, sourceRef.current);
    ghostRef.current = null;
    sourceRef.current = null;
    setDraggingId(null);
    setOverTarget(null);
    document.body.style.cursor = "";
    document.body.style.userSelect = "";
  }, []);

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
        holdTimer.current = setTimeout(() => {
          beginDrag(id, resolveReorderItem(e.currentTarget) ?? null, e.clientX, e.clientY);
        }, HOLD_MS);
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
          beginDrag(id, resolveReorderItem(e.currentTarget) ?? null, e.clientX, e.clientY);
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
      if (ghostRef.current) {
        moveGhost(ghostRef.current, e.clientX, e.clientY, ghostOffset.current.x, ghostOffset.current.y);
      }
      setOverTarget(findTarget(e.clientX, e.clientY, activeId));
    }

    function onUp(e: PointerEvent) {
      const target = findTarget(e.clientX, e.clientY, activeId);
      if (target) {
        suppressClickRef.current = true;
        onReorderRef.current(activeId, target.id, target.kind, target.position);
      }
      endDrag();
    }

    window.addEventListener("pointermove", onMove);
    window.addEventListener("pointerup", onUp);
    window.addEventListener("pointercancel", onUp);
    return () => {
      window.removeEventListener("pointermove", onMove);
      window.removeEventListener("pointerup", onUp);
      window.removeEventListener("pointercancel", onUp);
    };
  }, [draggingId, endDrag, findTarget]);

  return {
    getDropProps,
    getHoldProps,
    getHandleProps,
    draggingId,
    overId: overTarget?.id ?? null,
    overKind: overTarget?.kind ?? null,
    overPosition: overTarget?.position ?? null,
    consumeClick,
  };
}
