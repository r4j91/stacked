"use client";

import { useEffect } from "react";
import { usePathname } from "next/navigation";

export function useMainFocusOnRoute() {
  const pathname = usePathname();

  useEffect(() => {
    const main = document.querySelector<HTMLElement>("[data-workbench-main]");
    main?.focus({ preventScroll: true });
  }, [pathname]);
}
