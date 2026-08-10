"use client";

import { useSyncExternalStore } from "react";
import {
  DEFAULT_INSTALLMENT_PROGRESS_ON_CARD,
  readInstallmentProgressOnCard,
  subscribeInstallmentProgressOnCard,
} from "@/lib/theme/installment-progress-on-card";

export function useInstallmentProgressOnCard(): boolean {
  return useSyncExternalStore(
    subscribeInstallmentProgressOnCard,
    readInstallmentProgressOnCard,
    () => DEFAULT_INSTALLMENT_PROGRESS_ON_CARD,
  );
}
