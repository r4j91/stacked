"use client";

import { useEffect, useRef } from "react";
import { layout } from "@/lib/theme/tokens";
import { useWorkbench } from "@/components/shell/workbench-context";

/** Colapsa a sidebar automaticamente quando o inspector abre em desktop estreito. */
export function useCompactDesktopChrome() {
  const { sidebarCollapsed, toggleSidebar, selectedTaskId } = useWorkbench();
  const autoCollapsedRef = useRef(false);

  useEffect(() => {
    if (typeof window === "undefined") return;

    const inspectorOpen = selectedTaskId !== null;

    if (!inspectorOpen) {
      autoCollapsedRef.current = false;
      return;
    }

    const minCanvas = layout.contentMinWidth + 48;
    const needsCompact = window.innerWidth < layout.desktopChromeMin + minCanvas;

    if (needsCompact && !sidebarCollapsed && !autoCollapsedRef.current) {
      toggleSidebar();
      autoCollapsedRef.current = true;
    }
  }, [selectedTaskId, sidebarCollapsed, toggleSidebar]);
}
