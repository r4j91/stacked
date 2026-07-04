import type { CalendarEvent, GoogleCalendarStatus } from "@/lib/types/calendar-event";

export async function fetchGoogleCalendarStatus(): Promise<GoogleCalendarStatus> {
  const res = await fetch("/api/google/calendar/status", { cache: "no-store" });
  if (res.status === 401) {
    return { configured: false, connected: false, email: null, importEnabled: false };
  }
  if (!res.ok) {
    return { configured: false, connected: false, email: null, importEnabled: false };
  }
  return res.json() as Promise<GoogleCalendarStatus>;
}

export async function fetchGoogleCalendarEvents(from: Date, to: Date): Promise<CalendarEvent[]> {
  const params = new URLSearchParams({
    from: from.toISOString(),
    to: to.toISOString(),
  });
  const res = await fetch(`/api/google/calendar/events?${params}`, { cache: "no-store" });
  if (!res.ok) {
    const data = (await res.json().catch(() => ({}))) as { events?: CalendarEvent[] };
    return data.events ?? [];
  }
  const data = (await res.json()) as { events: CalendarEvent[] };
  return data.events ?? [];
}

export async function setGoogleCalendarImport(importEnabled: boolean): Promise<void> {
  await fetch("/api/google/calendar/import", {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ importEnabled }),
  });
}

export async function disconnectGoogleCalendar(): Promise<void> {
  await fetch("/api/google/calendar/status", { method: "DELETE" });
}

export function connectGoogleCalendarUrl(): string {
  return "/api/google/calendar/connect";
}
