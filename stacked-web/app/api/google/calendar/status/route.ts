import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { deleteConnection, getCalendarStatus } from "@/lib/google/calendar-server";
import { isGoogleCalendarConfigured } from "@/lib/google/config";

export async function GET() {
  if (!isGoogleCalendarConfigured()) {
    return NextResponse.json({ configured: false, connected: false, email: null, importEnabled: false });
  }

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: "Não autenticado" }, { status: 401 });
  }

  const status = await getCalendarStatus(user.id);
  return NextResponse.json(status);
}

export async function DELETE() {
  if (!isGoogleCalendarConfigured()) {
    return NextResponse.json({ error: "Não configurado" }, { status: 503 });
  }

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: "Não autenticado" }, { status: 401 });
  }

  await deleteConnection(user.id);
  return NextResponse.json({ ok: true });
}
