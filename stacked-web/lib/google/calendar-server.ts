import { createAdminClient } from "@/lib/supabase/admin";
import { GOOGLE_CALENDAR_SCOPE, isGoogleCalendarConfigured } from "@/lib/google/config";
import type { CalendarEvent, GoogleCalendarConnectionRow, GoogleCalendarStatus } from "@/lib/types/calendar-event";

const TOKEN_URL = "https://oauth2.googleapis.com/token";
const CALENDAR_API = "https://www.googleapis.com/calendar/v3";

export async function getConnection(userId: string): Promise<GoogleCalendarConnectionRow | null> {
  const admin = createAdminClient();
  const { data, error } = await admin
    .from("google_calendar_connections")
    .select("*")
    .eq("user_id", userId)
    .maybeSingle();
  if (error) throw new Error(error.message);
  return data as GoogleCalendarConnectionRow | null;
}

export async function getCalendarStatus(userId: string): Promise<GoogleCalendarStatus> {
  if (!isGoogleCalendarConfigured()) {
    return { configured: false, connected: false, email: null, importEnabled: false };
  }
  try {
    const row = await getConnection(userId);
    if (!row) {
      return { configured: true, connected: false, email: null, importEnabled: false };
    }
    return {
      configured: true,
      connected: true,
      email: row.google_account_email,
      importEnabled: row.import_enabled,
    };
  } catch {
    return { configured: true, connected: false, email: null, importEnabled: false };
  }
}

export async function upsertConnection(
  userId: string,
  input: {
    refreshToken: string;
    accessToken?: string;
    expiresIn?: number;
    email?: string | null;
  },
) {
  const admin = createAdminClient();
  const tokenExpiresAt =
    input.expiresIn != null
      ? new Date(Date.now() + input.expiresIn * 1000).toISOString()
      : null;

  const { error } = await admin.from("google_calendar_connections").upsert(
    {
      user_id: userId,
      refresh_token: input.refreshToken,
      access_token: input.accessToken ?? null,
      token_expires_at: tokenExpiresAt,
      google_account_email: input.email ?? null,
      import_enabled: true,
    },
    { onConflict: "user_id" },
  );
  if (error) throw new Error(error.message);
}

export async function deleteConnection(userId: string) {
  const admin = createAdminClient();
  const { error } = await admin.from("google_calendar_connections").delete().eq("user_id", userId);
  if (error) throw new Error(error.message);
}

export async function setImportEnabled(userId: string, importEnabled: boolean) {
  const admin = createAdminClient();
  const { error } = await admin
    .from("google_calendar_connections")
    .update({ import_enabled: importEnabled })
    .eq("user_id", userId);
  if (error) throw new Error(error.message);
}

export async function exchangeCodeForTokens(code: string, redirectUri: string) {
  const res = await fetch(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      code,
      client_id: process.env.GOOGLE_CLIENT_ID!,
      client_secret: process.env.GOOGLE_CLIENT_SECRET!,
      redirect_uri: redirectUri,
      grant_type: "authorization_code",
    }),
  });
  const data = (await res.json()) as {
    access_token?: string;
    refresh_token?: string;
    expires_in?: number;
    error?: string;
    error_description?: string;
  };
  if (!res.ok || !data.access_token) {
    throw new Error(data.error_description ?? data.error ?? "Falha ao conectar Google Calendar");
  }
  return data;
}

async function refreshAccessToken(connection: GoogleCalendarConnectionRow): Promise<string> {
  const res = await fetch(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: process.env.GOOGLE_CLIENT_ID!,
      client_secret: process.env.GOOGLE_CLIENT_SECRET!,
      refresh_token: connection.refresh_token,
      grant_type: "refresh_token",
    }),
  });
  const data = (await res.json()) as {
    access_token?: string;
    expires_in?: number;
    error?: string;
    error_description?: string;
  };
  if (!res.ok || !data.access_token) {
    throw new Error(data.error_description ?? data.error ?? "Token Google expirado — reconecte o calendário");
  }

  const admin = createAdminClient();
  await admin
    .from("google_calendar_connections")
    .update({
      access_token: data.access_token,
      token_expires_at: new Date(Date.now() + (data.expires_in ?? 3600) * 1000).toISOString(),
    })
    .eq("user_id", connection.user_id);

  return data.access_token;
}

