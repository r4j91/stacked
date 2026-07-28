"use client";

import { useSyncExternalStore } from "react";
import {
  DEFAULT_DISPLAY_MODE,
  readDisplayMode,
  subscribeDisplayMode,
} from "@/lib/theme/display-mode";

export function useDisplayMode() {
  return useSyncExternalStore(
    subscribeDisplayMode,
    readDisplayMode,
    () => DEFAULT_DISPLAY_MODE,
  );
}
