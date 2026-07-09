"use client";

import { useCallback, useEffect, useRef, useState } from "react";

export type LabelReorderPosition = "before" | "after";

const HANDLE_DRAG_START_PX = 5;

function dropPositionForRect(clientY: number, rect: DOMRect): LabelReorderPosition {
  return clientY > rect.top + rect.height / 2 ? "after" : "before";
}

function resolveReorderItem(el: EventTarget | null) {
  return (el as HTMLElement | null)?.closest<HTMLElement>("[data-reorder-item]");
}

function findLabelDropTarget(
  clientX: number,
  clientY: number,
  selfId: string,
): { id: string; position: LabelReorderPosition } | null {
  for (const node of document.elementsFromPoint(clientX, clientY)) {
    if (!(node instanceof HTMLElement)) continue;
    if (node.closest("[data-reorder-source]") || node.closest(".reorder-ghost")) continue;

    const host = node.closest<HTMLElement>("[data-reorder-label-id]");
    const id = host?.dataset.reorderLabelId;
    if (id && id !== selfId) {
      const rect = host!.getBoundingClientRect();
      return { id, position: dropPositionForRect(clientY, rect) };
    }
  }

  const rows = [...document.querySelectorAll<HTMLElement>("[data-reorder-label-id]")].filter(
    (el) => el.dataset.reorderLabelId !== selfId,
  );
  if (!rows.length) return null;

  let nearest: { el: HTMLElement; id: string; dist: number } | null = null;
  for (const el of rows) {
    const id = el.dataset.reorderLabelId;
    if (!id) continue;
    const rect = el.getBoundingClientRect();
    const dist =
      clientY < rect.top ? rect.top - clientY : clientY > rect.bottom ? clientY - rect.bottom : 0;
    if (!nearest || dist < nearest.dist) nearest = { el, id, dist };
  }

  if (!nearest || nearest.dist > 40) return null;
  const rect = nearest.el.getBoundingClientRect();
  return { id: nearest.id, position: dropPositionForRect(clientY, rect) };
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

export function applyLabelReorder(
  ids: string[],
  draggedId: string,
  targetId: string,
  position: LabelReorderPosition,
): string[] {
  const from = ids.indexOf(draggedId);
  const targetIndex = ids.indexOf(targetId);
  if (from === -1 || targetIndex === -1 || draggedId === targetId) return ids;

  const next = [...ids];
  next.splice(from, 1);
  let to = targetIndex;
  if (from < targetIndex) to -= 1;
  if (position === "after") to += 1;
  next.splice(to, 0, draggedId);
  return next;
}

export function useLabelListReorder(
  onReorder: (draggedId: string, targetId: string, position: LabelReorderPosition) => void,
) {
  const [draggingId, setDraggingId] = useState<string | null>(null);
  const [overTarget, setOverTarget] = useState<{ id: string; position: LabelReorderPosition } | null>(null);
  const pendingId = useRef<string | null>(null);
  const startPos = useRef({ x: 0, y: 0 });
  const ghostRef = useRef<HTMLElement | null>(null);
  const sourceRef = useRef<HTMLElement | null>(null);
  const ghostOffset = useRef({ x: 0, y: 0 });
  const onReorderRef = useRef(onReorder);
  onReorderRef.current = onReorder;

  const beginDrag = useCallback((id: string, sourceEl: HTMLElement | null, pointerX: number, pointerY: number) => {
    pendingId.current = null;
    if (!sourceEl) return;
    const ghost = mountGhost(sourceEl, pointerX, pointerY);
    ghostRef.current = ghost.clone;
    sourceRef.current = sourceEl;
    ghostOffset.current = { x: ghost.offsetX, y: ghost.offsetY };
    setDraggingId(id);
    setOverTarget(null);
    document.body.style.cursor = "grabbing";
    document.body.style.userSelect = "none";
  }, []);

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
      "data-reorder-label-id": id,
    }),
    [],
  );

  const getHandleProps = useCallback(
    (id: string) => ({
      onPointerDown: (e: React.PointerEvent) => {
        if (e.button !== 0) return;
        e.stopPropagation();
        pendingId.current = id;
        startPos.current = { x: e.clientX, y: e.clientY };
      },
      onPointerMove: (e: React.PointerEvent) => {
        if (pendingId.current !== id) return;
        const dx = Math.abs(e.clientX - startPos.current.x);
        const dy = Math.abs(e.clientY - startPos.current.y);
        if (dx > HANDLE_DRAG_START_PX || dy > HANDLE_DRAG_START_PX) {
          e.stopPropagation();
          beginDrag(id, resolveReorderItem(e.currentTarget) ?? null, e.clientX, e.clientY);
        }
      },
      onPointerUp: () => {
        pendingId.current = null;
      },
      onPointerCancel: () => {
        pendingId.current = null;
      },
    }),
    [beginDrag],
  );

  useEffect(() => {
    if (!draggingId) return;
    const activeId = draggingId;

    function onMove(e: PointerEvent) {
      if (ghostRef.current) {
        moveGhost(
          ghostRef.current,
          e.clientX,
          e.clientY,
          ghostOffset.current.x,
          ghostOffset.current.y,
        );
      }
      setOverTarget(findLabelDropTarget(e.clientX, e.clientY, activeId));
    }

    function onUp(e: PointerEvent) {
      const target = findLabelDropTarget(e.clientX, e.clientY, activeId);
      if (target) onReorderRef.current(activeId, target.id, target.position);
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
  }, [draggingId, endDrag]);

  return {
    getDropProps,
    getHandleProps,
    draggingId,
    overId: overTarget?.id ?? null,
    overPosition: overTarget?.position ?? null,
  };
}
