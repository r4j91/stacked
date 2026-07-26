"use client";

import { useSyncExternalStore } from "react";
import {
  DEFAULT_SUBTASK_PROGRESS_RING,
  readSubtaskProgressRing,
  subscribeSubtaskProgressRing,
} from "@/lib/theme/subtask-progress-ring";

export function useSubtaskProgressRing(): boolean {
  return useSyncExternalStore(
    subscribeSubtaskProgressRing,
    readSubtaskProgressRing,
    () => DEFAULT_SUBTASK_PROGRESS_RING,
  );
}
