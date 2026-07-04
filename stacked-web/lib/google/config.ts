export const GOOGLE_CALENDAR_SCOPE = "https://www.googleapis.com/auth/calendar.readonly";

export function isGoogleCalendarConfigured(): boolean {
  return Boolean(
    process.env.GOOGLE_CLIENT_ID &&
      process.env.GOOGLE_CLIENT_SECRET &&
      process.env.NEXT_PUBLIC_SUPABASE_URL &&
      process.env.SUPABASE_SERVICE_ROLE_KEY,
  );
}

export function getSiteOrigin(request?: Request): string {
  if (process.env.NEXT_PUBLIC_SITE_URL) {
    return process.env.NEXT_PUBLIC_SITE_URL.replace(/\/$/, "");
  }
  if (request) {
    return new URL(request.url).origin;
  }
  return "http://localhost:3000";
}

export function googleRedirectUri(origin: string): string {
  return `${origin}/api/google/calendar/callback`;
}
