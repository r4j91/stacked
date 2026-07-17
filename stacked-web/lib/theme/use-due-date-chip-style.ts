"use client";

import { useSyncExternalStore } from "react";
import {
  DEFAULT_DUE_DATE_CHIP_STYLE,
  readDueDateChipStyle,
  subscribeDueDateChipStyle,
  type DueDateChipStyle,
} from "@/lib/theme/due-date-chip-style";

export function useDueDateChipStyle(): DueDateChipStyle {
  return useSyncExternalStore(
    subscribeDueDateChipStyle,
    readDueDateChipStyle,
    () => DEFAULT_DUE_DATE_CHIP_STYLE,
  );
}
