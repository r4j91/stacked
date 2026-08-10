"use client";

import type { InstallmentProgressSnapshot } from "@/lib/utils/installment-progress";

type InstallmentProgressLineProps = {
  snapshot: InstallmentProgressSnapshot;
  done?: boolean;
};

/** Paridade iOS TaskRow.installmentProgressLine — “3/12 pagas · R$ X restante” + barra. */
export function InstallmentProgressLine({
  snapshot,
  done = false,
}: InstallmentProgressLineProps) {
  const pct = Math.min(100, Math.max(0, snapshot.fraction * 100));
  return (
    <div className="mt-1.5 min-w-0" aria-label={snapshot.label}>
      <p
        className={`truncate text-[12px] font-semibold leading-tight ${
          done ? "text-[var(--color-accent)]/45" : "text-[var(--color-accent)]"
        }`}
      >
        {snapshot.label}
      </p>
      <div className="mt-1.5 h-[3px] w-full overflow-hidden rounded-full bg-[var(--color-border)]">
        <div
          className={`h-full rounded-full ${
            done ? "bg-[var(--color-accent)]/45" : "bg-[var(--color-accent)]"
          }`}
          style={{ width: `${pct}%` }}
        />
      </div>
    </div>
  );
}
