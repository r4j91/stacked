"use client";

/** Paridade iOS SubtaskProgressRing — anel + número; 100% = check preenchido. */
export function SubtaskProgressRing({
  done,
  total,
  size = 22,
}: {
  done: number;
  total: number;
  size?: number;
}) {
  const safeTotal = Math.max(total, 1);
  const clampedDone = Math.min(Math.max(done, 0), safeTotal);
  const progress = safeTotal > 0 ? clampedDone / safeTotal : 0;
  const isComplete = total > 0 && done >= total;
  const r = (size - 5) / 2;
  const c = size / 2;
  const circumference = 2 * Math.PI * r;
  const offset = circumference * (1 - progress);

  if (isComplete) {
    return (
      <span
        className="inline-flex items-center justify-center rounded-full bg-[var(--color-accent)] text-[var(--color-accent-text)]"
        style={{ width: size, height: size }}
        aria-hidden
      >
        <svg width={size * 0.55} height={size * 0.55} viewBox="0 0 24 24" fill="none">
          <path
            d="M5 13l4 4L19 7"
            stroke="currentColor"
            strokeWidth="3"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </svg>
      </span>
    );
  }

  return (
    <span className="relative inline-flex" style={{ width: size, height: size }} aria-hidden>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} className="block">
        <circle
          cx={c}
          cy={c}
          r={r}
          fill="none"
          stroke="var(--color-text-tertiary)"
          strokeOpacity={0.28}
          strokeWidth={2.5}
        />
        <circle
          cx={c}
          cy={c}
          r={r}
          fill="none"
          stroke="var(--color-accent)"
          strokeWidth={2.5}
          strokeLinecap="round"
          strokeDasharray={circumference}
          strokeDashoffset={offset}
          transform={`rotate(-90 ${c} ${c})`}
        />
      </svg>
      <span
        className="absolute inset-0 flex items-center justify-center font-bold tabular-nums text-[var(--color-text-secondary)]"
        style={{ fontSize: size * 0.38 }}
      >
        {clampedDone}
      </span>
    </span>
  );
}
