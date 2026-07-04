import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import { buildGoogleAuthUrl } from "@/lib/google/calendar-server";
import { getSiteOrigin, isGoogleCalendarConfigured } from "@/lib/google/config";

export async function GET(request: Request) {
  if (!isGoogleCalendarConfigured()) {
    return NextResponse.json({ error: "Google Calendar não configurado no servidor" }, { status: 503 });
  }

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.redirect(new URL("/login?next=/today", request.url));
  }

  const state = crypto.randomUUID();
  const cookieStore = await cookies();
  cookieStore.set("google_oauth_state", state, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    maxAge: 600,
    path: "/",
  });

  const origin = getSiteOrigin(request);
  const url = buildGoogleAuthUrl(origin, state);
  return NextResponse.redirect(url);
}