async function getValidAccessToken(connection: GoogleCalendarConnectionRow): Promise<string> {
  if (
    connection.access_token &&
    connection.token_expires_at &&
    new Date(connection.token_expires_at).getTime() > Date.now() + 60_000
  ) {
    return connection.access_token;
  }
  return refreshAccessToken(connection);
}

type GoogleCalendarListItem = {
  id: string;
  summary: string;
  backgroundColor?: string;
  selected?: boolean;
  hidden?: boolean;
};

type GoogleEventItem = {
  id: string;
  status?: string;
  summary?: string;
  htmlLink?: string;
  start?: { dateTime?: string; date?: string };
  end?: { dateTime?: string; date?: string };
};

function mapGoogleEvent(
  event: GoogleEventItem,
  calendar: GoogleCalendarListItem,
): CalendarEvent | null {
  if (event.status === "cancelled" || !event.summary) return null;
  const startRaw = event.start?.dateTime ?? event.start?.date;
  const endRaw = event.end?.dateTime ?? event.end?.date;
  if (!startRaw) return null;

  const isAllDay = Boolean(event.start?.date && !event.start?.dateTime);
  const startDate = isAllDay ? `${startRaw}T12:00:00.000Z` : startRaw;
  const endDate = endRaw
    ? isAllDay
      ? `${endRaw}T12:00:00.000Z`
      : endRaw
    : startDate;

  return {
    id: `${calendar.id}:${event.id}`,
    title: event.summary,
    startDate,
    endDate,
    isAllDay,
    calendarTitle: calendar.summary,
    calendarColor: calendar.backgroundColor,
    htmlLink: event.htmlLink,
  };
}

export async function fetchGoogleCalendarEvents(
  userId: string,
  timeMin: Date,
  timeMax: Date,
): Promise<CalendarEvent[]> {
  const connection = await getConnection(userId);
  if (!connection?.import_enabled) return [];

  const accessToken = await getValidAccessToken(connection);

  const listRes = await fetch(`${CALENDAR_API}/users/me/calendarList`, {
    headers: { Authorization: `Bearer ${accessToken}` },
    next: { revalidate: 0 },
  });
  const listData = (await listRes.json()) as { items?: GoogleCalendarListItem[]; error?: { message?: string } };
  if (!listRes.ok) {
    throw new Error(listData.error?.message ?? "Não foi possível listar calendários Google");
  }

  const calendars = (listData.items ?? []).filter((c) => c.selected !== false && !c.hidden);
  const params = new URLSearchParams({
    timeMin: timeMin.toISOString(),
    timeMax: timeMax.toISOString(),
    singleEvents: "true",
    orderBy: "startTime",
    maxResults: "250",
  });

  const allEvents: CalendarEvent[] = [];

  for (const calendar of calendars) {
    const url = `${CALENDAR_API}/calendars/${encodeURIComponent(calendar.id)}/events?${params}`;
    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${accessToken}` },
      next: { revalidate: 0 },
    });
    const data = (await res.json()) as { items?: GoogleEventItem[]; error?: { message?: string } };
    if (!res.ok) continue;
    for (const item of data.items ?? []) {
      const mapped = mapGoogleEvent(item, calendar);
      if (mapped) allEvents.push(mapped);
    }
  }

  return allEvents.sort(
    (a, b) => new Date(a.startDate).getTime() - new Date(b.startDate).getTime(),
  );
}

export function buildGoogleAuthUrl(origin: string, state: string): string {
  const params = new URLSearchParams({
    client_id: process.env.GOOGLE_CLIENT_ID!,
    redirect_uri: `${origin}/api/google/calendar/callback`,
    response_type: "code",
    scope: `${GOOGLE_CALENDAR_SCOPE} email profile openid`,
    access_type: "offline",
    prompt: "consent",
    state,
    include_granted_scopes: "true",
  });
  return `https://accounts.google.com/o/oauth2/v2/auth?${params.toString()}`;
}

export async function fetchGoogleEmail(accessToken: string): Promise<string | null> {
  const res = await fetch("https://www.googleapis.com/oauth2/v2/userinfo", {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!res.ok) return null;
  const data = (await res.json()) as { email?: string };
  return data.email ?? null;
}
