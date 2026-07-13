"use client";

import { type ReactNode } from "react";
import { createPortal } from "react-dom";

/** Portal síncrono no client — evita perder o 1º useLayoutEffect (ex.: menus). */
export function ClientPortal({ children }: { children: ReactNode }) {
  if (typeof document === "undefined") return null;
  return createPortal(children, document.body);
}
