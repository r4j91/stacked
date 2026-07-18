"use client";

import { useSyncExternalStore } from "react";
import {
  DEFAULT_TASK_ROW_LAYOUT,
  readTaskRowLayout,
  subscribeTaskRowLayout,
  type TaskRowLayout,
} from "@/lib/theme/task-row-layout";

export function useTaskRowLayout(): TaskRowLayout {
  return useSyncExternalStore(
    subscribeTaskRowLayout,
    readTaskRowLayout,
    () => DEFAULT_TASK_ROW_LAYOUT,
  );
}
