import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import {
  exchangeCodeForTokens,
  fetchGoogleEmail,
  upsertConnection,
} from "@/lib/google/calendar-server";
import { getSiteOrigin, googleRedirectUri, isGoogleCalendarConfigured } from "@/lib/google/config";

export async function GET(request: Request) {
  const origin = getSiteOrigin(request);
  const redirectBase = `${origin}/today`;

  if (!isGoogleCalendarConfigured()) {
    return NextResponse.redirect(`${redirectBase}?calendar=error&reason=config`);
  }

  const url = new URL(request.url);
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state");
  const oauthError = url.searchParams.get("error");

  if (oauthError) {
    return NextResponse.redirect(`${redirectBase}?calendar=error&reason=${oauthError}`);
  }

  const cookieStore = await cookies();
  const savedState = cookieStore.get("google_oauth_state")?.value;
  cookieStore.delete("google_oauth_state");

  if (!code || !state || !savedState || state !== savedState) {
    return NextResponse.redirect(`${redirectBase}?calendar=error&reason=state`);
  }

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.redirect(new URL("/login?next=/today", request.url));
  }

  try {
    const tokens = await exchangeCodeForTokens(code, googleRedirectUri(origin));
    if (!tokens.refresh_token) {
      return NextResponse.redirect(`${redirectBase}?calendar=error&reason=no_refresh`);
    }
    const email = await fetchGoogleEmail(tokens.access_token!);
    await upsertConnection(user.id, {
      refreshToken: tokens.refresh_token,
      accessToken: tokens.access_token,
      expiresIn: tokens.expires_in,
      email,
    });
    return NextResponse.redirect(`${redirectBase}?calendar=connected`);
  } catch {
    return NextResponse.redirect(`${redirectBase}?calendar=error&reason=exchange`);
  }
}
