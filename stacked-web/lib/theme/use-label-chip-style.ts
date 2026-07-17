"use client";

import { useSyncExternalStore } from "react";
import {
  DEFAULT_LABEL_CHIP_STYLE,
  readLabelChipStyle,
  subscribeLabelChipStyle,
  type LabelChipStyle,
} from "@/lib/theme/label-chip-style";

export function useLabelChipStyle(): LabelChipStyle {
  return useSyncExternalStore(
    subscribeLabelChipStyle,
    readLabelChipStyle,
    () => DEFAULT_LABEL_CHIP_STYLE,
  );
}
