"use client";

import { useEffect, useState } from "react";
import { useWorkbench } from "@/components/shell/workbench-context";

const SHORT_WEEKDAYS = ["dom", "seg", "ter", "qua", "qui", "sex", "sáb"];
const SHORT_MONTHS = [
  "jan",
  "fev",
  "mar",
  "abr",
  "mai",
  "jun",
  "jul",
  "ago",
  "set",
  "out",
  "nov",
  "dez",
];

function greetingPhrase(hour: number): string {
  if (hour < 5) return "Boa madrugada";
  if (hour < 12) return "Bom dia";
  if (hour < 18) return "Boa tarde";
  return "Boa noite";
}

function dayProgress(d: Date): number {
  const minutes = d.getHours() * 60 + d.getMinutes();
  return minutes / 1440;
}

function formatClock(d: Date): string {
  return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
}

function formatDateline(d: Date): string {
  return `${SHORT_WEEKDAYS[d.getDay()]}, ${d.getDate()} ${SHORT_MONTHS[d.getMonth()]}`;
}

/**
 * Hero "Trilho do dia" (paridade iOS HomeHeroDayRailCard): saudação + trilho
 * contínuo de progresso do dia + relógio. Linguagem "Quiet Control Room" —
 * tons muted, sem cor de destaque exceto o marcador de posição atual.
 */
export function HomeDayRail() {
  const { userProfile, filterCounts } = useWorkbench();
  const [now, setNow] = useState(() => new Date());

  useEffect(() => {
    const id = setInterval(() => setNow(new Date()), 30_000);
    return () => clearInterval(id);
  }, []);

  const overdue = filterCounts.overdue ?? 0;
  const isOverdue = overdue > 0;
  const accent = isOverdue ? "var(--color-overdue)" : "var(--color-accent)";
  const displayName = userProfile.name || "você";

  const status = isOverdue
    ? `${overdue} tarefa${overdue === 1 ? "" : "s"} atrasada${overdue === 1 ? "" : "s"}`
    : filterCounts.today > 0
      ? `${filterCounts.today} tarefa${filterCounts.today === 1 ? "" : "s"} para hoje`
      : "Nada agendado para hoje";

  return (
    <header className="shrink-0 border-b border-[var(--color-border)] pb-4 pt-5">
      <p className="type-screen-title truncate">
        {greetingPhrase(now.getHours())}, {displayName}
      </p>

      <div className="mt-3.5 flex items-center gap-3">
        <DayProgressRail progress={dayProgress(now)} accent={accent} />
        <span className="shrink-0 text-[13px] font-bold tabular-nums text-[var(--color-text)]">
          {formatClock(now)}
        </span>
      </div>

      <div className="mt-2.5 flex items-baseline justify-between gap-2">
        <p
          className={`truncate text-[13px] font-medium ${
            isOverdue ? "text-[var(--color-overdue)]" : "text-[var(--color-text-secondary)]"
          }`}
        >
          {status}
        </p>
        <span className="shrink-0 text-[11px] font-medium tracking-wide text-[var(--color-text-tertiary)]">
          {formatDateline(now)}
        </span>
      </div>
    </header>
  );
}

function DayProgressRail({ progress, accent }: { progress: number; accent: string }) {
  const pct = Math.min(100, Math.max(0, progress * 100));
  return (
    <div className="relative h-3 min-w-0 flex-1" aria-hidden>
      <div className="absolute left-0 right-0 top-1/2 h-[2px] -translate-y-1/2 rounded-full bg-[var(--color-text)]/10" />
      <div
        className="absolute left-0 top-1/2 h-[2px] -translate-y-1/2 rounded-full"
        style={{
          width: `${Math.max(1, pct)}%`,
          background: `linear-gradient(to right, color-mix(in srgb, ${accent} 62%, transparent), color-mix(in srgb, ${accent} 28%, transparent))`,
        }}
      />
      {[0, 25, 50, 75].map((mark) => (
        <span
          key={mark}
          className="absolute top-1/2 h-[5px] w-[1.5px] -translate-y-1/2 rounded-full bg-[var(--color-text)]"
          style={{ left: `${mark}%`, opacity: mark <= pct + 0.5 ? 0.4 : 0.15 }}
        />
      ))}
      <span
        className="absolute top-1/2 h-[7px] w-[7px] -translate-x-1/2 -translate-y-1/2 rounded-full ring-1 ring-black/20"
        style={{ left: `${pct}%`, background: accent }}
      />
    </div>
  );
}
