"use client";

import { useEffect, useState } from "react";
import { useWorkbench } from "@/components/shell/workbench-context";

export function useTaskListKeyboard(visibleTaskIds: string[], resetKey?: string | number) {
  const {
    selectTask,
    toggleTaskDone,
    paletteOpen,
    quickAddOpen,
    shortcutsOpen,
  } = useWorkbench();

  const [keyboardIndex, setKeyboardIndex] = useState(-1);

  const focusedTaskId = keyboardIndex >= 0 ? visibleTaskIds[keyboardIndex] ?? null : null;

  useEffect(() => {
    setKeyboardIndex(-1);
  }, [resetKey, visibleTaskIds.length]);

  useEffect(() => {
    if (!visibleTaskIds.length) return;

    function isTyping() {
      const el = document.activeElement as HTMLElement | null;
      return el?.tagName === "INPUT" || el?.tagName === "TEXTAREA" || el?.isContentEditable;
    }

    function onKey(e: KeyboardEvent) {
      if (paletteOpen || quickAddOpen || shortcutsOpen || isTyping()) return;

      const down = e.key === "ArrowDown" || e.key === "j" || e.key === "J";
      const up = e.key === "ArrowUp" || e.key === "k" || e.key === "K";

      if (down) {
        e.preventDefault();
        setKeyboardIndex((i) => (i < 0 ? 0 : Math.min(i + 1, visibleTaskIds.length - 1)));
      } else if (up) {
        e.preventDefault();
        setKeyboardIndex((i) => Math.max(i <= 0 ? 0 : i - 1, 0));
      } else if (e.key === "Enter" && keyboardIndex >= 0) {
        e.preventDefault();
        const id = visibleTaskIds[keyboardIndex];
        if (id) selectTask(id);
      } else if (e.key === " " && keyboardIndex >= 0) {
        e.preventDefault();
        const id = visibleTaskIds[keyboardIndex];
        if (id) toggleTaskDone(id);
      }
    }

    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [
    visibleTaskIds,
    keyboardIndex,
    paletteOpen,
    quickAddOpen,
    shortcutsOpen,
    selectTask,
    toggleTaskDone,
  ]);

  useEffect(() => {
    if (!focusedTaskId) return;
    document.querySelector(`[data-task-id="${focusedTaskId}"]`)?.scrollIntoView({ block: "nearest" });
  }, [focusedTaskId]);

  return { focusedTaskId, keyboardIndex };
}
