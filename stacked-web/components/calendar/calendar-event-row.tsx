"use client";

import { memo } from "react";
import type { CalendarEvent } from "@/lib/types/calendar-event";
import { formatEventTime } from "@/lib/utils/schedule-items";
import { AppIcon } from "@/components/ui/app-icon";
import { Calendar03Icon } from "@/lib/icons/nav-icons";

type CalendarEventRowProps = {
  event: CalendarEvent;
  onOpen?: () => void;
};

export const CalendarEventRow = memo(function CalendarEventRow({ event, onOpen }: CalendarEventRowProps) {
  const accent = event.calendarColor ?? "var(--color-accent)";
  const time = formatEventTime(event);
  const subtitle = event.isAllDay
    ? `Dia inteiro · ${event.calendarTitle}`
    : event.calendarTitle;

  function handleClick() {
    if (event.htmlLink) {
      window.open(event.htmlLink, "_blank", "noopener,noreferrer");
    }
    onOpen?.();
  }

  return (
    <button
      type="button"
      onClick={handleClick}
      className="scroll-list-item schedule-row mb-0.5 flex min-h-[52px] w-full cursor-pointer items-center gap-2.5 rounded-[var(--radius-md)] border border-transparent bg-[var(--color-surface)] px-3 py-2 text-left"
      aria-label={`${event.title}, compromisso do calendário, ${subtitle}`}
    >
      <span className="h-8 w-[3px] shrink-0 rounded-full" style={{ background: accent }} />
      <span
        className="flex h-7 w-7 shrink-0 items-center justify-center rounded-[7px]"
        style={{ background: `color-mix(in srgb, ${accent} 12%, transparent)`, color: accent }}
      >
        <AppIcon icon={Calendar03Icon} size={14} strokeWidth={2} />
      </span>
      <span className="min-w-0 flex-1">
        <span className="block truncate text-[15.5px] font-semibold leading-snug text-[var(--color-text)]">
          {event.title}
        </span>
        <span className="mt-0.5 block truncate text-[12.5px] text-[var(--color-text-tertiary)]">
          {subtitle}
        </span>
      </span>
      {time && (
        <span className="shrink-0 text-xs font-semibold tabular-nums text-[var(--color-text-secondary)]">
          {time}
        </span>
      )}
    </button>
  );
});
