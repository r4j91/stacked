"use client";

import { useMemo, useState } from "react";
import { AppIcon } from "@/components/ui/app-icon";
import { ArrowRight01Icon } from "@/lib/icons/nav-icons";
import { dateKey, monthLabel, parseDueDate, startOfDay, toDateStr } from "@/lib/utils/date";

const WEEKDAYS = ["D", "S", "T", "Q", "Q", "S", "S"];

type CalendarGridProps = {
  value?: string | null;
  onChange: (date: string) => void;
};

export function CalendarGrid({ value, onChange }: CalendarGridProps) {
  const selected = value ? parseDueDate(value) : null;
  const [viewDate, setViewDate] = useState(() => selected ?? startOfDay(new Date()));

  const cells = useMemo(() => {
    const year = viewDate.getFullYear();
    const month = viewDate.getMonth();
    const first = new Date(year, month, 1);
    const startPad = first.getDay();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const items: { key: string; day: number | null; date?: Date }[] = [];

    for (let i = 0; i < startPad; i++) items.push({ key: `pad-${i}`, day: null });
    for (let d = 1; d <= daysInMonth; d++) {
      const date = startOfDay(new Date(year, month, d));
      items.push({ key: dateKey(date), day: d, date });
    }
    return items;
  }, [viewDate]);

  function shiftMonth(delta: number) {
    setViewDate((prev) => startOfDay(new Date(prev.getFullYear(), prev.getMonth() + delta, 1)));
  }

  const todayKey = dateKey(startOfDay(new Date()));

  return (
    <div className="rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-[var(--color-surface-variant)] p-3">
      <div className="mb-3 flex items-center justify-between">
        <button
          type="button"
          onClick={() => shiftMonth(-1)}
          className="flex h-7 w-7 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-secondary)] hover:bg-[var(--color-hover-overlay)]"
          aria-label="Mês anterior"
        >
          <AppIcon icon={ArrowRight01Icon} size={16} className="rotate-180" />
        </button>
        <span className="text-sm font-semibold capitalize text-[var(--color-text)]">{monthLabel(viewDate)}</span>
        <button
          type="button"
          onClick={() => shiftMonth(1)}
          className="flex h-7 w-7 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-secondary)] hover:bg-[var(--color-hover-overlay)]"
          aria-label="Próximo mês"
        >
          <AppIcon icon={ArrowRight01Icon} size={16} />
        </button>
      </div>

      <div className="mb-1 grid grid-cols-7 gap-0.5">
        {WEEKDAYS.map((d) => (
          <span key={d} className="py-1 text-center text-[10px] font-semibold text-[var(--color-text-tertiary)]">
            {d}
          </span>
        ))}
      </div>

      <div className="grid grid-cols-7 gap-0.5">
        {cells.map((cell) => {
          if (!cell.day || !cell.date) {
            return <span key={cell.key} className="h-8" />;
          }
          const key = dateKey(cell.date);
          const isSelected = selected ? dateKey(selected) === key : false;
          const isToday = key === todayKey;
          return (
            <button
              key={cell.key}
              type="button"
              onClick={() => onChange(toDateStr(cell.date!))}
              className={`flex h-8 items-center justify-center rounded-[var(--radius-sm)] text-sm transition-colors ${
                isSelected
                  ? "bg-[var(--color-accent)] font-semibold text-[var(--color-accent-text)]"
                  : isToday
                    ? "font-semibold text-[var(--color-text)] ring-1 ring-[var(--color-border-strong)]"
                    : "text-[var(--color-text-secondary)] hover:bg-[var(--color-hover-overlay)] hover:text-[var(--color-text)]"
              }`}
            >
              {cell.day}
            </button>
          );
        })}
      </div>
    </div>
  );
}
