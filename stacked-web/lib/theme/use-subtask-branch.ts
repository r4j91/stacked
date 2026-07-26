"use client";

import { useSyncExternalStore } from "react";
import {
  DEFAULT_SUBTASK_BRANCH,
  readSubtaskBranch,
  subscribeSubtaskBranch,
} from "@/lib/theme/subtask-branch";

export function useSubtaskBranch(): boolean {
  return useSyncExternalStore(
    subscribeSubtaskBranch,
    readSubtaskBranch,
    () => DEFAULT_SUBTASK_BRANCH,
  );
}
