"use client";

import { useEffect, useState } from "react";
import { useWorkbench } from "@/components/shell/workbench-context";
import { useHomeWeather } from "@/lib/hooks/use-home-weather";

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

/** Data média estilo iOS: "Sáb, 9 ago" (compacta na meta-line). */
function formatMediumDate(d: Date): string {
  const weekday = SHORT_WEEKDAYS[d.getDay()];
  const month = SHORT_MONTHS[d.getMonth()];
  const raw = `${weekday}, ${d.getDate()} ${month}`;
  return raw.charAt(0).toUpperCase() + raw.slice(1);
}

/**
 * Header da Home — paridade iOS Saudação (sem trilho do dia):
 * saudação + nome; data · clima; status (atrasadas / hoje).
 */
export function HomeGreetingHeader() {
  const { userProfile, filterCounts } = useWorkbench();
  const weather = useHomeWeather();
  const [now, setNow] = useState(() => new Date());

  useEffect(() => {
    const id = setInterval(() => setNow(new Date()), 60_000);
    return () => clearInterval(id);
  }, []);

  const overdue = filterCounts.overdue ?? 0;
  const isOverdue = overdue > 0;
  const displayName = userProfile.name || "você";

  const status = isOverdue
    ? overdue === 1
      ? "1 atrasada · Toque para resolver"
      : `${overdue} atrasadas · Toque para resolver`
    : filterCounts.today === 0
      ? "Nada para hoje · Em dia"
      : filterCounts.today === 1
        ? "1 para hoje · Nada atrasado"
        : `${filterCounts.today} para hoje · Nada atrasado`;

  const dateLabel = formatMediumDate(now);
  const metaLine = weather?.degreeLabel
    ? `${dateLabel} · ${weather.degreeLabel}`
    : dateLabel;

  return (
    <header className="shrink-0 border-b border-[var(--color-border)] pb-4 pt-5">
      <p className="type-screen-title truncate">
        {greetingPhrase(now.getHours())}, {displayName}
      </p>
      <p className="mt-1.5 truncate text-[13px] font-medium text-[var(--color-text-secondary)]">
        {metaLine}
      </p>
      <p
        className={`mt-1 truncate text-[12.5px] font-medium ${
          isOverdue ? "text-[var(--color-overdue)]" : "text-[var(--color-text-tertiary)]"
        }`}
      >
        {status}
      </p>
    </header>
  );
}

/** @deprecated Use HomeGreetingHeader — mantido para imports antigos. */
export const HomeDayRail = HomeGreetingHeader;
